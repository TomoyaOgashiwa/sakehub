package admin

import (
	"context"
	"errors"
	"fmt"
	"strings"
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

func (s *Service) ListSearchMisses(ctx context.Context, p SearchMissListParams) (*SearchMissListResult, error) {
	scope, err := normalizeSearchMissScope(p.Scope)
	if err != nil {
		return nil, err
	}
	limit, offset := clampSearchMissBounds(p.Limit, p.Offset)

	rows, total, err := s.repo.ListSearchMisses(ctx, SearchMissListParams{
		Scope:  scope,
		Limit:  limit,
		Offset: offset,
	})
	if err != nil {
		return nil, fmt.Errorf("admin.ListSearchMisses: %w", err)
	}
	if rows == nil {
		rows = []SearchMissRow{}
	}
	return &SearchMissListResult{
		Data:   rows,
		Total:  total,
		Limit:  limit,
		Offset: offset,
	}, nil
}

func normalizeSearchMissScope(raw string) (string, error) {
	scope := strings.TrimSpace(raw)
	if scope == "" || scope == searchMissScopeAll {
		return "", nil
	}
	switch scope {
	case searchMissScopeDrink, searchMissScopeCocktail, searchMissScopeIng:
		return scope, nil
	default:
		return "", fmt.Errorf("%w: invalid scope", ErrValidation)
	}
}

func clampSearchMissBounds(limit, offset int) (int, int) {
	if limit <= 0 {
		limit = DefaultSearchMissLimit
	}
	if limit > MaxSearchMissLimit {
		limit = MaxSearchMissLimit
	}
	if offset < 0 {
		offset = 0
	}
	return limit, offset
}
