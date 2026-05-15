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

func (s *Service) Create(ctx context.Context, input CreateInput) (*Drink, error) {
	d := &Drink{
		Name:     input.Name,
		Category: input.Category,
		ABV:      input.ABV,
	}
	if err := s.repo.Insert(ctx, d); err != nil {
		return nil, fmt.Errorf("drink.Create: %w", err)
	}
	return d, nil
}
