package cocktail

import (
	"context"
	"fmt"
	"strings"
)

var validUnits = map[string]bool{
	"ml": true, "g": true, "piece": true, "tsp": true, "tbsp": true,
	"dash": true, "drop": true, "oz": true, "cl": true,
}

var validStatuses = map[string]bool{
	"draft": true, "published": true,
}

type Service struct {
	repo Repository
}

func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) Create(ctx context.Context, input CreateInput) (*Recipe, error) {
	if err := validate(input); err != nil {
		return nil, fmt.Errorf("cocktail.Create: %w", err)
	}

	recipe, err := s.repo.Insert(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("cocktail.Create: %w", err)
	}
	return recipe, nil
}

func validate(input CreateInput) error {
	name := strings.TrimSpace(input.Name)
	if name == "" {
		return fmt.Errorf("%w: name is required", ErrValidation)
	}
	if len([]rune(name)) > 100 {
		return fmt.Errorf("%w: name must be 100 characters or fewer", ErrValidation)
	}

	if input.Memo != nil && len([]rune(*input.Memo)) > 1000 {
		return fmt.Errorf("%w: memo must be 1000 characters or fewer", ErrValidation)
	}

	if !validStatuses[input.Status] {
		return fmt.Errorf("%w: status must be 'draft' or 'published'", ErrValidation)
	}

	if len(input.Ingredients) == 0 {
		return fmt.Errorf("%w: at least one ingredient is required", ErrValidation)
	}

	for i, ing := range input.Ingredients {
		ingName := strings.TrimSpace(ing.Name)
		if ingName == "" {
			return fmt.Errorf("%w: ingredient[%d] name is required", ErrValidation, i)
		}
		if len([]rune(ingName)) > 100 {
			return fmt.Errorf("%w: ingredient[%d] name must be 100 characters or fewer", ErrValidation, i)
		}
		if ing.Unit != nil && !validUnits[*ing.Unit] {
			return fmt.Errorf("%w: ingredient[%d] has invalid unit", ErrValidation, i)
		}
		if ing.Amount != nil && *ing.Amount <= 0 {
			return fmt.Errorf("%w: ingredient[%d] amount must be positive", ErrValidation, i)
		}
	}

	return nil
}
