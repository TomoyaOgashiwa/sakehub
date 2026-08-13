package drinklog

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/sakehub/api/internal/searchmiss"
)

const (
	maxItemsPerBatch = 20
	maxCustomNameLen = 200
	maxPlaceNameLen  = 200
	maxPlaceURLLen   = 2000
	maxQuantity      = 20
	maxDrankAtFuture = 36 * time.Hour
	maxDayRange      = 50 * time.Hour
)

type Service struct {
	repo Repository
}

func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) CreateBatch(ctx context.Context, input CreateBatchInput, userID string) ([]Log, error) {
	if len(input.Items) == 0 {
		return nil, fmt.Errorf("%w: items is required", ErrValidation)
	}
	if len(input.Items) > maxItemsPerBatch {
		return nil, fmt.Errorf("%w: too many items (max %d)", ErrValidation, maxItemsPerBatch)
	}

	placeName, err := optionalTrimmed(input.PlaceName, maxPlaceNameLen, "place_name")
	if err != nil {
		return nil, err
	}
	placeURL, err := optionalTrimmed(input.PlaceURL, maxPlaceURLLen, "place_url")
	if err != nil {
		return nil, err
	}

	drankAt := time.Now().UTC()
	if input.DrankAt != nil {
		drankAt = input.DrankAt.UTC()
	}
	if err := validateDrankAt(drankAt, time.Now()); err != nil {
		return nil, err
	}

	logs := make([]Log, 0, len(input.Items))
	for i, item := range input.Items {
		normalized, err := s.prepareItem(ctx, item)
		if err != nil {
			return nil, wrapItemError("CreateBatch", i, err)
		}

		log := Log{
			UserID:          userID,
			DrinkID:         normalized.DrinkID,
			CustomDrinkName: normalized.CustomDrinkName,
			DrankAt:         drankAt,
			VolumeML:        normalized.VolumeML,
			Quantity:        normalized.Quantity,
			InputUnit:       normalized.InputUnit,
			InputValue:      normalized.InputValue,
			ServingKey:      normalized.ServingKey,
			VolumePrecision: normalized.VolumePrecision,
			PlaceName:       placeName,
			PlaceURL:        placeURL,
		}

		if err := s.repo.Insert(ctx, &log); err != nil {
			return nil, fmt.Errorf("drinklog.CreateBatch: %w", err)
		}

		if normalized.CustomDrinkName != nil {
			// Best-effort demand signal; do not fail the log write.
			_ = s.repo.InsertSearchMiss(ctx, userID, *normalized.CustomDrinkName)
		}

		logs = append(logs, log)
	}

	return logs, nil
}

type normalizedItem struct {
	DrinkID         *string
	CustomDrinkName *string
	InputUnit       VolumeUnit
	InputValue      float64
	ServingKey      *string
	VolumePrecision VolumePrecision
	VolumeML        float64
	Quantity        int
}

func validateDrankAt(t, now time.Time) error {
	utc := t.UTC()
	n := now.UTC()
	if utc.After(n.Add(maxDrankAtFuture)) {
		return fmt.Errorf("%w: drank_at is in the future", ErrValidation)
	}
	if utc.Before(n.AddDate(-10, 0, 0)) {
		return fmt.Errorf("%w: drank_at is too far in the past", ErrValidation)
	}
	return nil
}

func wrapItemError(op string, i int, err error) error {
	if errors.Is(err, ErrDrinkNotFound) {
		return fmt.Errorf("drinklog.%s: %w", op, err)
	}
	return fmt.Errorf("%w: items[%d]: %v", ErrValidation, i, err)
}

func (s *Service) prepareItem(ctx context.Context, item CreateItemInput) (*normalizedItem, error) {
	normalized, err := normalizeItem(item)
	if err != nil {
		return nil, err
	}
	if normalized.DrinkID != nil {
		meta, err := s.repo.FindDrinkMeta(ctx, *normalized.DrinkID)
		if err != nil {
			return nil, err
		}
		applyServingRules(normalized, meta.Category)
	} else {
		normalized.ServingKey = nil
		normalized.VolumePrecision = PrecisionExact
	}
	return normalized, nil
}

