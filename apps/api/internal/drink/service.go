package drink

import (
	"context"
	"fmt"
)

type Service struct {
	repo Repository
}

func NewService(repo Repository) *Service {
	return &Service{repo: repo}
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

func (s *Service) List(ctx context.Context, params ListParams) ([]Drink, int, error) {
	drinks, total, err := s.repo.List(ctx, params)
	if err != nil {
		return nil, 0, fmt.Errorf("drink.List: %w", err)
	}
	return drinks, total, nil
}

func (s *Service) Create(ctx context.Context, input CreateInput) (*Drink, error) {
	d := &Drink{
		Slug:          input.Slug,
		Name:          input.Name,
		NameEn:        input.NameEn,
		Category:      input.Category,
		Subcategory:   input.Subcategory,
		Description:   input.Description,
		ImageURL:      input.ImageURL,
		ImageSource:   input.ImageSource,
		ABV:           input.ABV,
		OriginCountry: input.OriginCountry,
		Manufacturer:  input.Manufacturer,
	}
	if d.ImageSource == "" {
		d.ImageSource = "none"
	}
	if err := s.repo.Insert(ctx, d); err != nil {
		return nil, fmt.Errorf("drink.Create: %w", err)
	}
	return d, nil
}
