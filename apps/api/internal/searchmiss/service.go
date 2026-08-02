package searchmiss

import (
	"context"
	"fmt"
	"strings"
	"unicode/utf8"
)

type Service struct {
	repo Repository
}

func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

// Create logs a zero-hit search. Non-zero result_count, empty/short/long
// normalized queries, or invalid scope return ErrSkip (caller maps to 204).
func (s *Service) Create(ctx context.Context, input CreateInput, userID string) (*Miss, error) {
	scope := strings.TrimSpace(input.Scope)
	if !validScopes[scope] {
		return nil, fmt.Errorf("%w: invalid scope", ErrValidation)
	}

	raw := strings.TrimSpace(input.QueryRaw)
	if raw == "" {
		return nil, ErrSkip
	}
	if utf8.RuneCountInString(raw) > MaxRawLen {
		return nil, fmt.Errorf("%w: query_raw too long", ErrValidation)
	}

	// Prefer zero-hit only: confirmed searches with no matches.
	if input.ResultCount != 0 {
		return nil, ErrSkip
	}

	normalized := NormalizeQuery(raw)
	n := utf8.RuneCountInString(normalized)
	if n < MinNormalizedLen || n > MaxNormalizedLen {
		return nil, ErrSkip
	}

	miss := &Miss{
		Scope:           scope,
		QueryRaw:        raw,
		QueryNormalized: normalized,
		ResultCount:     0,
	}
	if userID != "" {
		miss.UserID = &userID
	}
	if input.ClientHash != nil {
		h := strings.TrimSpace(*input.ClientHash)
		if h != "" && utf8.RuneCountInString(h) <= 128 {
			miss.ClientHash = &h
		}
	}

	if err := s.repo.Insert(ctx, miss); err != nil {
		return nil, fmt.Errorf("searchmiss.Create: %w", err)
	}
	return miss, nil
}
