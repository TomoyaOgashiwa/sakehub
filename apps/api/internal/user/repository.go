package user

import (
	"context"
	"database/sql"
	"errors"
)

var ErrNotFound = errors.New("user not found")

type Repository interface {
	FindByID(ctx context.Context, id string) (*User, error)
}

type repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindByID(ctx context.Context, id string) (*User, error) {
	const q = `SELECT id, email, display_name, avatar_url, login_type, created_at, updated_at FROM users WHERE id = $1`

	var u User
	err := r.db.QueryRowContext(ctx, q, id).Scan(
		&u.ID, &u.Email, &u.DisplayName, &u.AvatarURL, &u.LoginType, &u.CreatedAt, &u.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}
