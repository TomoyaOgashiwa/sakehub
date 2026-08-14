package saveddrink

import (
	"context"
	"errors"
	"fmt"
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
	drank          []DrankDrink
	drankErr       error
	categoryTotals []CategoryTotal
	totalsErr      error
	nextDrinks     []DepthNextDrink
	nextErr        error
	nextForMaker   string
	nextCategory   *string
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

func (s *stubRepo) ListDrankPublished(context.Context, string) ([]DrankDrink, error) {
	return s.drank, s.drankErr
}

func (s *stubRepo) CountPublishedByCategory(context.Context) ([]CategoryTotal, error) {
	return s.categoryTotals, s.totalsErr
}

func (s *stubRepo) ListUnsavedByManufacturer(
	_ context.Context,
	_ []string,
	manufacturer string,
	category *string,
	_ int,
) ([]DepthNextDrink, error) {
	s.nextForMaker = manufacturer
	s.nextCategory = category
	return s.nextDrinks, s.nextErr
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

func TestSaveProvisionalPropagatesLimitError(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{
		provisionalErr: fmt.Errorf("%w: provisional limit reached", ErrValidation),
	})
	_, err := svc.SaveProvisional(context.Background(), "user", SaveProvisionalInput{
		Name:   "禅人未登録ラベル",
		Status: StatusDrank,
	})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
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

func TestDepthEmptyWhenNoDrank(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{
		drank:          []DrankDrink{},
		categoryTotals: []CategoryTotal{{Category: "sake", Total: 200}},
	})
	got, err := svc.Depth(context.Background(), "user")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if got.Specialty != nil {
		t.Fatalf("specialty %+v, want nil", got.Specialty)
	}
	if len(got.Makers) != 0 {
		t.Fatalf("makers %d, want 0", len(got.Makers))
	}
}

func TestDepthPicksSpecialtyByCount(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{
		drank: []DrankDrink{
			{DrinkID: "1", Category: "sake", Manufacturer: "Asahi"},
			{DrinkID: "2", Category: "sake", Manufacturer: "Asahi"},
			{DrinkID: "3", Category: "sake", Manufacturer: "Kubo"},
			{DrinkID: "4", Category: "whisky", Manufacturer: "Nikka"},
			{DrinkID: "5", Category: "whisky", Manufacturer: "Nikka"},
		},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 200},
			{Category: "whisky", Total: 180},
		},
	})
	got, err := svc.Depth(context.Background(), "user")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if got.Specialty == nil || got.Specialty.Category != "sake" || got.Specialty.Drank != 3 || got.Specialty.Total != 200 {
		t.Fatalf("specialty %+v", got.Specialty)
	}
	if got.MakerScope != "specialty" {
		t.Fatalf("makerScope %q", got.MakerScope)
	}
}

func TestDepthTieBreaksByFillRatio(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{
		drank: []DrankDrink{
			{DrinkID: "1", Category: "sake", Manufacturer: "A"},
			{DrinkID: "2", Category: "sake", Manufacturer: "B"},
			{DrinkID: "3", Category: "whisky", Manufacturer: "C"},
			{DrinkID: "4", Category: "whisky", Manufacturer: "D"},
		},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 200},
			{Category: "whisky", Total: 10},
		},
	})
	got, err := svc.Depth(context.Background(), "user")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if got.Specialty == nil || got.Specialty.Category != "whisky" {
		t.Fatalf("specialty %+v, want whisky", got.Specialty)
	}
}

func TestDepthTieBreaksByCategoryName(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{
		drank: []DrankDrink{
			{DrinkID: "1", Category: "sake", Manufacturer: "A"},
			{DrinkID: "2", Category: "beer", Manufacturer: "B"},
		},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 100},
			{Category: "beer", Total: 100},
		},
	})
	got, err := svc.Depth(context.Background(), "user")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if got.Specialty == nil || got.Specialty.Category != "beer" {
		t.Fatalf("specialty %+v, want beer", got.Specialty)
	}
}

