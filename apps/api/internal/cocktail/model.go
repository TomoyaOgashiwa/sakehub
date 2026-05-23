package cocktail

import (
	"errors"
	"time"
)

var (
	ErrNotFound   = errors.New("cocktail recipe not found")
	ErrValidation = errors.New("validation error")
)

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
	ID          string       `json:"id"`
	UserID      string       `json:"user_id"`
	Name        string       `json:"name"`
	Memo        *string      `json:"memo,omitempty"`
	ImageURL    *string      `json:"image_url,omitempty"`
	Status      string       `json:"status"`
	Ingredients []Ingredient `json:"ingredients"`
	CreatedAt   time.Time    `json:"created_at"`
	UpdatedAt   time.Time    `json:"updated_at"`
}

type IngredientInput struct {
	Name      string   `json:"name"`
	Amount    *float64 `json:"amount,omitempty"`
	Unit      *string  `json:"unit,omitempty"`
	SortOrder int      `json:"sort_order"`
}

type CreateInput struct {
	UserID      string            `json:"user_id"`
	Name        string            `json:"name"`
	Memo        *string           `json:"memo,omitempty"`
	ImageURL    *string           `json:"image_url,omitempty"`
	Status      string            `json:"status"`
	Ingredients []IngredientInput `json:"ingredients"`
}
