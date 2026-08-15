package admin

import (
	"context"
	"errors"
	"testing"
	"time"
)

func fixtureSearchMisses() []SearchMissRow {
	seen := time.Date(2024, 3, 8, 0, 0, 0, 0, time.UTC)
	return []SearchMissRow{
		{
			Scope:           "drink",
			QueryNormalized: "xqzt9zerohitnocatalog",
			SampleQueryRaw:  "xqzt9zeroHitNoCatalog",
			MissCount:       3,
			UniqueSearchers: 2,
			LastSeenAt:      seen,
		},
		{
			Scope:           "drink",
			QueryNormalized: "qlm8vortanox",
			SampleQueryRaw:  "QLM8 Vortanox",
			MissCount:       2,
			UniqueSearchers: 2,
			LastSeenAt:      seen,
		},
		{
			Scope:           "cocktail",
			QueryNormalized: "zynthrelfizz",
			SampleQueryRaw:  "Zynthrel Fizz",
			MissCount:       2,
			UniqueSearchers: 1,
			LastSeenAt:      seen,
		},
	}
}

func fixtureProvisionalDrinks() []ProvisionalDrinkRow {
	created := time.Date(2000, 1, 2, 0, 0, 0, 0, time.UTC)
	drank := savedStatusDrank
	return []ProvisionalDrinkRow{
		{
			ID:                   "b2000000-0000-4000-8000-000000000001",
			Name:                 "禅人未登録ラベル",
			NameNormalized:       "禅人未登録らべる",
			SubmittedBy:          "a1000000-0000-4000-8000-000000000001",
			SubmitterDisplayName: "評価者01",
			SubmitterEmail:       "rater01@example.com",
			CreatedAt:            created,
			HasSavedDrink:        true,
			SavedStatus:          &drank,
		},
		{
			ID:                   "b2000000-0000-4000-8000-000000000002",
			Name:                 "禅人未登録ラベル",
			NameNormalized:       "禅人未登録らべる",
			SubmittedBy:          "a1000000-0000-4000-8000-000000000002",
			SubmitterDisplayName: "評価者02",
			SubmitterEmail:       "rater02@example.com",
			CreatedAt:            created,
			HasSavedDrink:        true,
			SavedStatus:          &drank,
		},
	}
}

type stubRepo struct {
	role            string
	roleErr         error
	overview        *Overview
	overviewErr     error
	misses          []SearchMissRow
	missesErr       error
	lastMiss        SearchMissListParams
	provisionals    []ProvisionalDrinkRow
	provisionalsErr error
	lastProv        ProvisionalDrinkListParams
}

func (s *stubRepo) AppRole(context.Context, string) (string, error) {
	return s.role, s.roleErr
}

func (s *stubRepo) Overview(context.Context) (*Overview, error) {
	return s.overview, s.overviewErr
}

func (s *stubRepo) ListSearchMisses(_ context.Context, p SearchMissListParams) ([]SearchMissRow, int, error) {
	s.lastMiss = p
	if s.missesErr != nil {
		return nil, 0, s.missesErr
	}
	rows := s.misses
	if p.Scope != "" {
		filtered := make([]SearchMissRow, 0, len(rows))
		for _, row := range rows {
			if row.Scope == p.Scope {
				filtered = append(filtered, row)
			}
		}
		rows = filtered
	}
	total := len(rows)
	if p.Offset > total {
		return []SearchMissRow{}, total, nil
	}
	rows = rows[p.Offset:]
	if p.Limit > 0 && len(rows) > p.Limit {
		rows = rows[:p.Limit]
	}
	return rows, total, nil
}

func (s *stubRepo) ListProvisionalDrinks(_ context.Context, p ProvisionalDrinkListParams) ([]ProvisionalDrinkRow, int, error) {
	s.lastProv = p
	if s.provisionalsErr != nil {
		return nil, 0, s.provisionalsErr
	}
	rows := s.provisionals
	total := len(rows)
	if p.Offset > total {
		return []ProvisionalDrinkRow{}, total, nil
	}
	rows = rows[p.Offset:]
	if p.Limit > 0 && len(rows) > p.Limit {
		rows = rows[:p.Limit]
	}
	return rows, total, nil
}

func TestIsAdminRejectsEmptyUserID(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{role: AppRoleAdmin})

	ok, err := svc.IsAdmin(context.Background(), "")
	if !errors.Is(err, ErrUnauthorized) {
		t.Fatalf("err = %v, want ErrUnauthorized", err)
	}
	if ok {
		t.Fatal("empty user id must not be admin")
	}
}

