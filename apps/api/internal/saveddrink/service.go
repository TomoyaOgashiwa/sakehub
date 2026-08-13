package saveddrink

import (
	"context"
	"fmt"
	"regexp"
	"strings"
	"unicode/utf8"

	"github.com/sakehub/api/pkg/normalize"
)

var uuidRe = regexp.MustCompile(`(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)

const (
	defaultListLimit = 50
	maxListLimit     = 100
)

type Service struct {
	repo Repository
}

func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

func validStatus(status string) bool {
	return status == StatusDrank || status == StatusWant
}

func (s *Service) Save(ctx context.Context, userID string, input SaveInput) (*SavedDrink, error) {
	if !uuidRe.MatchString(input.DrinkID) {
		return nil, fmt.Errorf("%w: drink_id is required", ErrValidation)
	}
	if !validStatus(input.Status) {
		return nil, fmt.Errorf("%w: status must be drank or want", ErrValidation)
	}

	exists, err := s.repo.DrinkExists(ctx, input.DrinkID)
	if err != nil {
		return nil, fmt.Errorf("saveddrink.Save: %w", err)
	}
	if !exists {
		return nil, ErrDrinkNotFound
	}

	row, err := s.repo.Upsert(ctx, userID, input.DrinkID, input.Status)
	if err != nil {
		return nil, fmt.Errorf("saveddrink.Save: %w", err)
	}
	return row, nil
}

func (s *Service) SaveProvisional(ctx context.Context, userID string, input SaveProvisionalInput) (*SavedDrink, error) {
	name := strings.TrimSpace(input.Name)
	if name == "" {
		return nil, fmt.Errorf("%w: name is required", ErrValidation)
	}
	if utf8.RuneCountInString(name) > MaxProvisionalRaw {
		return nil, fmt.Errorf("%w: name is too long", ErrValidation)
	}
	if !validStatus(input.Status) {
		return nil, fmt.Errorf("%w: status must be drank or want", ErrValidation)
	}

	normalized := normalize.Query(name)
	n := utf8.RuneCountInString(normalized)
	if n < MinNormalizedLen || n > MaxNormalizedLen {
		return nil, fmt.Errorf("%w: name is invalid", ErrValidation)
	}

	exists, err := s.repo.ProvisionalNameExists(ctx, userID, normalized)
	if err != nil {
		return nil, fmt.Errorf("saveddrink.SaveProvisional: %w", err)
	}
	if !exists {
		count, err := s.repo.CountProvisionalByUser(ctx, userID)
		if err != nil {
			return nil, fmt.Errorf("saveddrink.SaveProvisional: %w", err)
		}
		if count >= MaxProvisionalPerUser {
			return nil, fmt.Errorf("%w: provisional limit reached", ErrValidation)
		}
	}

	row, err := s.repo.UpsertProvisional(ctx, userID, name, normalized, input.Status)
	if err != nil {
		return nil, fmt.Errorf("saveddrink.SaveProvisional: %w", err)
	}
	return row, nil
}

func (s *Service) Patch(ctx context.Context, drinkID, userID string, input PatchInput) (*SavedDrink, error) {
	if !uuidRe.MatchString(drinkID) {
		return nil, fmt.Errorf("%w: drink_id is required", ErrValidation)
	}
	if input.Status == nil && input.Note == nil {
		return nil, fmt.Errorf("%w: status or note is required", ErrValidation)
	}
	if input.Status != nil && !validStatus(*input.Status) {
		return nil, fmt.Errorf("%w: status must be drank or want", ErrValidation)
	}
	if input.Note != nil && utf8.RuneCountInString(*input.Note) > MaxNoteLen {
		return nil, fmt.Errorf("%w: note must be %d characters or fewer", ErrValidation, MaxNoteLen)
	}

	row, err := s.repo.Update(ctx, drinkID, userID, input.Status, input.Note)
	if err != nil {
		return nil, fmt.Errorf("saveddrink.Patch: %w", err)
	}
	return row, nil
}

func (s *Service) GetMine(ctx context.Context, drinkID, userID string) (*SavedDrink, error) {
	if !uuidRe.MatchString(drinkID) {
		return nil, fmt.Errorf("%w: drink_id is required", ErrValidation)
	}

	row, err := s.repo.FindByDrinkAndUser(ctx, drinkID, userID)
	if err != nil {
		return nil, fmt.Errorf("saveddrink.GetMine: %w", err)
	}
	return row, nil
}

func (s *Service) List(ctx context.Context, userID string, params ListParams) ([]SavedDrink, error) {
	if params.Limit <= 0 {
		params.Limit = defaultListLimit
	}
	if params.Limit > maxListLimit {
		params.Limit = maxListLimit
	}
	if params.Offset < 0 {
		params.Offset = 0
	}

	items, err := s.repo.ListByUser(ctx, userID, params)
	if err != nil {
		return nil, fmt.Errorf("saveddrink.List: %w", err)
	}
	return items, nil
}

func (s *Service) Unsave(ctx context.Context, drinkID, userID string) error {
	if !uuidRe.MatchString(drinkID) {
		return fmt.Errorf("%w: drink_id is required", ErrValidation)
	}
	if err := s.repo.DeleteByDrinkAndUser(ctx, drinkID, userID); err != nil {
		return fmt.Errorf("saveddrink.Unsave: %w", err)
	}
	return nil
}
