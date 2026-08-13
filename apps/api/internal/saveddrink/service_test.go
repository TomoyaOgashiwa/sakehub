package saveddrink

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type stubRepo struct {
	exists         bool
	existsErr      error
	upsertRow      *SavedDrink
	upsertErr      error
	provisionalRow *SavedDrink
	provisionalErr error
	updateRow      *SavedDrink
	updateErr      error
	findRow        *SavedDrink
	findErr        error
	listRows       []SavedDrink
	listErr        error
	deleteErr      error
	deletedFor     string
	lastStatus     string
	lastNote       *string
	lastProvName   string
	lastProvNorm   string
}

func (s *stubRepo) DrinkExists(context.Context, string) (bool, error) {
	return s.exists, s.existsErr
}

func (s *stubRepo) Upsert(_ context.Context, _, _, status string) (*SavedDrink, error) {
	s.lastStatus = status
	return s.upsertRow, s.upsertErr
}

func (s *stubRepo) UpsertProvisional(_ context.Context, _, name, nameNormalized, status string) (*SavedDrink, error) {
	s.lastStatus = status
	s.lastProvName = name
	s.lastProvNorm = nameNormalized
	return s.provisionalRow, s.provisionalErr
}

func (s *stubRepo) Update(_ context.Context, _, _ string, status, note *string) (*SavedDrink, error) {
	if status != nil {
		s.lastStatus = *status
	}
	s.lastNote = note
	return s.updateRow, s.updateErr
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
	_, err := svc.Save(context.Background(), "user", SaveInput{DrinkID: "not-a-uuid", Status: StatusDrank})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestSaveRejectsMissingStatus(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{exists: true})
	_, err := svc.Save(context.Background(), "user", SaveInput{DrinkID: testDrinkID})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestSaveRejectsInvalidStatus(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{exists: true})
	_, err := svc.Save(context.Background(), "user", SaveInput{DrinkID: testDrinkID, Status: "have"})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestSaveRejectsMissingDrink(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{exists: false})
	_, err := svc.Save(context.Background(), "user", SaveInput{DrinkID: testDrinkID, Status: StatusWant})
	if !errors.Is(err, ErrDrinkNotFound) {
		t.Fatalf("expected ErrDrinkNotFound, got %v", err)
	}
}

func TestSaveUpsertsWhenDrinkExists(t *testing.T) {
	t.Parallel()
	want := &SavedDrink{ID: "s1", DrinkID: testDrinkID, Status: StatusDrank}
	repo := &stubRepo{exists: true, upsertRow: want}
	svc := NewService(repo)
	got, err := svc.Save(context.Background(), "user", SaveInput{DrinkID: testDrinkID, Status: StatusDrank})
	if err != nil {
		t.Fatalf("Save: %v", err)
	}
	if got != want {
		t.Fatalf("got %+v, want %+v", got, want)
	}
	if repo.lastStatus != StatusDrank {
		t.Fatalf("upserted status %q, want %q", repo.lastStatus, StatusDrank)
	}
}

func TestPatchRejectsEmptyBody(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})
	_, err := svc.Patch(context.Background(), testDrinkID, "user", PatchInput{})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestPatchRejectsLongNote(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})
	note := strings.Repeat("あ", MaxNoteLen+1)
	_, err := svc.Patch(context.Background(), testDrinkID, "user", PatchInput{Note: &note})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestPatchUpdatesStatus(t *testing.T) {
	t.Parallel()
	status := StatusWant
	want := &SavedDrink{ID: "s1", DrinkID: testDrinkID, Status: StatusWant}
	repo := &stubRepo{updateRow: want}
	svc := NewService(repo)
	got, err := svc.Patch(context.Background(), testDrinkID, "user", PatchInput{Status: &status})
	if err != nil {
		t.Fatalf("Patch: %v", err)
	}
	if got != want {
		t.Fatalf("got %+v, want %+v", got, want)
	}
	if repo.lastStatus != StatusWant {
		t.Fatalf("patched status %q, want %q", repo.lastStatus, StatusWant)
	}
}

func TestSaveProvisionalRequiresNameAndStatus(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})
	_, err := svc.SaveProvisional(context.Background(), "user", SaveProvisionalInput{Status: StatusDrank})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestSaveProvisionalRejectsInvalidStatus(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})
	_, err := svc.SaveProvisional(context.Background(), "user", SaveProvisionalInput{Name: "禅人未登録ラベル", Status: "have"})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestSaveProvisionalUpsertsNormalizedName(t *testing.T) {
	t.Parallel()
	want := &SavedDrink{ID: "s1", Status: StatusWant}
	repo := &stubRepo{provisionalRow: want}
	svc := NewService(repo)
	got, err := svc.SaveProvisional(context.Background(), "user", SaveProvisionalInput{
		Name:   "  禅人未登録ラベル  ",
		Status: StatusWant,
	})
	if err != nil {
		t.Fatalf("SaveProvisional: %v", err)
	}
	if got != want {
		t.Fatalf("got %+v, want %+v", got, want)
	}
	if repo.lastProvName != "禅人未登録ラベル" {
		t.Fatalf("name %q", repo.lastProvName)
	}
	if repo.lastProvNorm != "禅人未登録らべる" {
		t.Fatalf("normalized %q, want 禅人未登録らべる", repo.lastProvNorm)
	}
	if repo.lastStatus != StatusWant {
		t.Fatalf("status %q", repo.lastStatus)
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
