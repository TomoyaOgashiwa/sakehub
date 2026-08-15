package admin

import (
	"context"
	"database/sql"
	"errors"
)

type Repository interface {
	AppRole(ctx context.Context, userID string) (string, error)
	Overview(ctx context.Context) (*Overview, error)
}

type repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &repository{db: db}
}

func (r *repository) AppRole(ctx context.Context, userID string) (string, error) {
	const q = `SELECT app_role FROM users WHERE id = $1`

	var role string
	err := r.db.QueryRowContext(ctx, q, userID).Scan(&role)
	if errors.Is(err, sql.ErrNoRows) {
		return "", ErrNotFound
	}
	if err != nil {
		return "", err
	}
	return role, nil
}

func (r *repository) Overview(ctx context.Context) (*Overview, error) {
	const q = `
SELECT
  (SELECT COUNT(*) FROM search_misses
    WHERE scope = 'drink' AND result_count = 0) AS drink_miss_rows,
  (SELECT COUNT(DISTINCT query_normalized) FROM search_misses
    WHERE scope = 'drink' AND result_count = 0) AS drink_miss_queries,
  (SELECT COUNT(*) FROM drinks
    WHERE visibility = 'provisional' AND merged_into_id IS NULL) AS provisional_drinks,
  (SELECT COUNT(*) FROM drinks WHERE visibility = 'published') AS published_drinks`

	var o Overview
	err := r.db.QueryRowContext(ctx, q).Scan(
		&o.DrinkMissRows,
		&o.DrinkMissQueries,
		&o.ProvisionalDrinks,
		&o.PublishedDrinks,
	)
	if err != nil {
		return nil, err
	}
	return &o, nil
}
