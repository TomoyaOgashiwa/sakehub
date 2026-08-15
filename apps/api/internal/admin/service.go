package admin

import (
	"context"
	"errors"
	"fmt"
)

type Service struct {
	repo Repository
}

func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) IsAdmin(ctx context.Context, userID string) (bool, error) {
	if userID == "" {
		return false, ErrUnauthorized
	}

	role, err := s.repo.AppRole(ctx, userID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return false, nil
		}
		return false, fmt.Errorf("admin.IsAdmin: %w", err)
	}
	return role == AppRoleAdmin, nil
}

func (s *Service) Overview(ctx context.Context) (*Overview, error) {
	o, err := s.repo.Overview(ctx)
	if err != nil {
		return nil, fmt.Errorf("admin.Overview: %w", err)
	}
	return o, nil
}