func normalizeItem(input CreateItemInput) (*normalizedItem, error) {
	var drinkID *string
	if input.DrinkID != nil {
		id := strings.TrimSpace(*input.DrinkID)
		if id != "" {
			drinkID = &id
		}
	}

	var customName *string
	if input.CustomDrinkName != nil {
		name := strings.TrimSpace(*input.CustomDrinkName)
		if name != "" {
			if utf8.RuneCountInString(name) > maxCustomNameLen {
				return nil, fmt.Errorf("custom_drink_name too long")
			}
			customName = &name
		}
	}

	if (drinkID == nil && customName == nil) || (drinkID != nil && customName != nil) {
		return nil, fmt.Errorf("provide either drink_id or custom_drink_name")
	}

	unit := VolumeUnit(strings.ToLower(string(input.InputUnit)))
	if unit != UnitML && unit != UnitOZ {
		return nil, fmt.Errorf("input_unit must be ml or oz")
	}

	if input.InputValue <= 0 {
		return nil, fmt.Errorf("input_value must be positive")
	}
	if unit == UnitML && input.InputValue > 2000 {
		return nil, fmt.Errorf("input_value ml must be <= 2000")
	}
	if unit == UnitOZ && input.InputValue > 70 {
		return nil, fmt.Errorf("input_value oz must be <= 70")
	}

	volumeML := toVolumeML(unit, input.InputValue)
	if volumeML <= 0 || volumeML > 2000 {
		return nil, fmt.Errorf("volume_ml out of range")
	}

	precision := input.VolumePrecision
	if precision != PrecisionExact && precision != PrecisionEstimated {
		return nil, fmt.Errorf("volume_precision must be exact or estimated")
	}

	var servingKey *string
	if input.ServingKey != nil {
		key := strings.TrimSpace(*input.ServingKey)
		if key != "" {
			servingKey = &key
		}
	}

	if servingKey == nil || customName != nil {
		precision = PrecisionExact
		servingKey = nil
	}

	quantity := input.Quantity
	if quantity == 0 {
		quantity = 1
	}
	if quantity < 1 || quantity > maxQuantity {
		return nil, fmt.Errorf("quantity must be between 1 and %d", maxQuantity)
	}

	return &normalizedItem{
		DrinkID:         drinkID,
		CustomDrinkName: customName,
		InputUnit:       unit,
		InputValue:      round2(input.InputValue),
		ServingKey:      servingKey,
		VolumePrecision: precision,
		VolumeML:        volumeML,
		Quantity:        quantity,
	}, nil
}

func applyServingRules(item *normalizedItem, category string) {
	if item.ServingKey == nil {
		item.VolumePrecision = PrecisionExact
		return
	}
	preset := findServingPreset(*item.ServingKey)
	if preset == nil || !presetAllowsCategory(preset, category) {
		item.ServingKey = nil
		item.VolumePrecision = PrecisionExact
		return
	}
	if nearlyEqual(item.VolumeML, preset.VolumeML) &&
		item.InputUnit == UnitML &&
		nearlyEqual(item.InputValue, preset.VolumeML) {
		item.VolumePrecision = preset.DefaultPrecision
		return
	}
	item.ServingKey = nil
	item.VolumePrecision = PrecisionExact
}

func optionalTrimmed(raw *string, maxLen int, field string) (*string, error) {
	if raw == nil {
		return nil, nil
	}
	v := strings.TrimSpace(*raw)
	if v == "" {
		return nil, nil
	}
	if utf8.RuneCountInString(v) > maxLen {
		return nil, fmt.Errorf("%w: %s too long", ErrValidation, field)
	}
	return &v, nil
}

