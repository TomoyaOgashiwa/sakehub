package cocktail

import (
	"errors"
	"fmt"
	"time"
)

var (
	ErrNotFound         = errors.New("cocktail recipe not found")
	ErrCocktailNotFound = errors.New("cocktail not found")
	ErrValidation       = errors.New("validation error")
	ErrInvalidRating    = errors.New("rating must be between 1 and 5")
	ErrInvalidUUID      = errors.New("invalid uuid")
	ErrRatingNotFound   = errors.New("rating not found")
	ErrForbidden        = errors.New("not allowed to modify this rating")
)

// Default list caps keep detail payloads bounded as recipes/ratings grow.
const (
	DefaultPublishedRecipeLimit = 50
	DefaultMineRecipeLimit      = 50
	DefaultRatingListLimit      = 20
	DefaultCocktailListLimit    = 100
	MaxPublishedRecipeLimit     = 100
	MaxMineRecipeLimit          = 100
	MaxRatingListLimit          = 50
	MaxCocktailListLimit        = 200

	// WITHDRAWN_AUTHOR_LABEL is shown when a published recipe's author has left.
	// Keep in sync with apps/web/src/utils/withdrawn-author.ts.
	WITHDRAWN_AUTHOR_LABEL = "退会したユーザー"
)

// ListParams filters and paginates the cocktails master list.
// Default sort: recipe_count DESC, then name ASC.
type ListParams struct {
	Query      string
	BaseSpirit string
	Limit      int
	Offset     int
}

// ValidationError carries a client-safe detail without service wrap prefixes.
type ValidationError struct {
	Detail string
}

func (e *ValidationError) Error() string {
	if e == nil || e.Detail == "" {
		return ErrValidation.Error()
	}
	return ErrValidation.Error() + ": " + e.Detail
}

func (e *ValidationError) Unwrap() error {
	return ErrValidation
}

func validationErrorf(format string, args ...any) error {
	return &ValidationError{Detail: fmt.Sprintf(format, args...)}
}

// Cocktail is a master record for a cocktail genre (e.g. レモンサワー, マンハッタン).
// User-created recipes (cocktail_recipes) belong to exactly one Cocktail.
type Cocktail struct {
	ID            string    `json:"id"`
	Slug          string    `json:"slug"`
	Name          string    `json:"name"`
	NameEn        *string   `json:"name_en,omitempty"`
	Description   string    `json:"description"`
	ImageURL      *string   `json:"image_url,omitempty"`
	ImageSource   string    `json:"image_source"`
	BaseSpirit    *string   `json:"base_spirit,omitempty"`
	ABV           *float64  `json:"abv,omitempty"`
	OriginCountry *string   `json:"origin_country,omitempty"`
	RecipeCount   int       `json:"recipe_count"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// MyRecipeSummary is the authenticated owner's draft + published list item.
// Official recipes are excluded; rating aggregates are omitted on purpose.
type MyRecipeSummary struct {
	ID           string    `json:"id"`
	Name         string    `json:"name"`
	Status       string    `json:"status"`
	ImageURL     *string   `json:"image_url,omitempty"`
	UpdatedAt    time.Time `json:"updated_at"`
	CocktailID   string    `json:"cocktail_id"`
	CocktailSlug string    `json:"cocktail_slug"`
	CocktailName string    `json:"cocktail_name"`
}

// RecipeSummary is a lightweight recipe representation used in list views.
// Rating aggregates are computed from cocktail_recipe_ratings in SQL.
type RecipeSummary struct {
	ID            string    `json:"id"`
	CocktailID    string    `json:"cocktail_id"`
	UserID        *string   `json:"user_id"`
	AuthorName    *string   `json:"author_name,omitempty"`
	Name          string    `json:"name"`
	Memo          *string   `json:"memo,omitempty"`
	ImageURL      *string   `json:"image_url,omitempty"`
	Status        string    `json:"status"`
	IsOfficial    bool      `json:"is_official"`
	AverageRating float64   `json:"average_rating"`
	TotalRatings  int       `json:"total_ratings"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// CocktailDetail bundles a master record with its published recipes so the
// detail page can be rendered from a single API call.
type CocktailDetail struct {
	Cocktail
	OfficialRecipe *Recipe         `json:"official_recipe,omitempty"`
	Recipes        []RecipeSummary `json:"recipes"`
	HasMoreRecipes bool            `json:"has_more_recipes"`
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

type Step struct {
	ID        string    `json:"id"`
	RecipeID  string    `json:"recipe_id"`
	Body      string    `json:"body"`
	SortOrder int       `json:"sort_order"`
	CreatedAt time.Time `json:"created_at"`
}

type Recipe struct {
	ID            string       `json:"id"`
	CocktailID    string       `json:"cocktail_id"`
	CocktailSlug  string       `json:"cocktail_slug,omitempty"`
	UserID        *string      `json:"user_id"`
	AuthorName    *string      `json:"author_name,omitempty"`
	Name          string       `json:"name"`
	Memo          *string      `json:"memo,omitempty"`
	ImageURL      *string      `json:"image_url,omitempty"`
	Status        string       `json:"status"`
	IsOfficial    bool         `json:"is_official"`
	AverageRating float64      `json:"average_rating"`
	TotalRatings  int          `json:"total_ratings"`
	Ingredients   []Ingredient `json:"ingredients"`
	Steps         []Step       `json:"steps"`
	CreatedAt     time.Time    `json:"created_at"`
	UpdatedAt     time.Time    `json:"updated_at"`
}

type IngredientInput struct {
	Name      string   `json:"name"`
	Amount    *float64 `json:"amount,omitempty"`
	Unit      *string  `json:"unit,omitempty"`
	SortOrder int      `json:"sort_order"`
}

type StepInput struct {
	Body      string `json:"body"`
	SortOrder int    `json:"sort_order"`
}

// CreateInput is the user-facing create payload. is_official is intentionally
// omitted so posts always get DEFAULT false; official recipes are seed-only.
type CreateInput struct {
	UserID      string            `json:"user_id"`
	CocktailID  string            `json:"cocktail_id"`
	Name        string            `json:"name"`
	Memo        *string           `json:"memo,omitempty"`
	ImageURL    *string           `json:"image_url,omitempty"`
	Status      string            `json:"status"`
	Ingredients []IngredientInput `json:"ingredients"`
	Steps       []StepInput       `json:"steps"`
}

// DraftUpdateInput is the full-replace payload for a draft PATCH.
// image_url / memo omit-vs-null is resolved in the service before this is built.
type DraftUpdateInput struct {
	CocktailID  string
	Name        string
	Memo        *string
	ImageURL    *string
	Status      string
	Ingredients []IngredientInput
	Steps       []StepInput
}

func (in DraftUpdateInput) asCreateInput() CreateInput {
	return CreateInput{
		CocktailID:  in.CocktailID,
		Name:        in.Name,
		Memo:        in.Memo,
		ImageURL:    in.ImageURL,
		Status:      in.Status,
		Ingredients: in.Ingredients,
		Steps:       in.Steps,
	}
}

const (
	msgPublishedCannotUpdate = "published recipes cannot be updated"
	msgPublishedCannotDelete = "published recipes cannot be deleted"
	msgIsOfficialForbidden   = "is_official cannot be set"
)

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

// RatingListResult is a bounded page of ratings with a has-more flag.
type RatingListResult struct {
	Data    []RecipeRating `json:"data"`
	HasMore bool           `json:"has_more"`
}
