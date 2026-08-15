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
