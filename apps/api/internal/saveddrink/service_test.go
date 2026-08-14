package saveddrink

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"
)

type stubRepo struct {
	exists               bool
	existsErr            error
	upsertRow            *SavedDrink
	upsertErr            error
	provisionalRow       *SavedDrink
	provisionalErr       error
	updateRow            *SavedDrink
	updateErr            error
	findRow              *SavedDrink
	findErr              error
	listRows             []SavedDrink
	listErr              error
	lastList             ListParams
	deleteErr            error
	deletedFor           string
	lastStatus           string
	lastNote             *string
	lastProvName         string
	lastProvNorm         string
	drankCounts          []CategoryCount
	drankErr             error
	categoryTotals       []CategoryTotal
	totalsErr            error
	makersByScope        map[string][]DepthMaker
	makersErr            error
	makerKeys            []string
	nextDrinks           []DepthNextDrink
	nextErr              error
	nextForMaker         string
	nextCategory         *string
	nextForUser          string
	provisionalCount     int
	provisionalCountErr  error
	publishedIdentities  []PublishedIdentity
	unmergedProvisionals []ProvisionalCandidate
	mergeOne             MergeOneResult
	mergeErr             error
	mergedPairs          [][2]string
	orphanDeleted        int
	orphanErr            error
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

func (s *stubRepo) ListByUser(_ context.Context, _ string, params ListParams) ([]SavedDrink, error) {
	s.lastList = params
	return s.listRows, s.listErr
}

func (s *stubRepo) DeleteByDrinkAndUser(_ context.Context, drinkID, _ string) error {
	s.deletedFor = drinkID
	return s.deleteErr
}

func (s *stubRepo) CountDrankByCategory(context.Context, string) ([]CategoryCount, error) {
	if s.drankCounts == nil {
		return []CategoryCount{}, s.drankErr
	}
	return s.drankCounts, s.drankErr
}

func (s *stubRepo) CountPublishedByCategory(context.Context) ([]CategoryTotal, error) {
	return s.categoryTotals, s.totalsErr
}

func (s *stubRepo) CountProvisional(context.Context, string) (int, error) {
	return s.provisionalCount, s.provisionalCountErr
}

func (s *stubRepo) ListMakers(_ context.Context, _ string, category *string) ([]DepthMaker, error) {
	key := ""
	if category != nil {
		key = *category
	}
	s.makerKeys = append(s.makerKeys, key)
	if s.makersErr != nil {
		return nil, s.makersErr
	}
	if s.makersByScope == nil {
		return []DepthMaker{}, nil
	}
	out := s.makersByScope[key]
	if out == nil {
		return []DepthMaker{}, nil
	}
	return out, nil
}

func (s *stubRepo) ListPublishedIdentities(context.Context) ([]PublishedIdentity, error) {
	if s.publishedIdentities == nil {
		return []PublishedIdentity{}, nil
	}
	return s.publishedIdentities, nil
}

func (s *stubRepo) ListUnmergedProvisionals(context.Context) ([]ProvisionalCandidate, error) {
	if s.unmergedProvisionals == nil {
		return []ProvisionalCandidate{}, nil
	}
	return s.unmergedProvisionals, nil
}

func (s *stubRepo) MergeProvisionalInto(_ context.Context, provisionalID, publishedID string) (MergeOneResult, error) {
	s.mergedPairs = append(s.mergedPairs, [2]string{provisionalID, publishedID})
	return s.mergeOne, s.mergeErr
}

func (s *stubRepo) DeleteMergedOrphans(context.Context) (int, error) {
	return s.orphanDeleted, s.orphanErr
}

func (s *stubRepo) ListUnsavedByManufacturer(
	_ context.Context,
	userID, manufacturer string,
	category *string,
	_ int,
) ([]DepthNextDrink, error) {
	s.nextForUser = userID
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
		drankCounts:    []CategoryCount{},
		categoryTotals: []CategoryTotal{{Category: "sake", Total: 200}},
	})
	got, err := svc.Depth(context.Background(), "user", "")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if got.Specialty != nil {
		t.Fatalf("specialty %+v, want nil", got.Specialty)
	}
	if len(got.Categories) != 0 {
		t.Fatalf("categories %d, want 0", len(got.Categories))
	}
	if len(got.Makers) != 0 {
		t.Fatalf("makers %d, want 0", len(got.Makers))
	}
	if got.ProvisionalCount != 0 {
		t.Fatalf("provisionalCount %d, want 0", got.ProvisionalCount)
	}
}

