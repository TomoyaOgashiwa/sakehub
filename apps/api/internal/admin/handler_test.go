package admin

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/sakehub/api/internal/middleware"
)

func mountAdmin(t *testing.T, repo Repository, userID string) http.Handler {
	t.Helper()
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			if userID != "" {
				req = req.WithContext(context.WithValue(req.Context(), middleware.CtxUserID, userID))
			}
			next.ServeHTTP(w, req)
		})
	})
	NewHandler(NewService(repo)).Routes(r)
	return r
}

func TestOverviewRejectsMissingUserID(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: AppRoleAdmin}, "")

	req := httptest.NewRequest(http.MethodGet, "/overview", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", rec.Code)
	}
}

func TestOverviewRejectsMember(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: "member"}, "member-1")

	req := httptest.NewRequest(http.MethodGet, "/overview", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403", rec.Code)
	}
}

func TestOverviewRejectsMissingUser(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{roleErr: ErrNotFound}, "ghost")

	req := httptest.NewRequest(http.MethodGet, "/overview", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403", rec.Code)
	}
}

func TestOverviewAllowsAdmin(t *testing.T) {
	t.Parallel()
	want := &Overview{
		DrinkMissRows:     3,
		DrinkMissQueries:  2,
		ProvisionalDrinks: 1,
		PublishedDrinks:   8,
	}
	h := mountAdmin(t, &stubRepo{role: AppRoleAdmin, overview: want}, "admin-1")

	req := httptest.NewRequest(http.MethodGet, "/overview", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200 body=%s", rec.Code, rec.Body.String())
	}

	var got Overview
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if got != *want {
		t.Fatalf("got %+v, want %+v", got, *want)
	}
}

func TestOverviewDoesNotUseJWTRole(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: "member"}, "member-1")

	req := httptest.NewRequest(http.MethodGet, "/overview", nil)
	req = req.WithContext(context.WithValue(req.Context(), middleware.CtxRole, "admin"))
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403 when only JWT role is present", rec.Code)
	}
}

func TestOverviewRepoErrorIs500(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: AppRoleAdmin, overviewErr: errors.New("db down")}, "admin-1")

	req := httptest.NewRequest(http.MethodGet, "/overview", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("status = %d, want 500", rec.Code)
	}
}

func TestSearchMissesRejectsMissingUserID(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: AppRoleAdmin, misses: fixtureSearchMisses()}, "")

	req := httptest.NewRequest(http.MethodGet, "/search-misses", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", rec.Code)
	}
}

func TestSearchMissesRejectsMember(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: "member", misses: fixtureSearchMisses()}, "member-1")

	req := httptest.NewRequest(http.MethodGet, "/search-misses", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403", rec.Code)
	}
}

func TestSearchMissesRejectsMissingUser(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{roleErr: ErrNotFound, misses: fixtureSearchMisses()}, "ghost")

	req := httptest.NewRequest(http.MethodGet, "/search-misses", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403", rec.Code)
	}
}

func TestSearchMissesAllowsAdmin(t *testing.T) {
	t.Parallel()
	want := fixtureSearchMisses()
	h := mountAdmin(t, &stubRepo{role: AppRoleAdmin, misses: want}, "admin-1")

	req := httptest.NewRequest(http.MethodGet, "/search-misses", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200 body=%s", rec.Code, rec.Body.String())
	}

	var got SearchMissListResult
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if got.Total != len(want) || len(got.Data) != len(want) {
		t.Fatalf("total=%d len=%d, want %d", got.Total, len(got.Data), len(want))
	}
	if got.Limit != DefaultSearchMissLimit || got.Offset != 0 {
		t.Fatalf("bounds limit=%d offset=%d", got.Limit, got.Offset)
	}
	if got.Data[0].QueryNormalized != "xqzt9zerohitnocatalog" || got.Data[0].SampleQueryRaw == "" {
		t.Fatalf("first row %+v", got.Data[0])
	}
}

