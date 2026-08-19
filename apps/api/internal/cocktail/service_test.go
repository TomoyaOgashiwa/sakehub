package cocktail

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"
)

const (
	testRecipeID   = "11111111-1111-1111-1111-111111111111"
	testUserID     = "22222222-2222-2222-2222-222222222222"
	testCocktailID = "33333333-3333-3333-3333-333333333333"
)

type stubRepo struct {
	owned        *Recipe
	ownedErr     error
	updated      *Recipe
	updateErr    error
	updateCalled bool
	lastUpdate   DraftUpdateInput
	deleted      bool
	deleteErr    error
	published    *Recipe
	insertErr    error
}

func (s *stubRepo) ListCocktails(context.Context, ListParams) ([]Cocktail, int, error) {
	return nil, 0, nil
}
func (s *stubRepo) FindCocktailBySlug(context.Context, string) (*Cocktail, error) {
	return nil, ErrCocktailNotFound
}
func (s *stubRepo) ListPublishedRecipes(context.Context, string, int, int) ([]RecipeSummary, bool, error) {
	return nil, false, nil
}
func (s *stubRepo) ListMine(context.Context, string, int, int) ([]MyRecipeSummary, int, error) {
	return nil, 0, nil
}
func (s *stubRepo) FindPublishedRecipeByID(context.Context, string) (*Recipe, error) {
	if s.published != nil {
		return s.published, nil
	}
	return nil, ErrNotFound
}
func (s *stubRepo) FindOfficialRecipeByCocktailID(context.Context, string) (*Recipe, error) {
	return nil, ErrNotFound
}
func (s *stubRepo) RatableRecipeExists(context.Context, string) error { return nil }
func (s *stubRepo) Insert(context.Context, CreateInput) (*Recipe, error) {
	return nil, s.insertErr
}
func (s *stubRepo) FindOwnedRecipeByID(context.Context, string, string) (*Recipe, error) {
	if s.ownedErr != nil {
		return nil, s.ownedErr
	}
	if s.owned == nil {
		return nil, ErrNotFound
	}
	cp := *s.owned
	return &cp, nil
}
func (s *stubRepo) UpdateDraft(_ context.Context, _ string, _ string, input DraftUpdateInput) (*Recipe, error) {
	s.updateCalled = true
	s.lastUpdate = input
	if s.updateErr != nil {
		return nil, s.updateErr
	}
	if s.updated != nil {
		return s.updated, nil
	}
	return &Recipe{ID: testRecipeID, Status: input.Status, CocktailSlug: "manhattan"}, nil
}
func (s *stubRepo) DeleteDraft(context.Context, string, string) error {
	s.deleted = true
	return s.deleteErr
}
func (s *stubRepo) FindRatingByRecipeAndUser(context.Context, string, string) (*RecipeRating, error) {
	return nil, ErrRatingNotFound
}
func (s *stubRepo) ListRatingsByRecipe(context.Context, string, int, int) ([]RecipeRating, bool, error) {
	return nil, false, nil
}
func (s *stubRepo) UpsertRating(context.Context, *RecipeRating) error  { return nil }
func (s *stubRepo) DeleteRating(context.Context, string, string) error { return nil }

func draftOwned() *Recipe {
	memo := "keep me"
	image := "https://example.com/old.jpg"
	return &Recipe{
		ID:         testRecipeID,
		CocktailID: testCocktailID,
		Name:       "Old name",
		Status:     "draft",
		Memo:       &memo,
		ImageURL:   &image,
		Ingredients: []Ingredient{
			{Name: "gin", SortOrder: 0},
		},
		Steps: []Step{
			{Body: "stir", SortOrder: 0},
		},
	}
}

func publishedOwned() *Recipe {
	rec := draftOwned()
	rec.Status = "published"
	return rec
}

func mustRaw(t *testing.T, v any) json.RawMessage {
	t.Helper()
	b, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	return b
}

