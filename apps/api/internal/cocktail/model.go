package cocktail

import (
	"errors"
	"time"
)

var (
	ErrNotFound         = errors.New("cocktail recipe not found")
	ErrCocktailNotFound = errors.New("cocktail not found")
	ErrValidation       = errors.New("validation error")
	ErrInvalidRating    = errors.New("rating must be between 1 and 5")
	ErrRatingNotFound   = errors.New("rating not found")
	ErrForbidden        = errors.New("not allowed to modify this rating")
)

// Cocktail is a master record for a cocktail genre (e.g. レモンサワー, マンハッタン).
// User-created recipes (cocktail_recipes) belong to exactly one Cocktail.
type Cocktail struct {
	ID            string    `json:"id"`
	Slug          string    `json:"slug"`
	Name          string    `json:"name"`
	NameEn        *string   `json:"name_en,omitempty"`
	Description   string    `json:"description"`
	ImageURL      *string   `json:"image_url,omitempty"`
	BaseSpirit    *string   `json:"base_spirit,omitempty"`
	ABV           *float64  `json:"abv,omitempty"`
	OriginCountry *string   `json:"origin_country,omitempty"`
	RecipeCount   int       `json:"recipe_count"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// RecipeSummary is a lightweight recipe representation used in list views.
// Rating aggregates are computed from cocktail_recipe_ratings in SQL.
type RecipeSummary struct {
	ID            string    `json:"id"`
	CocktailID    string    `json:"cocktail_id"`
	UserID        string    `json:"user_id"`
	Name          string    `json:"name"`
	Memo          *string   `json:"memo,omitempty"`
	ImageURL      *string   `json:"image_url,omitempty"`
	Status        string    `json:"status"`
	AverageRating float64   `json:"average_rating"`
	TotalRatings  int       `json:"total_ratings"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// CocktailDetail bundles a master record with its published recipes so the
// detail page can be rendered from a single API call.
type CocktailDetail struct {
	Cocktail
	Recipes []RecipeSummary `json:"recipes"`
}

type Ingredient struct {
	ID        string    `json:"id"`
	RecipeID  string    `json:"recipe_id"`
	Name      string    `json:"name"`
	Amount    *float64  `json:"amount,omitempty"`
	Unit      *string   `json:"unit,omitempty"`
	SortOrder int       `json:"sort_order"`
	CreatedAt time.Time `json:"created_at"`
}

type Recipe struct {
	ID            string       `json:"id"`
	CocktailID    string       `json:"cocktail_id"`
	UserID        string       `json:"user_id"`
	Name          string       `json:"name"`
	Memo          *string      `json:"memo,omitempty"`
	ImageURL      *string      `json:"image_url,omitempty"`
	Status        string       `json:"status"`
	AverageRating float64      `json:"average_rating"`
	TotalRatings  int          `json:"total_ratings"`
	Ingredients   []Ingredient `json:"ingredients"`
	CreatedAt     time.Time    `json:"created_at"`
	UpdatedAt     time.Time    `json:"updated_at"`
}

type IngredientInput struct {
	Name      string   `json:"name"`
	Amount    *float64 `json:"amount,omitempty"`
	Unit      *string  `json:"unit,omitempty"`
	SortOrder int      `json:"sort_order"`
}

type CreateInput struct {
	UserID      string            `json:"user_id"`
	CocktailID  string            `json:"cocktail_id"`
	Name        string            `json:"name"`
	Memo        *string           `json:"memo,omitempty"`
	ImageURL    *string           `json:"image_url,omitempty"`
	Status      string            `json:"status"`
	Ingredients []IngredientInput `json:"ingredients"`
}

// RecipeRating is a user's star rating and optional comment for a recipe.
type RecipeRating struct {
	ID        string    `json:"id"`
	RecipeID  string    `json:"recipe_id"`
	UserID    string    `json:"user_id"`
	Rating    int       `json:"rating"`
	Comment   string    `json:"comment"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// RatingUpsertInput is used for both create and update; the repository
// performs INSERT ON CONFLICT UPDATE keyed on (recipe_id, user_id).
type RatingUpsertInput struct {
	RecipeID string `json:"recipe_id"`
	Rating   int    `json:"rating"`
	Comment  string `json:"comment"`
}