func (s *Service) List(ctx context.Context, userID string, params ListParams) ([]Log, error) {
	if params.Limit <= 0 || params.Limit > 100 {
		params.Limit = 50
	}
	if params.Offset < 0 {
		params.Offset = 0
	}

	logs, err := s.repo.ListByUser(ctx, userID, params)
	if err != nil {
		return nil, fmt.Errorf("drinklog.List: %w", err)
	}
	return logs, nil
}

func (s *Service) GetByID(ctx context.Context, id, userID string) (*Log, error) {
	if strings.TrimSpace(id) == "" {
		return nil, fmt.Errorf("%w: id is required", ErrValidation)
	}
	log, err := s.repo.FindByID(ctx, id, userID)
	if err != nil {
		return nil, fmt.Errorf("drinklog.GetByID: %w", err)
	}
	return log, nil
}

func (s *Service) Update(ctx context.Context, id, userID string, input UpdateInput) (*Log, error) {
	if strings.TrimSpace(id) == "" {
		return nil, fmt.Errorf("%w: id is required", ErrValidation)
	}

	existing, err := s.repo.FindByID(ctx, id, userID)
	if err != nil {
		return nil, fmt.Errorf("drinklog.Update: %w", err)
	}

	normalized, err := s.prepareItem(ctx, CreateItemInput{
		DrinkID:         input.DrinkID,
		CustomDrinkName: input.CustomDrinkName,
		InputUnit:       input.InputUnit,
		InputValue:      input.InputValue,
		ServingKey:      input.ServingKey,
		VolumePrecision: input.VolumePrecision,
		Quantity:        input.Quantity,
	})
	if err != nil {
		if errors.Is(err, ErrDrinkNotFound) {
			return nil, fmt.Errorf("drinklog.Update: %w", err)
		}
		return nil, fmt.Errorf("%w: %v", ErrValidation, err)
	}

	placeName, err := optionalTrimmed(input.PlaceName, maxPlaceNameLen, "place_name")
	if err != nil {
		return nil, err
	}
	placeURL, err := optionalTrimmed(input.PlaceURL, maxPlaceURLLen, "place_url")
	if err != nil {
		return nil, err
	}

	drankAt := existing.DrankAt
	if input.DrankAt != nil {
		drankAt = input.DrankAt.UTC()
		if err := validateDrankAt(drankAt, time.Now()); err != nil {
			return nil, err
		}
	}

	log := Log{
		ID:              existing.ID,
		UserID:          userID,
		DrinkID:         normalized.DrinkID,
		CustomDrinkName: normalized.CustomDrinkName,
		DrankAt:         drankAt,
		VolumeML:        normalized.VolumeML,
		Quantity:        normalized.Quantity,
		InputUnit:       normalized.InputUnit,
		InputValue:      normalized.InputValue,
		ServingKey:      normalized.ServingKey,
		VolumePrecision: normalized.VolumePrecision,
		PlaceName:       placeName,
		PlaceURL:        placeURL,
	}

	if err := s.repo.Update(ctx, &log); err != nil {
		return nil, fmt.Errorf("drinklog.Update: %w", err)
	}

	if normalized.CustomDrinkName != nil {
		_ = s.repo.InsertSearchMiss(ctx, userID, *normalized.CustomDrinkName)
	}

	// Re-fetch so response includes joined drink summary.
	updated, err := s.repo.FindByID(ctx, id, userID)
	if err != nil {
		return nil, fmt.Errorf("drinklog.Update: %w", err)
	}
	return updated, nil
}