func TestPatchOwnedPublishedRejectsEvenNameOnly(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{owned: publishedOwned()}
	svc := NewService(repo)

	_, err := svc.PatchOwnedRecipe(context.Background(), testUserID, testRecipeID, map[string]json.RawMessage{
		"name": mustRaw(t, "New name"),
	})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want ErrValidation", err)
	}
	if !strings.Contains(err.Error(), msgPublishedCannotUpdate) {
		t.Fatalf("err = %v, want %q", err, msgPublishedCannotUpdate)
	}
	if repo.updateCalled {
		t.Fatal("UpdateDraft must not run for a published recipe")
	}
}

func TestPatchOwnedPublishedRejectsIngredients(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{owned: publishedOwned()}
	svc := NewService(repo)

	_, err := svc.PatchOwnedRecipe(context.Background(), testUserID, testRecipeID, map[string]json.RawMessage{
		"ingredients": mustRaw(t, []IngredientInput{{Name: "gin", SortOrder: 0}}),
	})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want ErrValidation", err)
	}
	if repo.updateCalled {
		t.Fatal("UpdateDraft must not run when published + ingredients")
	}
}

func TestPatchOwnedDraftPublishRequiresIngredientAndStep(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{owned: draftOwned()}
	svc := NewService(repo)

	_, err := svc.PatchOwnedRecipe(context.Background(), testUserID, testRecipeID, map[string]json.RawMessage{
		"cocktail_id": mustRaw(t, testCocktailID),
		"name":        mustRaw(t, "Negroni"),
		"status":      mustRaw(t, "published"),
	})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want ErrValidation", err)
	}
	if !strings.Contains(err.Error(), "at least one ingredient") {
		t.Fatalf("err = %v, want ingredient required", err)
	}
	if repo.updateCalled {
		t.Fatal("UpdateDraft must not run when publish validation fails")
	}
}

func TestPatchOwnedDraftPublishSucceedsWithBody(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{owned: draftOwned()}
	svc := NewService(repo)

	got, err := svc.PatchOwnedRecipe(context.Background(), testUserID, testRecipeID, map[string]json.RawMessage{
		"cocktail_id": mustRaw(t, testCocktailID),
		"name":        mustRaw(t, "Negroni"),
		"status":      mustRaw(t, "published"),
		"ingredients": mustRaw(t, []IngredientInput{{Name: "gin", SortOrder: 0}}),
		"steps":       mustRaw(t, []StepInput{{Body: "stir", SortOrder: 0}}),
	})
	if err != nil {
		t.Fatalf("PatchOwnedRecipe: %v", err)
	}
	if !repo.updateCalled {
		t.Fatal("UpdateDraft should run")
	}
	if repo.lastUpdate.Status != "published" {
		t.Fatalf("status = %q, want published", repo.lastUpdate.Status)
	}
	if got == nil || got.CocktailSlug != "manhattan" {
		t.Fatalf("got = %+v, want slug from UpdateDraft", got)
	}
}

func TestPatchOwnedDraftOmitsImageKeepsExisting(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{owned: draftOwned()}
	svc := NewService(repo)

	_, err := svc.PatchOwnedRecipe(context.Background(), testUserID, testRecipeID, map[string]json.RawMessage{
		"cocktail_id": mustRaw(t, testCocktailID),
		"name":        mustRaw(t, "Negroni"),
		"status":      mustRaw(t, "draft"),
	})
	if err != nil {
		t.Fatalf("PatchOwnedRecipe: %v", err)
	}
	if repo.lastUpdate.ImageURL == nil || *repo.lastUpdate.ImageURL != "https://example.com/old.jpg" {
		t.Fatalf("image_url = %v, want existing", repo.lastUpdate.ImageURL)
	}
	if repo.lastUpdate.Memo == nil || *repo.lastUpdate.Memo != "keep me" {
		t.Fatalf("memo = %v, want existing", repo.lastUpdate.Memo)
	}
}