func TestDepthIncludesProvisionalCount(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{
		drankCounts:      []CategoryCount{{Category: "sake", Drank: 1}},
		categoryTotals:   []CategoryTotal{{Category: "sake", Total: 200}},
		provisionalCount: 3,
	})
	got, err := svc.Depth(context.Background(), "user", "")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if got.ProvisionalCount != 3 {
		t.Fatalf("provisionalCount %d, want 3", got.ProvisionalCount)
	}
	if got.Specialty == nil || got.Specialty.Category != "sake" {
		t.Fatalf("specialty %+v", got.Specialty)
	}
}

func TestDepthPicksSpecialtyByCount(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{
		drankCounts: []CategoryCount{
			{Category: "sake", Drank: 3},
			{Category: "whisky", Drank: 2},
		},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 200},
			{Category: "whisky", Total: 180},
		},
		makersByScope: map[string][]DepthMaker{
			"sake": {{Manufacturer: "Asahi", Drank: 2}},
		},
	})
	got, err := svc.Depth(context.Background(), "user", "")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if got.Specialty == nil || got.Specialty.Category != "sake" || got.Specialty.Drank != 3 || got.Specialty.Total != 200 {
		t.Fatalf("specialty %+v", got.Specialty)
	}
	if len(got.Categories) != 2 {
		t.Fatalf("categories %d, want 2", len(got.Categories))
	}
	if got.Categories[0].Category != "sake" || got.Categories[1].Category != "whisky" {
		t.Fatalf("categories %+v", got.Categories)
	}
	if got.MakerScope != "specialty" {
		t.Fatalf("makerScope %q", got.MakerScope)
	}
}

func TestDepthTieBreaksByFillRatio(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{
		drankCounts: []CategoryCount{
			{Category: "sake", Drank: 2},
			{Category: "whisky", Drank: 2},
		},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 200},
			{Category: "whisky", Total: 10},
		},
	})
	got, err := svc.Depth(context.Background(), "user", "")
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
		drankCounts: []CategoryCount{
			{Category: "sake", Drank: 1},
			{Category: "beer", Drank: 1},
		},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 100},
			{Category: "beer", Total: 100},
		},
	})
	got, err := svc.Depth(context.Background(), "user", "")
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
		drankCounts: []CategoryCount{
			{Category: "sake", Drank: 3},
			{Category: "whisky", Drank: 2},
		},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 200},
			{Category: "whisky", Total: 180},
		},
		makersByScope: map[string][]DepthMaker{
			"sake": {{Manufacturer: "Asahi Shuzo", Drank: 2}},
		},
		nextDrinks: next,
	}
	svc := NewService(repo)
	got, err := svc.Depth(context.Background(), "user", "")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if len(got.Makers) != 1 || got.Makers[0].Manufacturer != "Asahi Shuzo" || got.Makers[0].Drank != 2 {
		t.Fatalf("makers %+v", got.Makers)
	}
	if repo.nextForMaker != "Asahi Shuzo" {
		t.Fatalf("next maker %q", repo.nextForMaker)
	}
	if repo.nextForUser != "user" {
		t.Fatalf("next user %q", repo.nextForUser)
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
		drankCounts: []CategoryCount{
			{Category: "sake", Drank: 3},
			{Category: "whisky", Drank: 2},
		},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 200},
			{Category: "whisky", Total: 180},
		},
		makersByScope: map[string][]DepthMaker{
			"": {{Manufacturer: "Nikka", Drank: 2}},
		},
	}
	svc := NewService(repo)
	got, err := svc.Depth(context.Background(), "user", "")
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
		drankCounts:    []CategoryCount{{Category: "sake", Drank: 4}},
		categoryTotals: []CategoryTotal{{Category: "sake", Total: 200}},
		makersByScope: map[string][]DepthMaker{
			"sake": {
				{Manufacturer: "Asahi Shuzo", Drank: 2},
				{Manufacturer: "Kubo", Drank: 2},
			},
		},
		nextDrinks: []DepthNextDrink{{Slug: "a", Name: "A"}},
	})
	got, err := svc.Depth(context.Background(), "user", "")
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
		drankCounts:    []CategoryCount{{Category: "sake", Drank: 3}},
		categoryTotals: []CategoryTotal{{Category: "sake", Total: 200}},
	})
	got, err := svc.Depth(context.Background(), "user", "")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if len(got.Makers) != 0 {
		t.Fatalf("makers %+v", got.Makers)
	}
}

