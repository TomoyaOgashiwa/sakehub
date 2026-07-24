package cocktail

import (
	"context"
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

func (s *Service) ListCocktails(ctx context.Context) ([]Cocktail, error) {
	cocktails, err := s.repo.ListCocktails(ctx)
	if err != nil {
		return nil, fmt.Errorf("cocktail.ListCocktails: %w", err)
	}
	return cocktails, nil
}

// GetCocktailBySlug returns the master record together with its published
// recipes so the genre detail page needs only one API call.
func (s *Service) GetCocktailBySlug(ctx context.Context, slug string) (*CocktailDetail, error) {
	c, err := s.repo.FindCocktailBySlug(ctx, slug)
	if err != nil {
		return nil, fmt.Errorf("cocktail.GetCocktailBySlug: %w", err)
	}

	recipes, err := s.repo.ListPublishedRecipes(ctx, c.ID, DefaultPublishedRecipeLimit)
	if err != nil {
		return nil, fmt.Errorf("cocktail.GetCocktailBySlug recipes: %w", err)
	}

	return &CocktailDetail{Cocktail: *c, Recipes: recipes}, nil
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
		return nil, fmt.Errorf("cocktail.Create: %w", err)
	}

	recipe, err := s.repo.Insert(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("cocktail.Create: %w", err)
	}
	return recipe, nil
}

func (s *Service) ListRatingsByRecipe(ctx context.Context, recipeID string) ([]RecipeRating, error) {
	if !isUUID(recipeID) {
		return nil, ErrInvalidUUID
	}

	ratings, err := s.repo.ListRatingsByRecipe(ctx, recipeID, DefaultRatingListLimit)
	if err != nil {
		return nil, fmt.Errorf("cocktail.ListRatingsByRecipe: %w", err)
	}
	return ratings, nil
}

func (s *Service) GetRatingByRecipeAndUser(ctx context.Context, recipeID, userID string) (*RecipeRating, error) {
	if !isUUID(recipeID) {
		return nil, ErrInvalidUUID
	}

	rating, err := s.repo.FindRatingByRecipeAndUser(ctx, recipeID, userID)
	if err != nil {
		return nil, fmt.Errorf("cocktail.GetRatingByRecipeAndUser: %w", err)
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
		return nil, fmt.Errorf("%w: comment must be 1000 characters or fewer", ErrValidation)
	}

	// Only published recipes are rateable (align with the public GET endpoint).
	if err := s.repo.PublishedRecipeExists(ctx, input.RecipeID); err != nil {
		return nil, fmt.Errorf("cocktail.UpsertRating: %w", err)
	}

	rating := &RecipeRating{
		RecipeID: input.RecipeID,
		UserID:   userID,
		Rating:   input.Rating,
		Comment:  input.Comment,
	}

	if err := s.repo.UpsertRating(ctx, rating); err != nil {
		return nil, fmt.Errorf("cocktail.UpsertRating: %w", err)
	}
	return rating, nil
}

func (s *Service) DeleteRating(ctx context.Context, id, userID string) error {
	if !isUUID(id) {
		return ErrInvalidUUID
	}

	if err := s.repo.DeleteRating(ctx, id, userID); err != nil {
		return fmt.Errorf("cocktail.DeleteRating: %w", err)
	}
	return nil
}

func isUUID(v string) bool {
	return uuidPattern.MatchString(strings.TrimSpace(v))
}

func validate(input CreateInput) error {
	if !isUUID(strings.TrimSpace(input.CocktailID)) {
		return fmt.Errorf("%w: cocktail_id must be a valid uuid", ErrValidation)
	}

	name := strings.TrimSpace(input.Name)
	if name == "" {
		return fmt.Errorf("%w: name is required", ErrValidation)
	}
	if len([]rune(name)) > 100 {
		return fmt.Errorf("%w: name must be 100 characters or fewer", ErrValidation)
	}

	if input.Memo != nil && len([]rune(*input.Memo)) > 1000 {
		return fmt.Errorf("%w: memo must be 1000 characters or fewer", ErrValidation)
	}

	if !validStatuses[input.Status] {
		return fmt.Errorf("%w: status must be 'draft' or 'published'", ErrValidation)
	}

	if len(input.Ingredients) == 0 {
		return fmt.Errorf("%w: at least one ingredient is required", ErrValidation)
	}

	for i, ing := range input.Ingredients {
		ingName := strings.TrimSpace(ing.Name)
		if ingName == "" {
			return fmt.Errorf("%w: ingredient[%d] name is required", ErrValidation, i)
		}
		if len([]rune(ingName)) > 100 {
			return fmt.Errorf("%w: ingredient[%d] name must be 100 characters or fewer", ErrValidation, i)
		}
		if ing.Unit != nil && !validUnits[*ing.Unit] {
			return fmt.Errorf("%w: ingredient[%d] has invalid unit", ErrValidation, i)
		}
		if ing.Amount != nil && *ing.Amount <= 0 {
			return fmt.Errorf("%w: ingredient[%d] amount must be positive", ErrValidation, i)
		}
	}

	return nil
}