func TestPatchOwnedDraftNullImageClears(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{owned: draftOwned()}
	svc := NewService(repo)

	_, err := svc.PatchOwnedRecipe(context.Background(), testUserID, testRecipeID, map[string]json.RawMessage{
		"cocktail_id": mustRaw(t, testCocktailID),
		"name":        mustRaw(t, "Negroni"),
		"status":      mustRaw(t, "draft"),
		"image_url":   json.RawMessage("null"),
		"memo":        json.RawMessage("null"),
	})
	if err != nil {
		t.Fatalf("PatchOwnedRecipe: %v", err)
	}
	if repo.lastUpdate.ImageURL != nil {
		t.Fatalf("image_url = %v, want nil", repo.lastUpdate.ImageURL)
	}
	if repo.lastUpdate.Memo != nil {
		t.Fatalf("memo = %v, want nil", repo.lastUpdate.Memo)
	}
}

func TestPatchOwnedRejectsIsOfficialKey(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{owned: draftOwned()}
	svc := NewService(repo)

	_, err := svc.PatchOwnedRecipe(context.Background(), testUserID, testRecipeID, map[string]json.RawMessage{
		"is_official": mustRaw(t, true),
		"name":        mustRaw(t, "Negroni"),
	})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want ErrValidation", err)
	}
	if !strings.Contains(err.Error(), msgIsOfficialForbidden) {
		t.Fatalf("err = %v, want is_official forbidden", err)
	}
	if repo.updateCalled {
		t.Fatal("UpdateDraft must not run for is_official")
	}
}

func TestPatchOwnedRejectsUnknownKey(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{owned: draftOwned()}
	svc := NewService(repo)

	_, err := svc.PatchOwnedRecipe(context.Background(), testUserID, testRecipeID, map[string]json.RawMessage{
		"user_id": mustRaw(t, testUserID),
	})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want ErrValidation", err)
	}
	if !strings.Contains(err.Error(), "unknown field") {
		t.Fatalf("err = %v, want unknown field", err)
	}
	if repo.updateCalled {
		t.Fatal("UpdateDraft must not run for unknown keys")
	}
}

func TestPatchOwnedOmittedIngredientsAreEmptyNotKept(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{owned: draftOwned()}
	svc := NewService(repo)

	_, err := svc.PatchOwnedRecipe(context.Background(), testUserID, testRecipeID, map[string]json.RawMessage{
		"cocktail_id": mustRaw(t, testCocktailID),
		"name":        mustRaw(t, "Negroni"),
		"status":      mustRaw(t, "draft"),
	})
	if err != nil {
		t.Fatalf("PatchOwnedRecipe: %v", err)
	}
	if len(repo.lastUpdate.Ingredients) != 0 {
		t.Fatalf("ingredients = %+v, want empty (full replace)", repo.lastUpdate.Ingredients)
	}
}

func TestGetOwnedRecipeInvalidUUID(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})
	_, err := svc.GetOwnedRecipe(context.Background(), testUserID, "not-a-uuid")
	if !errors.Is(err, ErrInvalidUUID) {
		t.Fatalf("err = %v, want ErrInvalidUUID", err)
	}
}

func TestGetOwnedRecipeNotFound(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{ownedErr: ErrNotFound})
	_, err := svc.GetOwnedRecipe(context.Background(), testUserID, testRecipeID)
	if !errors.Is(err, ErrNotFound) {
		t.Fatalf("err = %v, want ErrNotFound", err)
	}
}

func TestDeleteOwnedDraftInvalidUUID(t *testing.T) {
	t.Parallel()
	svc := NewService(&stubRepo{})
	err := svc.DeleteOwnedDraft(context.Background(), testUserID, "bad")
	if !errors.Is(err, ErrInvalidUUID) {
		t.Fatalf("err = %v, want ErrInvalidUUID", err)
	}
}

func TestDeleteOwnedDraftPublished(t *testing.T) {
	t.Parallel()
	repo := &stubRepo{deleteErr: validationErrorf("%s", msgPublishedCannotDelete)}
	svc := NewService(repo)
	err := svc.DeleteOwnedDraft(context.Background(), testUserID, testRecipeID)
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("err = %v, want ErrValidation", err)
	}
}
