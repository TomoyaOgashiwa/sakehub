package cocktail

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"strings"
)

var validUnits = map[string]bool{
	"ml": true, "g": true, "piece": true, "tsp": true, "tbsp": true,
	"dash": true, "drop": true, "oz": true, "cl": true,
}

var validStatuses = map[string]bool{
	"draft": true, "published": true,
}

var uuidPattern = regexp.MustCompile(`(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)

type Service struct {
	repo Repository
}

func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) ListCocktails(ctx context.Context, params ListParams) ([]Cocktail, int, error) {
	params.Query = strings.TrimSpace(params.Query)
	params.BaseSpirit = strings.TrimSpace(params.BaseSpirit)
	params.Limit, params.Offset = clampListBounds(
		params.Limit, params.Offset, DefaultCocktailListLimit, MaxCocktailListLimit,
	)

	cocktails, total, err := s.repo.ListCocktails(ctx, params)
	if err != nil {
		return nil, 0, fmt.Errorf("cocktail.ListCocktails: %w", err)
	}
	return cocktails, total, nil
}

// GetCocktailBySlug returns the master record together with a page of its
// published (non-official) recipes and the official basic recipe when present.
func (s *Service) GetCocktailBySlug(ctx context.Context, slug string, limit, offset int) (*CocktailDetail, error) {
	c, err := s.repo.FindCocktailBySlug(ctx, slug)
	if err != nil {
		return nil, fmt.Errorf("cocktail.GetCocktailBySlug: %w", err)
	}

	limit, offset = clampListBounds(limit, offset, DefaultPublishedRecipeLimit, MaxPublishedRecipeLimit)

	recipes, hasMore, err := s.repo.ListPublishedRecipes(ctx, c.ID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("cocktail.GetCocktailBySlug recipes: %w", err)
	}

	detail := &CocktailDetail{
		Cocktail:       *c,
		Recipes:        recipes,
		HasMoreRecipes: hasMore,
	}

	// Unregistered official recipes are normal until the seed batch covers all
	// cocktails; treat ErrNotFound as OfficialRecipe = nil, not a 404.
	official, err := s.repo.FindOfficialRecipeByCocktailID(ctx, c.ID)
	if err != nil && !errors.Is(err, ErrNotFound) {
		return nil, fmt.Errorf("cocktail.GetCocktailBySlug official: %w", err)
	}
	if err == nil {
		detail.OfficialRecipe = official
	}

	return detail, nil
}

func (s *Service) ListMine(ctx context.Context, userID string, limit, offset int) ([]MyRecipeSummary, int, error) {
	limit, offset = clampListBounds(limit, offset, DefaultMineRecipeLimit, MaxMineRecipeLimit)

	recipes, total, err := s.repo.ListMine(ctx, userID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("cocktail.ListMine: %w", err)
	}
	return recipes, total, nil
}

func (s *Service) GetRecipeByID(ctx context.Context, id string) (*Recipe, error) {
	if !isUUID(id) {
		return nil, ErrInvalidUUID
	}

	recipe, err := s.repo.FindPublishedRecipeByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("cocktail.GetRecipeByID: %w", err)
	}
	return recipe, nil
}

func (s *Service) Create(ctx context.Context, input CreateInput) (*Recipe, error) {
	if err := validate(input); err != nil {
		return nil, err
	}

	recipe, err := s.repo.Insert(ctx, input)
	if err != nil {
		if errors.Is(err, ErrValidation) {
			return nil, err
		}
		return nil, fmt.Errorf("cocktail.Create: %w", err)
	}
	return recipe, nil
}

func (s *Service) ListRatingsByRecipe(ctx context.Context, recipeID string, limit, offset int) (*RatingListResult, error) {
	if !isUUID(recipeID) {
		return nil, ErrInvalidUUID
	}
	// Align with public recipe GET: draft / official / unknown IDs must not leak ratings.
	if err := s.repo.RatableRecipeExists(ctx, recipeID); err != nil {
		return nil, err
	}

	limit, offset = clampListBounds(limit, offset, DefaultRatingListLimit, MaxRatingListLimit)

	ratings, hasMore, err := s.repo.ListRatingsByRecipe(ctx, recipeID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("cocktail.ListRatingsByRecipe: %w", err)
	}
	return &RatingListResult{Data: ratings, HasMore: hasMore}, nil
}

func (s *Service) GetRatingByRecipeAndUser(ctx context.Context, recipeID, userID string) (*RecipeRating, error) {
	if !isUUID(recipeID) {
		return nil, ErrInvalidUUID
	}
	if err := s.repo.RatableRecipeExists(ctx, recipeID); err != nil {
		return nil, err
	}

	rating, err := s.repo.FindRatingByRecipeAndUser(ctx, recipeID, userID)
	if err != nil {
		return nil, err
	}
	return rating, nil
}

func (s *Service) UpsertRating(ctx context.Context, input RatingUpsertInput, userID string) (*RecipeRating, error) {
	if !isUUID(input.RecipeID) {
		return nil, ErrInvalidUUID
	}
	if input.Rating < 1 || input.Rating > 5 {
		return nil, ErrInvalidRating
	}
	if len([]rune(input.Comment)) > 1000 {
		return nil, validationErrorf("comment must be 1000 characters or fewer")
	}

	rating := &RecipeRating{
		RecipeID: input.RecipeID,
		UserID:   userID,
		Rating:   input.Rating,
		Comment:  input.Comment,
	}

	// Published + non-official check is atomic inside UpsertRating.
	if err := s.repo.UpsertRating(ctx, rating); err != nil {
		if errors.Is(err, ErrValidation) || errors.Is(err, ErrNotFound) {
			return nil, err
		}
		return nil, fmt.Errorf("cocktail.UpsertRating: %w", err)
	}
	return rating, nil
}

func (s *Service) DeleteRating(ctx context.Context, id, userID string) error {
	if !isUUID(id) {
		return ErrInvalidUUID
	}

	if err := s.repo.DeleteRating(ctx, id, userID); err != nil {
		if errors.Is(err, ErrForbidden) {
			return err
		}
		return fmt.Errorf("cocktail.DeleteRating: %w", err)
	}
	return nil
}

func isUUID(v string) bool {
	return uuidPattern.MatchString(strings.TrimSpace(v))
}

func clampListBounds(limit, offset, defaultLimit, maxLimit int) (int, int) {
	if limit <= 0 {
		limit = defaultLimit
	}
	if limit > maxLimit {
		limit = maxLimit
	}
	if offset < 0 {
		offset = 0
	}
	return limit, offset
}

func validate(input CreateInput) error {
	if !isUUID(strings.TrimSpace(input.CocktailID)) {
		return validationErrorf("cocktail_id must be a valid uuid")
	}

	name := strings.TrimSpace(input.Name)
	if name == "" {
		return validationErrorf("name is required")
	}
	if len([]rune(name)) > 100 {
		return validationErrorf("name must be 100 characters or fewer")
	}

	if input.Memo != nil && len([]rune(*input.Memo)) > 1000 {
		return validationErrorf("memo must be 1000 characters or fewer")
	}

	if !validStatuses[input.Status] {
		return validationErrorf("status must be 'draft' or 'published'")
	}

	// published requires ≥1 ingredient and ≥1 step (SEO / recipeInstructions).
	// draft may have empty ingredients and steps.
	if input.Status == "published" {
		if len(input.Ingredients) == 0 {
			return validationErrorf("at least one ingredient is required")
		}
		if len(input.Steps) == 0 {
			return validationErrorf("at least one step is required")
		}
	}

	for i, ing := range input.Ingredients {
		ingName := strings.TrimSpace(ing.Name)
		if ingName == "" {
			return validationErrorf("ingredient[%d] name is required", i)
		}
		if len([]rune(ingName)) > 100 {
			return validationErrorf("ingredient[%d] name must be 100 characters or fewer", i)
		}
		if ing.Unit != nil && !validUnits[*ing.Unit] {
			return validationErrorf("ingredient[%d] has invalid unit", i)
		}
		if ing.Amount != nil && *ing.Amount <= 0 {
			return validationErrorf("ingredient[%d] amount must be positive", i)
		}
	}

	for i, step := range input.Steps {
		body := strings.TrimSpace(step.Body)
		if body == "" {
			return validationErrorf("step[%d] body is required", i)
		}
		if len([]rune(body)) > 500 {
			return validationErrorf("step[%d] body must be 500 characters or fewer", i)
		}
	}

	return nil
}