func TestIsAdminRejectsMember(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{role: "member"})

	ok, err := svc.IsAdmin(context.Background(), "user-1")
	if err != nil {
		t.Fatalf("IsAdmin: %v", err)
	}
	if ok {
		t.Fatal("member must not be admin")
	}
}

func TestIsAdminRejectsMissingUser(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{roleErr: ErrNotFound})

	ok, err := svc.IsAdmin(context.Background(), "missing")
	if err != nil {
		t.Fatalf("IsAdmin: %v", err)
	}
	if ok {
		t.Fatal("missing user must not be admin")
	}
}

func TestIsAdminAcceptsAdmin(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{role: AppRoleAdmin})

	ok, err := svc.IsAdmin(context.Background(), "admin-1")
	if err != nil {
		t.Fatalf("IsAdmin: %v", err)
	}
	if !ok {
		t.Fatal("admin role must be accepted")
	}
}

func TestIsAdminWrapsRepositoryError(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{roleErr: errors.New("db down")})

	ok, err := svc.IsAdmin(context.Background(), "user-1")
	if err == nil {
		t.Fatal("expected error")
	}
	if errors.Is(err, ErrUnauthorized) {
		t.Fatalf("repo failure must not look like authz: %v", err)
	}
	if ok {
		t.Fatal("repo failure must not be admin")
	}
}

func TestOverviewReturnsRepositoryCounts(t *testing.T) {
	t.Parallel()
	want := &Overview{
		DrinkMissRows:     4,
		DrinkMissQueries:  2,
		ProvisionalDrinks: 1,
		PublishedDrinks:   10,
	}
	svc := NewService(&stubRepo{overview: want})

	got, err := svc.Overview(context.Background())
	if err != nil {
		t.Fatalf("Overview: %v", err)
	}
	if got != want {
		t.Fatalf("got %+v, want %+v", got, want)
	}
}

func TestListSearchMissesRejectsInvalidScope(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})

	got, err := svc.ListSearchMisses(context.Background(), SearchMissListParams{Scope: "users"})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want ErrValidation", err)
	}
	if got != nil {
		t.Fatalf("got %+v, want nil", got)
	}
}

func TestListSearchMissesTreatsAllAsUnfiltered(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{misses: fixtureSearchMisses()}
	svc := NewService(repo)

	got, err := svc.ListSearchMisses(context.Background(), SearchMissListParams{Scope: "all"})
	if err != nil {
		t.Fatalf("ListSearchMisses: %v", err)
	}
	if repo.lastMiss.Scope != "" {
		t.Fatalf("repo scope = %q, want empty (all)", repo.lastMiss.Scope)
	}
	if got.Total != 3 || len(got.Data) != 3 {
		t.Fatalf("total=%d len=%d, want 3", got.Total, len(got.Data))
	}
}

func TestListSearchMissesFiltersScope(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{misses: fixtureSearchMisses()}
	svc := NewService(repo)

	got, err := svc.ListSearchMisses(context.Background(), SearchMissListParams{Scope: "cocktail"})
	if err != nil {
		t.Fatalf("ListSearchMisses: %v", err)
	}
	if repo.lastMiss.Scope != "cocktail" {
		t.Fatalf("repo scope = %q, want cocktail", repo.lastMiss.Scope)
	}
	if got.Total != 1 || len(got.Data) != 1 {
		t.Fatalf("total=%d len=%d, want 1", got.Total, len(got.Data))
	}
	if got.Data[0].Scope != "cocktail" || got.Data[0].QueryNormalized != "zynthrelfizz" {
		t.Fatalf("got %+v", got.Data[0])
	}
}

func TestListSearchMissesClampsLimitAndOffset(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{misses: fixtureSearchMisses()}
	svc := NewService(repo)

	got, err := svc.ListSearchMisses(context.Background(), SearchMissListParams{
		Limit:  500,
		Offset: -3,
	})
	if err != nil {
		t.Fatalf("ListSearchMisses: %v", err)
	}
	if repo.lastMiss.Limit != MaxSearchMissLimit {
		t.Fatalf("limit = %d, want %d", repo.lastMiss.Limit, MaxSearchMissLimit)
	}
	if repo.lastMiss.Offset != 0 {
		t.Fatalf("offset = %d, want 0", repo.lastMiss.Offset)
	}
	if got.Limit != MaxSearchMissLimit || got.Offset != 0 {
		t.Fatalf("result bounds limit=%d offset=%d", got.Limit, got.Offset)
	}
}