func TestDepthOmitsZeroCategories(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{
		drankCounts: []CategoryCount{{Category: "sake", Drank: 1}},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 200},
			{Category: "beer", Total: 150},
			{Category: "whisky", Total: 180},
		},
	})
	got, err := svc.Depth(context.Background(), "user", "")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if len(got.Categories) != 1 || got.Categories[0].Category != "sake" {
		t.Fatalf("categories %+v, want sake only", got.Categories)
	}
}

func TestDepthRequestedCategoryScopesMakersWithoutFallback(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{
		drankCounts: []CategoryCount{
			{Category: "sake", Drank: 3},
			{Category: "whisky", Drank: 2},
		},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 200},
			{Category: "whisky", Total: 180},
		},
		makersByScope: map[string][]DepthMaker{
			"whisky": {{Manufacturer: "Nikka", Drank: 2}},
		},
	}
	svc := NewService(repo)

	sake, err := svc.Depth(context.Background(), "user", "sake")
	if err != nil {
		t.Fatalf("Depth sake: %v", err)
	}
	if len(sake.Categories) != 2 {
		t.Fatalf("categories %d, want all filled", len(sake.Categories))
	}
	if len(sake.Makers) != 0 {
		t.Fatalf("sake makers %+v, want none without overall fallback", sake.Makers)
	}
	if sake.MakerScope != "specialty" {
		t.Fatalf("makerScope %q, want specialty", sake.MakerScope)
	}
	for _, key := range repo.makerKeys {
		if key == "" {
			t.Fatalf("maker keys %+v, sake request must not fall back to overall", repo.makerKeys)
		}
	}

	whisky, err := svc.Depth(context.Background(), "user", "whisky")
	if err != nil {
		t.Fatalf("Depth whisky: %v", err)
	}
	if len(whisky.Makers) != 1 || whisky.Makers[0].Manufacturer != "Nikka" {
		t.Fatalf("whisky makers %+v, want Nikka", whisky.Makers)
	}
	if repo.nextCategory == nil || *repo.nextCategory != "whisky" {
		t.Fatalf("next category %v, want whisky", repo.nextCategory)
	}
}

func TestDepthInvalidCategoryUsesOverviewFallback(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{
		drankCounts: []CategoryCount{
			{Category: "sake", Drank: 3},
			{Category: "whisky", Drank: 2},
		},
		categoryTotals: []CategoryTotal{
			{Category: "sake", Total: 200},
			{Category: "whisky", Total: 180},
		},
		makersByScope: map[string][]DepthMaker{
			"": {{Manufacturer: "Nikka", Drank: 2}},
		},
	}
	svc := NewService(repo)
	got, err := svc.Depth(context.Background(), "user", "all")
	if err != nil {
		t.Fatalf("Depth: %v", err)
	}
	if got.MakerScope != "all" {
		t.Fatalf("makerScope %q, want all", got.MakerScope)
	}
	if len(got.Makers) != 1 || got.Makers[0].Manufacturer != "Nikka" {
		t.Fatalf("makers %+v, want overall Nikka", got.Makers)
	}
}

func TestListRejectsInvalidStatus(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})
	_, err := svc.List(context.Background(), "user", ListParams{Status: "have"})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestListPassesCategoryAndStatus(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{listRows: []SavedDrink{}}
	svc := NewService(repo)
	_, err := svc.List(context.Background(), "user", ListParams{
		Limit:         100,
		Status:        StatusDrank,
		Category:      "sake",
		PublishedOnly: true,
	})
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if repo.lastList.Status != StatusDrank || repo.lastList.Category != "sake" || !repo.lastList.PublishedOnly {
		t.Fatalf("list params %+v", repo.lastList)
	}
	if repo.lastList.Limit != 100 {
		t.Fatalf("limit %d", repo.lastList.Limit)
	}
}

