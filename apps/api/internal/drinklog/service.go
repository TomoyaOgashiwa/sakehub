package drinklog

import (
	"context"
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

	logs := make([]Log, 0, len(input.Items))
	for i, item := range input.Items {
		normalized, err := normalizeItem(item)
		if err != nil {
			return nil, fmt.Errorf("%w: items[%d]: %v", ErrValidation, i, err)
		}

		if normalized.DrinkID != nil {
			meta, err := s.repo.FindDrinkMeta(ctx, *normalized.DrinkID)
			if err != nil {
				return nil, fmt.Errorf("drinklog.CreateBatch: %w", err)
			}
			applyServingRules(normalized, meta.Category)
		} else {
			// Custom drinks cannot use category presets.
			normalized.ServingKey = nil
			normalized.VolumePrecision = PrecisionExact
		}

		log := Log{
			UserID:          userID,
			DrinkID:         normalized.DrinkID,
			CustomDrinkName: normalized.CustomDrinkName,
			DrankAt:         drankAt,
			VolumeML:        normalized.VolumeML,
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

	return &normalizedItem{
		DrinkID:         drinkID,
		CustomDrinkName: customName,
		InputUnit:       unit,
		InputValue:      round2(input.InputValue),
		ServingKey:      servingKey,
		VolumePrecision: precision,
		VolumeML:        volumeML,
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
