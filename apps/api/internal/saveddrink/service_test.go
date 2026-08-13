package saveddrink

import (
	"context"
	"errors"
	"testing"
)

type stubRepo struct {
	exists     bool
	existsErr  error
	upsertRow  *SavedDrink
	upsertErr  error
	findRow    *SavedDrink
	findErr    error
	listRows   []SavedDrink
	listErr    error
	deleteErr  error
	deletedFor string
}

func (s *stubRepo) DrinkExists(context.Context, string) (bool, error) {
	return s.exists, s.existsErr
}

func (s *stubRepo) Upsert(context.Context, string, string) (*SavedDrink, error) {
	return s.upsertRow, s.upsertErr
}

func (s *stubRepo) FindByDrinkAndUser(context.Context, string, string) (*SavedDrink, error) {
	return s.findRow, s.findErr
}

func (s *stubRepo) ListByUser(context.Context, string, ListParams) ([]SavedDrink, error) {
	return s.listRows, s.listErr
}

func (s *stubRepo) DeleteByDrinkAndUser(_ context.Context, drinkID, _ string) error {
	s.deletedFor = drinkID
	return s.deleteErr
}

const testDrinkID = "11111111-1111-1111-1111-111111111111"

func TestSaveRejectsInvalidDrinkID(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})
	_, err := svc.Save(context.Background(), "user", SaveInput{DrinkID: "not-a-uuid"})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestSaveRejectsMissingDrink(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{exists: false})
	_, err := svc.Save(context.Background(), "user", SaveInput{DrinkID: testDrinkID})
	if !errors.Is(err, ErrDrinkNotFound) {
		t.Fatalf("expected ErrDrinkNotFound, got %v", err)
	}
}

func TestSaveUpsertsWhenDrinkExists(t *testing.T) {
	t.Parallel()
	want := &SavedDrink{ID: "s1", DrinkID: testDrinkID}
	svc := NewService(&stubRepo{exists: true, upsertRow: want})
	got, err := svc.Save(context.Background(), "user", SaveInput{DrinkID: testDrinkID})
	if err != nil {
		t.Fatalf("Save: %v", err)
	}
	if got != want {
		t.Fatalf("got %+v, want %+v", got, want)
	}
}

func TestUnsaveRejectsInvalidDrinkID(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})
	err := svc.Unsave(context.Background(), "bad", "user")
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestUnsaveDeletesByDrinkID(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{}
	svc := NewService(repo)
	if err := svc.Unsave(context.Background(), testDrinkID, "user"); err != nil {
		t.Fatalf("Unsave: %v", err)
	}
	if repo.deletedFor != testDrinkID {
		t.Fatalf("deleted %q, want %q", repo.deletedFor, testDrinkID)
	}
}
