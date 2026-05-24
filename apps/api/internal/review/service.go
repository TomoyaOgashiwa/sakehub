package review

import (
	"context"
	"errors"
	"fmt"
)

var ErrInvalidRating = errors.New("rating must be between 1 and 5")

type Service struct {
	repo Repository
}

func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) ListByDrink(ctx context.Context, drinkID string) ([]Review, error) {
	reviews, err := s.repo.ListByDrink(ctx, drinkID)
	if err != nil {
		return nil, fmt.Errorf("review.ListByDrink: %w", err)
	}
	return reviews, nil
}

func (s *Service) GetByDrinkAndUser(ctx context.Context, drinkID, userID string) (*Review, error) {
	rev, err := s.repo.FindByDrinkAndUser(ctx, drinkID, userID)
	if err != nil {
		return nil, fmt.Errorf("review.GetByDrinkAndUser: %w", err)
	}
	return rev, nil
}

func (s *Service) Upsert(ctx context.Context, input UpsertInput, userID string) (*Review, error) {
	if input.Rating < 1 || input.Rating > 5 {
		return nil, ErrInvalidRating
	}

	rev := &Review{
		DrinkID: input.DrinkID,
		UserID:  userID,
		Rating:  input.Rating,
		Comment: input.Comment,
	}

	if err := s.repo.Upsert(ctx, rev); err != nil {
		return nil, fmt.Errorf("review.Upsert: %w", err)
	}
	return rev, nil
}

func (s *Service) Delete(ctx context.Context, id, userID string) error {
	if err := s.repo.Delete(ctx, id, userID); err != nil {
		return fmt.Errorf("review.Delete: %w", err)
	}
	return nil
}