func TestSearchMissesFiltersScope(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: AppRoleAdmin, misses: fixtureSearchMisses()}, "admin-1")

	req := httptest.NewRequest(http.MethodGet, "/search-misses?scope=drink", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200 body=%s", rec.Code, rec.Body.String())
	}

	var got SearchMissListResult
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if got.Total != 2 || len(got.Data) != 2 {
		t.Fatalf("total=%d len=%d, want 2 drink rows", got.Total, len(got.Data))
	}
	for _, row := range got.Data {
		if row.Scope != "drink" {
			t.Fatalf("scope = %q, want drink", row.Scope)
		}
	}
}

func TestSearchMissesRejectsInvalidScope(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: AppRoleAdmin, misses: fixtureSearchMisses()}, "admin-1")

	req := httptest.NewRequest(http.MethodGet, "/search-misses?scope=users", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", rec.Code)
	}
}

func TestSearchMissesRejectsInvalidLimit(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: AppRoleAdmin, misses: fixtureSearchMisses()}, "admin-1")

	req := httptest.NewRequest(http.MethodGet, "/search-misses?limit=nope", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", rec.Code)
	}
}

func TestProvisionalDrinksRejectsMissingUserID(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: AppRoleAdmin, provisionals: fixtureProvisionalDrinks()}, "")

	req := httptest.NewRequest(http.MethodGet, "/provisional-drinks", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", rec.Code)
	}
}

func TestProvisionalDrinksRejectsMember(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: "member", provisionals: fixtureProvisionalDrinks()}, "member-1")

	req := httptest.NewRequest(http.MethodGet, "/provisional-drinks", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403", rec.Code)
	}
}

func TestProvisionalDrinksRejectsMissingUser(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{roleErr: ErrNotFound, provisionals: fixtureProvisionalDrinks()}, "ghost")

	req := httptest.NewRequest(http.MethodGet, "/provisional-drinks", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403", rec.Code)
	}
}

func TestProvisionalDrinksAllowsAdminProvisionalOnly(t *testing.T) {
	t.Parallel()
	want := fixtureProvisionalDrinks()
	h := mountAdmin(t, &stubRepo{role: AppRoleAdmin, provisionals: want}, "admin-1")

	req := httptest.NewRequest(http.MethodGet, "/provisional-drinks", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200 body=%s", rec.Code, rec.Body.String())
	}

	var got ProvisionalDrinkListResult
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if got.Total != len(want) || len(got.Data) != len(want) {
		t.Fatalf("total=%d len=%d, want %d", got.Total, len(got.Data), len(want))
	}
	if got.Limit != DefaultProvisionalLimit || got.Offset != 0 {
		t.Fatalf("bounds limit=%d offset=%d", got.Limit, got.Offset)
	}
	for _, row := range got.Data {
		if row.Name != "禅人未登録ラベル" || row.NameNormalized != "禅人未登録らべる" {
			t.Fatalf("non-provisional or unexpected row %+v", row)
		}
		if row.SubmittedBy == "" || row.SubmitterEmail == "" {
			t.Fatalf("submitter missing %+v", row)
		}
		if !row.HasSavedDrink {
			t.Fatalf("fixture stakes must have saved_drinks %+v", row)
		}
	}
}

func TestProvisionalDrinksRejectsInvalidLimit(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: AppRoleAdmin, provisionals: fixtureProvisionalDrinks()}, "admin-1")

	req := httptest.NewRequest(http.MethodGet, "/provisional-drinks?limit=nope", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", rec.Code)
	}
}

func TestProvisionalDrinksWriteMethodsAreNotRegistered(t *testing.T) {
	t.Parallel()
	h := mountAdmin(t, &stubRepo{role: AppRoleAdmin, provisionals: fixtureProvisionalDrinks()}, "admin-1")

	for _, method := range []string{http.MethodPost, http.MethodPatch, http.MethodPut, http.MethodDelete} {
		req := httptest.NewRequest(method, "/provisional-drinks", nil)
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		if rec.Code != http.StatusMethodNotAllowed {
			t.Fatalf("%s status = %d, want 405", method, rec.Code)
		}
	}
}