func TestListDropsInvalidCategory(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{listRows: []SavedDrink{}}
	svc := NewService(repo)
	_, err := svc.List(context.Background(), "user", ListParams{
		Category:      "all",
		PublishedOnly: true,
	})
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if repo.lastList.Category != "" || repo.lastList.PublishedOnly {
		t.Fatalf("list params %+v, want category cleared", repo.lastList)
	}
}

func TestListPassesDrankUnion(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{listRows: []SavedDrink{}}
	svc := NewService(repo)
	_, err := svc.List(context.Background(), "user", ListParams{
		Limit:      100,
		Category:   "sake",
		DrankUnion: true,
	})
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if !repo.lastList.DrankUnion || repo.lastList.Category != "sake" {
		t.Fatalf("list params %+v", repo.lastList)
	}
}

func TestListPassesProvisionalVisibility(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{listRows: []SavedDrink{}}
	svc := NewService(repo)
	_, err := svc.List(context.Background(), "user", ListParams{
		Limit:      100,
		Visibility: VisibilityProvisional,
	})
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if repo.lastList.Visibility != VisibilityProvisional {
		t.Fatalf("list params %+v", repo.lastList)
	}
}

func TestListRejectsVisibilityWithCategory(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})
	_, err := svc.List(context.Background(), "user", ListParams{
		Visibility: VisibilityProvisional,
		Category:   "sake",
	})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestListRejectsInvalidVisibility(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})
	_, err := svc.List(context.Background(), "user", ListParams{Visibility: "hidden"})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestMergeExactNamesRemapsUniqueMatch(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{
		publishedIdentities: []PublishedIdentity{{
			ID:   "pub-1",
			Slug: "zh-unlisted-label",
			Name: "禅人未登録ラベル",
		}},
		unmergedProvisionals: []ProvisionalCandidate{{
			ID:             "prov-1",
			NameNormalized: "禅人未登録らべる",
		}},
		mergeOne: MergeOneResult{Remapped: 1, Deleted: true},
	}
	got, err := NewService(repo).MergeExactNames(context.Background())
	if err != nil {
		t.Fatalf("MergeExactNames: %v", err)
	}
	if got.Remapped != 1 || got.Deleted != 1 || got.SkippedAmbiguous != 0 {
		t.Fatalf("report %+v", got)
	}
	if len(repo.mergedPairs) != 1 || repo.mergedPairs[0] != [2]string{"prov-1", "pub-1"} {
		t.Fatalf("merged pairs %+v", repo.mergedPairs)
	}
}

func TestMergeExactNamesSkipsAmbiguous(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{
		publishedIdentities: []PublishedIdentity{
			{ID: "a", Slug: "sku-a", Name: "Sku A", Aliases: []string{"共有名"}},
			{ID: "b", Slug: "sku-b", Name: "Sku B", Aliases: []string{"共有名"}},
		},
		unmergedProvisionals: []ProvisionalCandidate{{
			ID:             "prov-1",
			NameNormalized: "共有名",
		}},
	}
	got, err := NewService(repo).MergeExactNames(context.Background())
	if err != nil {
		t.Fatalf("MergeExactNames: %v", err)
	}
	if got.SkippedAmbiguous != 1 || got.Remapped != 0 || len(repo.mergedPairs) != 0 {
		t.Fatalf("report %+v pairs %+v", got, repo.mergedPairs)
	}
}

func TestMergeExactNamesLeavesUnmatched(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{
		publishedIdentities: []PublishedIdentity{{
			ID:   "d45",
			Slug: "dassai-45",
			Name: "獺祭 純米大吟醸 磨き四割五分",
		}},
		unmergedProvisionals: []ProvisionalCandidate{{
			ID:             "prov-1",
			NameNormalized: "獺祭",
		}},
	}
	got, err := NewService(repo).MergeExactNames(context.Background())
	if err != nil {
		t.Fatalf("MergeExactNames: %v", err)
	}
	if got.Remapped != 0 || got.SkippedAmbiguous != 0 || len(repo.mergedPairs) != 0 {
		t.Fatalf("report %+v pairs %+v", got, repo.mergedPairs)
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