func TestDepthMakersInSpecialtyWhenTwoPlus(t *testing.T) {
	t.Parallel()
	next := []DepthNextDrink{{Slug: "dassai-45", Name: "Dassai 45"}}
	repo := &stubRepo{
		drank: []DrankDrink{
			{DrinkID: "1", Category: "sake", Manufacturer: "Asahi Shuzo"},
			{DrinkID: "2", Category: "sake", Manufacturer: "Asahi Shuzo"},
			{DrinkID: "3", Category: "sake", Manufacturer: "Kubo"},
			{DrinkID: "4", Category: "whisky", Manufacturer: "Nikka"},
			{DrinkID: "5", Category: "whisky", Manufacturer: "Nikka"},
		},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 200},
			{Category: "whisky", Total: 180},
		},
		nextDrinks: next,
	}
	svc := NewService(repo)
	got, err := svc.Depth(context.Background(), "user")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if len(got.Makers) != 1 || got.Makers[0].Manufacturer != "Asahi Shuzo" || got.Makers[0].Drank != 2 {
		t.Fatalf("makers %+v", got.Makers)
	}
	if repo.nextForMaker != "Asahi Shuzo" {
		t.Fatalf("next maker %q", repo.nextForMaker)
	}
	if repo.nextCategory == nil || *repo.nextCategory != "sake" {
		t.Fatalf("next category %v", repo.nextCategory)
	}
	if len(got.Makers[0].NextDrinks) != 1 || got.Makers[0].NextDrinks[0].Slug != "dassai-45" {
		t.Fatalf("nextDrinks %+v", got.Makers[0].NextDrinks)
	}
}

func TestDepthMakersFallBackToOverall(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{
		drank: []DrankDrink{
			{DrinkID: "1", Category: "sake", Manufacturer: "Asahi Shuzo"},
			{DrinkID: "2", Category: "sake", Manufacturer: "Kubo"},
			{DrinkID: "3", Category: "sake", Manufacturer: "Dewazakura"},
			{DrinkID: "4", Category: "whisky", Manufacturer: "Nikka"},
			{DrinkID: "5", Category: "whisky", Manufacturer: "Nikka"},
		},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 200},
			{Category: "whisky", Total: 180},
		},
	}
	svc := NewService(repo)
	got, err := svc.Depth(context.Background(), "user")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if got.Specialty == nil || got.Specialty.Category != "sake" {
		t.Fatalf("specialty %+v", got.Specialty)
	}
	if len(got.Makers) != 1 || got.Makers[0].Manufacturer != "Nikka" {
		t.Fatalf("makers %+v, want overall Nikka", got.Makers)
	}
	if repo.nextCategory != nil {
		t.Fatalf("next category %v, want nil for overall fallback", repo.nextCategory)
	}
	if got.MakerScope != "all" {
		t.Fatalf("makerScope %q, want all", got.MakerScope)
	}
}

func TestDepthNextDrinksOnlyOnFirstMaker(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{
		drank: []DrankDrink{
			{DrinkID: "1", Category: "sake", Manufacturer: "Asahi Shuzo"},
			{DrinkID: "2", Category: "sake", Manufacturer: "Asahi Shuzo"},
			{DrinkID: "3", Category: "sake", Manufacturer: "Kubo"},
			{DrinkID: "4", Category: "sake", Manufacturer: "Kubo"},
		},
		categoryTotals: []CategoryTotal{{Category: "sake", Total: 200}},
		nextDrinks:     []DepthNextDrink{{Slug: "a", Name: "A"}},
	})
	got, err := svc.Depth(context.Background(), "user")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if len(got.Makers) != 2 {
		t.Fatalf("makers %d", len(got.Makers))
	}
	if len(got.Makers[0].NextDrinks) != 1 {
		t.Fatalf("first nextDrinks %+v", got.Makers[0].NextDrinks)
	}
	if len(got.Makers[1].NextDrinks) != 0 {
		t.Fatalf("second nextDrinks %+v", got.Makers[1].NextDrinks)
	}
}

func TestDepthSkipsEmptyManufacturer(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{
		drank: []DrankDrink{
			{DrinkID: "1", Category: "sake", Manufacturer: ""},
			{DrinkID: "2", Category: "sake", Manufacturer: ""},
			{DrinkID: "3", Category: "sake", Manufacturer: "  "},
		},
		categoryTotals: []CategoryTotal{{Category: "sake", Total: 200}},
	})
	got, err := svc.Depth(context.Background(), "user")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if len(got.Makers) != 0 {
		t.Fatalf("makers %+v", got.Makers)
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
