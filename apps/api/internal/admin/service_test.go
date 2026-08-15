package admin

import (
	"context"
	"errors"
	"testing"
)

type stubRepo struct {
	role        string
	roleErr     error
	overview    *Overview
	overviewErr error
}

func (s *stubRepo) AppRole(context.Context, string) (string, error) {
	return s.role, s.roleErr
}

func (s *stubRepo) Overview(context.Context) (*Overview, error) {
	return s.overview, s.overviewErr
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
	if errors.Is(err, ErrUnauthorized) || errors.Is(err, ErrForbidden) {
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
