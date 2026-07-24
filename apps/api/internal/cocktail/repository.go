package cocktail

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/lib/pq"
)

// cocktailColumns is the shared SELECT column list for the cocktails master.
// recipe_count only counts published recipes so the listing reflects what a
// visitor can actually open.
const cocktailColumns = `c.id, c.slug, c.name, c.name_en, c.description, c.image_url,
	c.base_spirit, c.abv, c.origin_country,
	COALESCE(rc.cnt, 0)::INTEGER AS recipe_count,
	c.created_at, c.updated_at`

const cocktailRecipeCountJoin = `LEFT JOIN LATERAL (
	SELECT COUNT(*) AS cnt
	FROM cocktail_recipes r
	WHERE r.cocktail_id = c.id AND r.status = 'published'
) rc ON true`

// recipeAggregates computes rating aggregates per recipe in SQL to avoid N+1
// round-trips; covered by idx_cocktail_recipe_ratings_recipe_id.
const recipeAggregates = `COALESCE((SELECT AVG(rt.rating)::NUMERIC(3,2) FROM cocktail_recipe_ratings rt WHERE rt.recipe_id = r.id), 0) AS average_rating,
	COALESCE((SELECT COUNT(*) FROM cocktail_recipe_ratings rt WHERE rt.recipe_id = r.id), 0)::INTEGER AS total_ratings`

type Repository interface {
	ListCocktails(ctx context.Context) ([]Cocktail, error)
	FindCocktailBySlug(ctx context.Context, slug string) (*Cocktail, error)
	ListPublishedRecipes(ctx context.Context, cocktailID string, limit, offset int) ([]RecipeSummary, bool, error)
	FindPublishedRecipeByID(ctx context.Context, id string) (*Recipe, error)
	PublishedRecipeExists(ctx context.Context, id string) error
	Insert(ctx context.Context, input CreateInput) (*Recipe, error)

	FindRatingByRecipeAndUser(ctx context.Context, recipeID, userID string) (*RecipeRating, error)
	ListRatingsByRecipe(ctx context.Context, recipeID string, limit, offset int) ([]RecipeRating, bool, error)
	UpsertRating(ctx context.Context, rating *RecipeRating) error
	DeleteRating(ctx context.Context, id, userID string) error
}

type repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &repository{db: db}
}

