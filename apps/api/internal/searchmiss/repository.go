package searchmiss

import (
	"context"
	"database/sql"
)

type Repository interface {
	Insert(ctx context.Context, miss *Miss) error
}

type repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Insert(ctx context.Context, miss *Miss) error {
	const q = `
		INSERT INTO search_misses (scope, query_raw, query_normalized, result_count, user_id, client_hash)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at`

	return r.db.QueryRowContext(ctx, q,
		miss.Scope, miss.QueryRaw, miss.QueryNormalized, miss.ResultCount, miss.UserID, miss.ClientHash,
	).Scan(&miss.ID, &miss.CreatedAt)
}
