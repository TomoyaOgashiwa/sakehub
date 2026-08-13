package drink

import (
	"context"
	"errors"
	"testing"
)

type stubRepo struct {
	listDrinks       []Drink
	listTotal        int
	listErr          error
	suggestDrinks    []Drink
	suggestErr       error
	suggestCalled    bool
	lastSuggestQuery string
}

func (s *stubRepo) FindByID(context.Context, string) (*Drink, error) { return nil, ErrNotFound }
func (s *stubRepo) FindBySlug(context.Context, string) (*Drink, error) {
	return nil, ErrNotFound
}
func (s *stubRepo) Insert(context.Context, *Drink) error { return nil }

func (s *stubRepo) List(context.Context, ListParams) ([]Drink, int, error) {
	return s.listDrinks, s.listTotal, s.listErr
}

func (s *stubRepo) SuggestSimilar(_ context.Context, query string, _ int) ([]Drink, error) {
	s.suggestCalled = true
	s.lastSuggestQuery = query
	return s.suggestDrinks, s.suggestErr
}

func TestListSkipsSuggestionsWhenHitsExist(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{
		listDrinks: []Drink{{ID: "1", Name: "Dassai"}},
		listTotal:  1,
	}
	svc := NewService(repo)

	drinks, total, suggestions, err := svc.List(context.Background(), ListParams{Query: "獺祭"})
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if total != 1 || len(drinks) != 1 {
		t.Fatalf("got %d drinks total=%d", len(drinks), total)
	}
	if repo.suggestCalled {
		t.Fatal("SuggestSimilar should not run when list has hits")
	}
	if len(suggestions) != 0 {
		t.Fatalf("suggestions = %d, want 0", len(suggestions))
	}
}

func TestListSkipsSuggestionsWhenCategorySet(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{listDrinks: []Drink{}, listTotal: 0}
	svc := NewService(repo)

	_, _, suggestions, err := svc.List(context.Background(), ListParams{Query: "foo", Category: "sake"})
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if repo.suggestCalled {
		t.Fatal("SuggestSimilar should not run when category is set")
	}
	if len(suggestions) != 0 {
		t.Fatalf("suggestions = %d, want 0", len(suggestions))
	}
}

func TestListReturnsSuggestionsOnBareQueryZeroHit(t *testing.T) {
	t.Parallel()
	want := []Drink{{ID: "2", Name: "Zenhito Cedar Malt"}}
	repo := &stubRepo{
		listDrinks:    []Drink{},
		listTotal:     0,
		suggestDrinks: want,
	}
	svc := NewService(repo)

	drinks, total, suggestions, err := svc.List(context.Background(), ListParams{Query: "Zenhito Cedr Malt"})
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if total != 0 || len(drinks) != 0 {
		t.Fatalf("expected empty list, got %d total=%d", len(drinks), total)
	}
	if !repo.suggestCalled || repo.lastSuggestQuery != "Zenhito Cedr Malt" {
		t.Fatalf("SuggestSimilar query = %q called=%v", repo.lastSuggestQuery, repo.suggestCalled)
	}
	if len(suggestions) != 1 || suggestions[0].Name != want[0].Name {
		t.Fatalf("suggestions = %+v, want %+v", suggestions, want)
	}
}

func TestListPropagatesSuggestError(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{
		listDrinks: []Drink{},
		listTotal:  0,
		suggestErr: errors.New("trgm failed"),
	}
	svc := NewService(repo)

	_, _, _, err := svc.List(context.Background(), ListParams{Query: "missing"})
	if err == nil {
		t.Fatal("expected error")
	}
}
