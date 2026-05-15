package drink

import (
	"context"
	"database/sql"
	"errors"
)

var ErrNotFound = errors.New("drink not found")

type Repository interface {
	FindByID(ctx context.Context, id string) (*Drink, error)
	Insert(ctx context.Context, d *Drink) error
}

type repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindByID(ctx context.Context, id string) (*Drink, error) {
	const q = `SELECT id, name, category, abv, created_at, updated_at FROM drinks WHERE id = $1`

	var d Drink
	err := r.db.QueryRowContext(ctx, q, id).Scan(
		&d.ID, &d.Name, &d.Category, &d.ABV, &d.CreatedAt, &d.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &d, nil
}

func (r *repository) Insert(ctx context.Context, d *Drink) error {
	const q = `INSERT INTO drinks (name, category, abv) VALUES ($1, $2, $3) RETURNING id, created_at, updated_at`

	return r.db.QueryRowContext(ctx, q, d.Name, d.Category, d.ABV).Scan(
		&d.ID, &d.CreatedAt, &d.UpdatedAt,
	)
}