func TestListSearchMissesWrapsRepositoryError(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{missesErr: errors.New("db down")})

	got, err := svc.ListSearchMisses(context.Background(), SearchMissListParams{})
	if err == nil {
		t.Fatal("expected error")
	}
	if errors.Is(err, ErrValidation) || errors.Is(err, ErrUnauthorized) {
		t.Fatalf("repo failure must not look like validation/authz: %v", err)
	}
	if got != nil {
		t.Fatalf("got %+v, want nil", got)
	}
}

func TestListProvisionalDrinksReturnsUnmergedStakes(t *testing.T) {
	t.Parallel()
	want := fixtureProvisionalDrinks()
	svc := NewService(&stubRepo{provisionals: want})

	got, err := svc.ListProvisionalDrinks(context.Background(), ProvisionalDrinkListParams{})
	if err != nil {
		t.Fatalf("ListProvisionalDrinks: %v", err)
	}
	if got.Total != 2 || len(got.Data) != 2 {
		t.Fatalf("total=%d len=%d, want 2", got.Total, len(got.Data))
	}
	if got.Data[0].Name != "禅人未登録ラベル" || got.Data[0].NameNormalized != "禅人未登録らべる" {
		t.Fatalf("first row %+v", got.Data[0])
	}
	if got.Data[0].SubmitterEmail != "rater01@example.com" {
		t.Fatalf("email = %q", got.Data[0].SubmitterEmail)
	}
	if !got.Data[0].HasSavedDrink || got.Data[0].SavedStatus == nil || *got.Data[0].SavedStatus != savedStatusDrank {
		t.Fatalf("saved %+v", got.Data[0])
	}
	if got.Limit != DefaultProvisionalLimit || got.Offset != 0 {
		t.Fatalf("bounds limit=%d offset=%d", got.Limit, got.Offset)
	}
}

func TestListProvisionalDrinksEmptyIsEmptySlice(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})

	got, err := svc.ListProvisionalDrinks(context.Background(), ProvisionalDrinkListParams{})
	if err != nil {
		t.Fatalf("ListProvisionalDrinks: %v", err)
	}
	if got.Data == nil || len(got.Data) != 0 {
		t.Fatalf("data = %#v, want empty slice", got.Data)
	}
}

func TestListProvisionalDrinksDropsInvalidSavedStatus(t *testing.T) {
	t.Parallel()
	bad := "published"
	svc := NewService(&stubRepo{provisionals: []ProvisionalDrinkRow{{
		ID:             "prov-1",
		Name:           "禅人未登録ラベル",
		NameNormalized: "禅人未登録らべる",
		SubmittedBy:    "user-1",
		HasSavedDrink:  true,
		SavedStatus:    &bad,
	}}})

	got, err := svc.ListProvisionalDrinks(context.Background(), ProvisionalDrinkListParams{})
	if err != nil {
		t.Fatalf("ListProvisionalDrinks: %v", err)
	}
	if got.Data[0].SavedStatus != nil {
		t.Fatalf("saved_status = %v, want nil", *got.Data[0].SavedStatus)
	}
}

func TestListProvisionalDrinksClampsLimitAndOffset(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{provisionals: fixtureProvisionalDrinks()}
	svc := NewService(repo)

	got, err := svc.ListProvisionalDrinks(context.Background(), ProvisionalDrinkListParams{
		Limit:  500,
		Offset: -3,
	})
	if err != nil {
		t.Fatalf("ListProvisionalDrinks: %v", err)
	}
	if repo.lastProv.Limit != MaxProvisionalLimit {
		t.Fatalf("limit = %d, want %d", repo.lastProv.Limit, MaxProvisionalLimit)
	}
	if repo.lastProv.Offset != 0 {
		t.Fatalf("offset = %d, want 0", repo.lastProv.Offset)
	}
	if got.Limit != MaxProvisionalLimit || got.Offset != 0 {
		t.Fatalf("result bounds limit=%d offset=%d", got.Limit, got.Offset)
	}
}

func TestListProvisionalDrinksWrapsRepositoryError(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{provisionalsErr: errors.New("db down")})

	got, err := svc.ListProvisionalDrinks(context.Background(), ProvisionalDrinkListParams{})
	if err == nil {
		t.Fatal("expected error")
	}
	if errors.Is(err, ErrValidation) || errors.Is(err, ErrUnauthorized) {
		t.Fatalf("repo failure must not look like validation/authz: %v", err)
	}
	if got != nil {
		t.Fatalf("got %+v, want nil", got)
	}
}
