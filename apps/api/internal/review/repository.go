package review

import (
	"context"
	"database/sql"
	"errors"
)

var ErrNotFound = errors.New("review not found")
var ErrForbidden = errors.New("not allowed to modify this review")

type Repository interface {
	FindByDrinkAndUser(ctx context.Context, drinkID, userID string) (*Review, error)
	ListByDrink(ctx context.Context, drinkID string) ([]Review, error)
	Upsert(ctx context.Context, r *Review) error
	Delete(ctx context.Context, id, userID string) error
}

type repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindByDrinkAndUser(ctx context.Context, drinkID, userID string) (*Review, error) {
	const q = `
		SELECT id, drink_id, user_id, rating, comment, created_at, updated_at
		FROM ratings
		WHERE drink_id = $1 AND user_id = $2`

	var rev Review
	err := r.db.QueryRowContext(ctx, q, drinkID, userID).Scan(
		&rev.ID, &rev.DrinkID, &rev.UserID, &rev.Rating, &rev.Comment,
		&rev.CreatedAt, &rev.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &rev, nil
}

func (r *repository) ListByDrink(ctx context.Context, drinkID string) ([]Review, error) {
	const q = `
		SELECT id, drink_id, user_id, rating, comment, created_at, updated_at
		FROM ratings
		WHERE drink_id = $1
		ORDER BY created_at DESC`

	rows, err := r.db.QueryContext(ctx, q, drinkID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var reviews []Review
	for rows.Next() {
		var rev Review
		if err := rows.Scan(
			&rev.ID, &rev.DrinkID, &rev.UserID, &rev.Rating, &rev.Comment,
			&rev.CreatedAt, &rev.UpdatedAt,
		); err != nil {
			return nil, err
		}
		reviews = append(reviews, rev)
	}
	return reviews, rows.Err()
}

// Upsert inserts a new rating or updates the rating/comment when the
// (drink_id, user_id) pair already exists.
func (r *repository) Upsert(ctx context.Context, rev *Review) error {
	const q = `
		INSERT INTO ratings (drink_id, user_id, rating, comment)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (drink_id, user_id)
		DO UPDATE SET rating = EXCLUDED.rating, comment = EXCLUDED.comment, updated_at = now()
		RETURNING id, created_at, updated_at`

	return r.db.QueryRowContext(ctx, q,
		rev.DrinkID, rev.UserID, rev.Rating, rev.Comment,
	).Scan(&rev.ID, &rev.CreatedAt, &rev.UpdatedAt)
}

// Delete removes the rating only if it belongs to userID.
func (r *repository) Delete(ctx context.Context, id, userID string) error {
	const q = `DELETE FROM ratings WHERE id = $1 AND user_id = $2`

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