func (r *repository) scanCocktail(row interface{ Scan(dest ...any) error }) (*Cocktail, error) {
	var c Cocktail
	err := row.Scan(
		&c.ID, &c.Slug, &c.Name, &c.NameEn, &c.Description, &c.ImageURL,
		&c.BaseSpirit, &c.ABV, &c.OriginCountry, &c.RecipeCount,
		&c.CreatedAt, &c.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

func (r *repository) ListCocktails(ctx context.Context) ([]Cocktail, error) {
	q := fmt.Sprintf(`SELECT %s FROM cocktails c %s ORDER BY c.name`,
		cocktailColumns, cocktailRecipeCountJoin)

	rows, err := r.db.QueryContext(ctx, q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cocktails []Cocktail
	for rows.Next() {
		c, err := r.scanCocktail(rows)
		if err != nil {
			return nil, err
		}
		cocktails = append(cocktails, *c)
	}
	return cocktails, rows.Err()
}

func (r *repository) FindCocktailBySlug(ctx context.Context, slug string) (*Cocktail, error) {
	q := fmt.Sprintf(`SELECT %s FROM cocktails c %s WHERE c.slug = $1`,
		cocktailColumns, cocktailRecipeCountJoin)

	c, err := r.scanCocktail(r.db.QueryRowContext(ctx, q, slug))
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrCocktailNotFound
	}
	if err != nil {
		return nil, err
	}
	return c, nil
}

func (r *repository) ListPublishedRecipes(ctx context.Context, cocktailID string, limit, offset int) ([]RecipeSummary, bool, error) {
	if limit <= 0 {
		limit = DefaultPublishedRecipeLimit
	}
	if offset < 0 {
		offset = 0
	}

	// Fetch one extra row to detect whether another page exists.
	q := fmt.Sprintf(`
		SELECT r.id, r.cocktail_id, r.user_id, r.name, r.memo, r.image_url, r.status,
			%s, r.created_at, r.updated_at
		FROM cocktail_recipes r
		WHERE r.cocktail_id = $1 AND r.status = 'published'
		ORDER BY r.created_at DESC
		LIMIT $2 OFFSET $3`, recipeAggregates)

	rows, err := r.db.QueryContext(ctx, q, cocktailID, limit+1, offset)
	if err != nil {
		return nil, false, err
	}
	defer rows.Close()

	recipes := make([]RecipeSummary, 0, limit)
	for rows.Next() {
		var rec RecipeSummary
		if err := rows.Scan(
			&rec.ID, &rec.CocktailID, &rec.UserID, &rec.Name, &rec.Memo, &rec.ImageURL,
			&rec.Status, &rec.AverageRating, &rec.TotalRatings,
			&rec.CreatedAt, &rec.UpdatedAt,
		); err != nil {
			return nil, false, err
		}
		recipes = append(recipes, rec)
	}
	if err := rows.Err(); err != nil {
		return nil, false, err
	}

	hasMore := len(recipes) > limit
	if hasMore {
		recipes = recipes[:limit]
	}
	return recipes, hasMore, nil
}

// FindPublishedRecipeByID returns a published recipe with its ingredients and
// rating aggregates. Drafts are treated as not found because this feeds a
// public endpoint. cocktail_slug is joined so callers can validate canonical URLs
// without a second master+recipes fetch.
func (r *repository) FindPublishedRecipeByID(ctx context.Context, id string) (*Recipe, error) {
	recipeQ := fmt.Sprintf(`
		SELECT r.id, r.cocktail_id, c.slug, r.user_id, r.name, r.memo, r.image_url, r.status,
			%s, r.created_at, r.updated_at
		FROM cocktail_recipes r
		INNER JOIN cocktails c ON c.id = r.cocktail_id
		WHERE r.id = $1 AND r.status = 'published'`, recipeAggregates)

	var rec Recipe
	err := r.db.QueryRowContext(ctx, recipeQ, id).Scan(
		&rec.ID, &rec.CocktailID, &rec.CocktailSlug, &rec.UserID, &rec.Name, &rec.Memo, &rec.ImageURL,
		&rec.Status, &rec.AverageRating, &rec.TotalRatings,
		&rec.CreatedAt, &rec.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}

	const ingQ = `
		SELECT id, recipe_id, name, amount, unit, sort_order, created_at
		FROM cocktail_recipe_ingredients
		WHERE recipe_id = $1
		ORDER BY sort_order`

	rows, err := r.db.QueryContext(ctx, ingQ, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	rec.Ingredients = make([]Ingredient, 0)
	for rows.Next() {
		var ing Ingredient
		if err := rows.Scan(
			&ing.ID, &ing.RecipeID, &ing.Name, &ing.Amount, &ing.Unit,
			&ing.SortOrder, &ing.CreatedAt,
		); err != nil {
			return nil, err
		}
		rec.Ingredients = append(rec.Ingredients, ing)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return &rec, nil
}

// PublishedRecipeExists returns ErrNotFound when the id is missing or not published.
func (r *repository) PublishedRecipeExists(ctx context.Context, id string) error {
	const q = `SELECT 1 FROM cocktail_recipes WHERE id = $1 AND status = 'published'`

	var one int
	err := r.db.QueryRowContext(ctx, q, id).Scan(&one)
	if errors.Is(err, sql.ErrNoRows) {
		return ErrNotFound
	}
	return err
}

func (r *repository) Insert(ctx context.Context, input CreateInput) (*Recipe, error) {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("cocktail.Insert begin tx: %w", err)
	}
	defer tx.Rollback() //nolint:errcheck

	const recipeQ = `
		INSERT INTO cocktail_recipes (user_id, cocktail_id, name, memo, image_url, status)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at, updated_at`

	recipe := &Recipe{
		UserID:     input.UserID,
		CocktailID: input.CocktailID,
		Name:       input.Name,
		Memo:       input.Memo,
		ImageURL:   input.ImageURL,
		Status:     input.Status,
	}

	err = tx.QueryRowContext(ctx, recipeQ,
		input.UserID, input.CocktailID, input.Name, input.Memo, input.ImageURL, input.Status,
	).Scan(&recipe.ID, &recipe.CreatedAt, &recipe.UpdatedAt)
	if err != nil {
		var pqErr *pq.Error
		// 23503 = foreign_key_violation: the referenced cocktail does not exist.
		if errors.As(err, &pqErr) && pqErr.Code == "23503" {
			return nil, validationErrorf("cocktail_id does not exist")
		}
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

func (r *repository) FindRatingByRecipeAndUser(ctx context.Context, recipeID, userID string) (*RecipeRating, error) {
	const q = `
		SELECT id, recipe_id, user_id, rating, comment, created_at, updated_at
		FROM cocktail_recipe_ratings
		WHERE recipe_id = $1 AND user_id = $2`

	var rating RecipeRating
	err := r.db.QueryRowContext(ctx, q, recipeID, userID).Scan(
		&rating.ID, &rating.RecipeID, &rating.UserID, &rating.Rating, &rating.Comment,
		&rating.CreatedAt, &rating.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrRatingNotFound
	}
	if err != nil {
		return nil, err
	}
	return &rating, nil
}

func (r *repository) ListRatingsByRecipe(ctx context.Context, recipeID string, limit, offset int) ([]RecipeRating, bool, error) {
	if limit <= 0 {
		limit = DefaultRatingListLimit
	}
	if offset < 0 {
		offset = 0
	}

	const q = `
		SELECT id, recipe_id, user_id, rating, comment, created_at, updated_at
		FROM cocktail_recipe_ratings
		WHERE recipe_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3`

	rows, err := r.db.QueryContext(ctx, q, recipeID, limit+1, offset)
	if err != nil {
		return nil, false, err
	}
	defer rows.Close()

	ratings := make([]RecipeRating, 0, limit)
	for rows.Next() {
		var rating RecipeRating
		if err := rows.Scan(
			&rating.ID, &rating.RecipeID, &rating.UserID, &rating.Rating, &rating.Comment,
			&rating.CreatedAt, &rating.UpdatedAt,
		); err != nil {
			return nil, false, err
		}
		ratings = append(ratings, rating)
	}
	if err := rows.Err(); err != nil {
		return nil, false, err
	}

	hasMore := len(ratings) > limit
	if hasMore {
		ratings = ratings[:limit]
	}
	return ratings, hasMore, nil
}

// UpsertRating inserts or updates a rating only when the recipe is published.
// The published check is in the same statement to avoid TOCTOU races (Go bypasses RLS).
func (r *repository) UpsertRating(ctx context.Context, rating *RecipeRating) error {
	const q = `
		INSERT INTO cocktail_recipe_ratings (recipe_id, user_id, rating, comment)
		SELECT $1, $2, $3, $4
		FROM cocktail_recipes r
		WHERE r.id = $1 AND r.status = 'published'
		ON CONFLICT (recipe_id, user_id)
		DO UPDATE SET rating = EXCLUDED.rating, comment = EXCLUDED.comment, updated_at = now()
		RETURNING id, created_at, updated_at`

	err := r.db.QueryRowContext(ctx, q,
		rating.RecipeID, rating.UserID, rating.Rating, rating.Comment,
	).Scan(&rating.ID, &rating.CreatedAt, &rating.UpdatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return ErrNotFound
	}
	if err != nil {
		var pqErr *pq.Error
		if errors.As(err, &pqErr) && pqErr.Code == "23503" {
			return validationErrorf("recipe_id does not exist")
		}
		return err
	}
	return nil
}

// DeleteRating removes the rating only if it belongs to userID.
func (r *repository) DeleteRating(ctx context.Context, id, userID string) error {
	const q = `DELETE FROM cocktail_recipe_ratings WHERE id = $1 AND user_id = $2`

	result, err := r.db.ExecContext(ctx, q, id, userID)
	if err != nil {
		return err
	}
	n, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		// Row does not exist or belongs to another user.
		return ErrForbidden
	}
	return nil
}
