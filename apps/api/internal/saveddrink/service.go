package saveddrink

import (
	"context"
	"fmt"
	"regexp"
	"sort"
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

func (s *Service) Depth(ctx context.Context, userID string) (*ListDepth, error) {
	drank, err := s.repo.ListDrankPublished(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("saveddrink.Depth: %w", err)
	}
	totals, err := s.repo.CountPublishedByCategory(ctx)
	if err != nil {
		return nil, fmt.Errorf("saveddrink.Depth: %w", err)
	}

	totalByCat := make(map[string]int, len(totals))
	for _, t := range totals {
		totalByCat[t.Category] = t.Total
	}

	categories := filledCategories(drank, totalByCat)
	makers := []DepthMaker{}
	if len(categories) == 0 {
		return &ListDepth{
			Specialty:  nil,
			Categories: categories,
			Makers:     makers,
			MakerScope: "all",
		}, nil
	}
	specialty := categories[0]

	scoped := clusterMakers(drank, &specialty.Category)
	nextCategory := &specialty.Category
	makerScope := "specialty"
	if len(scoped) == 0 {
		scoped = clusterMakers(drank, nil)
		nextCategory = nil
		makerScope = "all"
	}

	excludeIDs := make([]string, 0, len(drank))
	for _, d := range drank {
		excludeIDs = append(excludeIDs, d.DrinkID)
	}

	for i, m := range scoped {
		next := []DepthNextDrink{}
		if i == 0 {
			next, err = s.repo.ListUnsavedByManufacturer(
				ctx, excludeIDs, m.Manufacturer, nextCategory, maxDepthNextDrinks,
			)
			if err != nil {
				return nil, fmt.Errorf("saveddrink.Depth: %w", err)
			}
			if next == nil {
				next = []DepthNextDrink{}
			}
		}
		makers = append(makers, DepthMaker{
			Manufacturer: m.Manufacturer,
			Drank:        m.Drank,
			NextDrinks:   next,
		})
	}

	return &ListDepth{
		Specialty:  &specialty,
		Categories: categories,
		Makers:     makers,
		MakerScope: makerScope,
	}, nil
}

func filledCategories(drank []DrankDrink, totals map[string]int) []DepthSpecialty {
	counts := map[string]int{}
	for _, d := range drank {
		counts[d.Category]++
	}
	out := make([]DepthSpecialty, 0, len(counts))
	for cat, n := range counts {
		if n <= 0 {
			continue
		}
		out = append(out, DepthSpecialty{Category: cat, Drank: n, Total: totals[cat]})
	}
	sort.Slice(out, func(i, j int) bool {
		return betterSpecialty(out[i], &out[j])
	})
	return out
}

func betterSpecialty(cand DepthSpecialty, best *DepthSpecialty) bool {
	if best == nil {
		return true
	}
	if cand.Drank != best.Drank {
		return cand.Drank > best.Drank
	}
	candRatio := fillRatio(cand.Drank, cand.Total)
	bestRatio := fillRatio(best.Drank, best.Total)
	if candRatio != bestRatio {
		return candRatio > bestRatio
	}
	return cand.Category < best.Category
}

func fillRatio(n, d int) float64 {
	if d <= 0 {
		return 0
	}
	return float64(n) / float64(d)
}

func clusterMakers(drank []DrankDrink, category *string) []DepthMaker {
	counts := map[string]int{}
	for _, d := range drank {
		if category != nil && d.Category != *category {
			continue
		}
		m := strings.TrimSpace(d.Manufacturer)
		if m == "" {
			continue
		}
		counts[m]++
	}
	out := make([]DepthMaker, 0, len(counts))
	for m, n := range counts {
		if n >= minMakerDrank {
			out = append(out, DepthMaker{Manufacturer: m, Drank: n})
		}
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].Drank != out[j].Drank {
			return out[i].Drank > out[j].Drank
		}
		return out[i].Manufacturer < out[j].Manufacturer
	})
	if len(out) > maxDepthMakers {
		out = out[:maxDepthMakers]
	}
	return out
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
