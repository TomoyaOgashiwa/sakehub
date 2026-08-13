package saveddrink

import (
	"context"
	"database/sql"
	"errors"
)

type Repository interface {
	DrinkExists(ctx context.Context, drinkID string) (bool, error)
	Upsert(ctx context.Context, userID, drinkID, status string) (*SavedDrink, error)
	Update(ctx context.Context, drinkID, userID string, status, note *string) (*SavedDrink, error)
	FindByDrinkAndUser(ctx context.Context, drinkID, userID string) (*SavedDrink, error)
	ListByUser(ctx context.Context, userID string, params ListParams) ([]SavedDrink, error)
	DeleteByDrinkAndUser(ctx context.Context, drinkID, userID string) error
}

type repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &repository{db: db}
}

func (r *repository) DrinkExists(ctx context.Context, drinkID string) (bool, error) {
	const q = `SELECT EXISTS(SELECT 1 FROM drinks WHERE id = $1)`
	var exists bool
	if err := r.db.QueryRowContext(ctx, q, drinkID).Scan(&exists); err != nil {
		return false, err
	}
	return exists, nil
}

func (r *repository) Upsert(ctx context.Context, userID, drinkID, status string) (*SavedDrink, error) {
	const q = `
		INSERT INTO saved_drinks (user_id, drink_id, status)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id, drink_id)
		DO UPDATE SET status = EXCLUDED.status
		RETURNING id, user_id, drink_id, status, note, created_at`

	var row SavedDrink
	if err := r.db.QueryRowContext(ctx, q, userID, drinkID, status).Scan(
		&row.ID, &row.UserID, &row.DrinkID, &row.Status, &row.Note, &row.CreatedAt,
	); err != nil {
		return nil, err
	}
	return &row, nil
}

func (r *repository) Update(ctx context.Context, drinkID, userID string, status, note *string) (*SavedDrink, error) {
	const q = `
		UPDATE saved_drinks
		SET
			status = COALESCE($3, status),
			note = COALESCE($4, note)
		WHERE drink_id = $1 AND user_id = $2
		RETURNING id, user_id, drink_id, status, note, created_at`

	var row SavedDrink
	err := r.db.QueryRowContext(ctx, q, drinkID, userID, status, note).Scan(
		&row.ID, &row.UserID, &row.DrinkID, &row.Status, &row.Note, &row.CreatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &row, nil
}

func (r *repository) FindByDrinkAndUser(ctx context.Context, drinkID, userID string) (*SavedDrink, error) {
	const q = `
		SELECT id, user_id, drink_id, status, note, created_at
		FROM saved_drinks
		WHERE drink_id = $1 AND user_id = $2`

	var row SavedDrink
	err := r.db.QueryRowContext(ctx, q, drinkID, userID).Scan(
		&row.ID, &row.UserID, &row.DrinkID, &row.Status, &row.Note, &row.CreatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &row, nil
}

func (r *repository) ListByUser(ctx context.Context, userID string, params ListParams) ([]SavedDrink, error) {
	const q = `
		SELECT
			s.id, s.user_id, s.drink_id, s.status, s.note, s.created_at,
			d.id, d.slug, d.name, d.name_en, d.category, d.image_url,
			r.rating, r.comment
		FROM saved_drinks s
		INNER JOIN drinks d ON d.id = s.drink_id
		LEFT JOIN ratings r ON r.drink_id = s.drink_id AND r.user_id = s.user_id
		WHERE s.user_id = $1
		ORDER BY s.created_at DESC
		LIMIT $2 OFFSET $3`

	rows, err := r.db.QueryContext(ctx, q, userID, params.Limit, params.Offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []SavedDrink
	for rows.Next() {
		item, err := scanListed(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if items == nil {
		items = []SavedDrink{}
	}
	return items, rows.Err()
}

func (r *repository) DeleteByDrinkAndUser(ctx context.Context, drinkID, userID string) error {
	const q = `DELETE FROM saved_drinks WHERE drink_id = $1 AND user_id = $2`
	_, err := r.db.ExecContext(ctx, q, drinkID, userID)
	return err
}

func scanListed(rows *sql.Rows) (SavedDrink, error) {
	var (
		item     SavedDrink
		drink    DrinkSummary
		nameEn   sql.NullString
		imageURL sql.NullString
		rating   sql.NullInt64
		comment  sql.NullString
	)
	err := rows.Scan(
		&item.ID, &item.UserID, &item.DrinkID, &item.Status, &item.Note, &item.CreatedAt,
		&drink.ID, &drink.Slug, &drink.Name, &nameEn, &drink.Category, &imageURL,
		&rating, &comment,
	)
	if err != nil {
		return SavedDrink{}, err
	}
	if nameEn.Valid {
		drink.NameEn = &nameEn.String
	}
	if imageURL.Valid {
		drink.ImageURL = &imageURL.String
	}
	item.Drink = &drink
	if rating.Valid {
		v := int(rating.Int64)
		item.Rating = &v
	}
	if comment.Valid {
		item.Comment = &comment.String
	}
	return item, nil
}
