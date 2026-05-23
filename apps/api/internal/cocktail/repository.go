package cocktail

import (
	"context"
	"database/sql"
	"fmt"
)

type Repository interface {
	Insert(ctx context.Context, input CreateInput) (*Recipe, error)
}

type repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Insert(ctx context.Context, input CreateInput) (*Recipe, error) {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("cocktail.Insert begin tx: %w", err)
	}
	defer tx.Rollback() //nolint:errcheck

	const recipeQ = `
		INSERT INTO cocktail_recipes (user_id, name, memo, image_url, status)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at`

	recipe := &Recipe{
		UserID:   input.UserID,
		Name:     input.Name,
		Memo:     input.Memo,
		ImageURL: input.ImageURL,
		Status:   input.Status,
	}

	err = tx.QueryRowContext(ctx, recipeQ,
		input.UserID, input.Name, input.Memo, input.ImageURL, input.Status,
	).Scan(&recipe.ID, &recipe.CreatedAt, &recipe.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("cocktail.Insert recipe: %w", err)
	}

	recipe.Ingredients = make([]Ingredient, 0, len(input.Ingredients))
	for _, ing := range input.Ingredients {
		const ingQ = `
			INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order)
			VALUES ($1, $2, $3, $4, $5)
			RETURNING id, created_at`

		var inserted Ingredient
		inserted.RecipeID = recipe.ID
		inserted.Name = ing.Name
		inserted.Amount = ing.Amount
		inserted.Unit = ing.Unit
		inserted.SortOrder = ing.SortOrder

		err = tx.QueryRowContext(ctx, ingQ,
			recipe.ID, ing.Name, ing.Amount, ing.Unit, ing.SortOrder,
		).Scan(&inserted.ID, &inserted.CreatedAt)
		if err != nil {
			return nil, fmt.Errorf("cocktail.Insert ingredient: %w", err)
		}
		recipe.Ingredients = append(recipe.Ingredients, inserted)
	}

	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("cocktail.Insert commit: %w", err)
	}

	return recipe, nil
}
