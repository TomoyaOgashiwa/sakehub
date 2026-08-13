package drink

import (
	"context"
	"fmt"
	"strings"
	"unicode/utf8"

	"go.uber.org/zap"
)

type Service struct {
	repo   Repository
	logger *zap.Logger
}

func NewService(repo Repository, logger *zap.Logger) *Service {
	if logger == nil {
		logger = zap.NewNop()
	}
	return &Service{repo: repo, logger: logger}
}

func (s *Service) GetByID(ctx context.Context, id string) (*Drink, error) {
	d, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("drink.GetByID: %w", err)
	}
	return d, nil
}

func (s *Service) GetBySlug(ctx context.Context, slug string) (*Drink, error) {
	d, err := s.repo.FindBySlug(ctx, slug)
	if err != nil {
		return nil, fmt.Errorf("drink.GetBySlug: %w", err)
	}
	return d, nil
}

func (s *Service) List(ctx context.Context, params ListParams) ([]Drink, int, []Drink, error) {
	drinks, total, err := s.repo.List(ctx, params)
	if err != nil {
		return nil, 0, nil, fmt.Errorf("drink.List: %w", err)
	}

	suggestions := []Drink{}
	q := strings.TrimSpace(params.Query)
	if q != "" &&
		params.Category == "" &&
		total == 0 &&
		utf8.RuneCountInString(q) >= MinSuggestQueryLen {
		suggestions, err = s.repo.SuggestSimilar(ctx, q, MaxSuggestions)
		if err != nil {
			s.logger.Warn("drink suggestions failed", zap.String("q", q), zap.Error(err))
			suggestions = []Drink{}
		}
	}

	return drinks, total, suggestions, nil
}

func (s *Service) Create(ctx context.Context, input CreateInput) (*Drink, error) {
	// Attribution labels (generated / brand) are seed/admin-only. Public Create
	// must not accept client-supplied image_source.
	d := &Drink{
		Slug:          input.Slug,
		Name:          input.Name,
		NameEn:        input.NameEn,
		Category:      input.Category,
		Subcategory:   input.Subcategory,
		Description:   input.Description,
		ImageURL:      input.ImageURL,
		ImageSource:   "none",
		ABV:           input.ABV,
		OriginCountry: input.OriginCountry,
		Manufacturer:  input.Manufacturer,
	}
	if err := s.repo.Insert(ctx, d); err != nil {
		return nil, fmt.Errorf("drink.Create: %w", err)
	}
	return d, nil
}