func (s *Service) ReplaceDay(ctx context.Context, userID string, input ReplaceDayInput) ([]Log, error) {
	if input.RangeFrom == nil || input.RangeTo == nil {
		return nil, fmt.Errorf("%w: range_from and range_to are required", ErrValidation)
	}
	if input.DrankAt == nil {
		return nil, fmt.Errorf("%w: drank_at is required", ErrValidation)
	}
	from := input.RangeFrom.UTC()
	to := input.RangeTo.UTC()
	if !to.After(from) {
		return nil, fmt.Errorf("%w: range_to must be after range_from", ErrValidation)
	}
	if to.Sub(from) > maxDayRange {
		return nil, fmt.Errorf("%w: day range is too long", ErrValidation)
	}

	drankAt := input.DrankAt.UTC()
	if err := validateDrankAt(drankAt, time.Now()); err != nil {
		return nil, err
	}

	if len(input.Items) == 0 {
		return nil, fmt.Errorf("%w: items is required", ErrValidation)
	}
	if len(input.Items) > maxItemsPerBatch {
		return nil, fmt.Errorf("%w: too many items (max %d)", ErrValidation, maxItemsPerBatch)
	}

	placeName, err := optionalTrimmed(input.PlaceName, maxPlaceNameLen, "place_name")
	if err != nil {
		return nil, err
	}
	placeURL, err := optionalTrimmed(input.PlaceURL, maxPlaceURLLen, "place_url")
	if err != nil {
		return nil, err
	}

	incoming := make([]Log, 0, len(input.Items))
	for i, item := range input.Items {
		normalized, err := s.prepareItem(ctx, item.CreateItemInput)
		if err != nil {
			return nil, wrapItemError("ReplaceDay", i, err)
		}

		log := Log{
			UserID:          userID,
			DrinkID:         normalized.DrinkID,
			CustomDrinkName: normalized.CustomDrinkName,
			DrankAt:         drankAt,
			VolumeML:        normalized.VolumeML,
			Quantity:        normalized.Quantity,
			InputUnit:       normalized.InputUnit,
			InputValue:      normalized.InputValue,
			ServingKey:      normalized.ServingKey,
			VolumePrecision: normalized.VolumePrecision,
			PlaceName:       placeName,
			PlaceURL:        placeURL,
		}
		if item.ID != nil {
			id := strings.TrimSpace(*item.ID)
			if id != "" {
				log.ID = id
			}
		}
		incoming = append(incoming, log)
	}

	logs, err := s.repo.ReplaceInRange(ctx, userID, from, to, incoming)
	if err != nil {
		return nil, fmt.Errorf("drinklog.ReplaceDay: %w", err)
	}

	for _, log := range incoming {
		if log.CustomDrinkName != nil {
			_ = s.repo.InsertSearchMiss(ctx, userID, *log.CustomDrinkName)
		}
	}

	return logs, nil
}

func (s *Service) Delete(ctx context.Context, id, userID string) error {
	if strings.TrimSpace(id) == "" {
		return fmt.Errorf("%w: id is required", ErrValidation)
	}
	if err := s.repo.Delete(ctx, id, userID); err != nil {
		return fmt.Errorf("drinklog.Delete: %w", err)
	}
	return nil
}

func (s *Service) Summary(ctx context.Context, userID string, from, to time.Time) (*Summary, error) {
	if from.IsZero() || to.IsZero() {
		return nil, fmt.Errorf("%w: from and to are required", ErrValidation)
	}
	if !to.After(from) {
		return nil, fmt.Errorf("%w: to must be after from", ErrValidation)
	}

	logCount, skipped, pureGrams, err := s.repo.Summary(ctx, userID, from.UTC(), to.UTC())
	if err != nil {
		return nil, fmt.Errorf("drinklog.Summary: %w", err)
	}

	return &Summary{
		From:              from.UTC(),
		To:                to.UTC(),
		LogCount:          logCount,
		PureAlcoholGrams:  pureGrams,
		SkippedMissingABV: skipped,
	}, nil
}

// normalizeMissQuery adapts searchmiss normalization for demand logging.
func normalizeMissQuery(raw string) string {
	return searchmiss.NormalizeQuery(raw)
}
