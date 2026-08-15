package admin

import (
	"context"
	"database/sql"
	"errors"
)

type Repository interface {
	AppRole(ctx context.Context, userID string) (string, error)
	Overview(ctx context.Context) (*Overview, error)
	ListSearchMisses(ctx context.Context, p SearchMissListParams) ([]SearchMissRow, int, error)
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

func (r *repository) ListSearchMisses(ctx context.Context, p SearchMissListParams) ([]SearchMissRow, int, error) {
	var scope any
	if p.Scope != "" {
		scope = p.Scope
	}

	const countQ = `
SELECT COUNT(*)::int FROM (
  SELECT 1
  FROM search_misses sm
  WHERE sm.result_count = 0
    AND ($1::text IS NULL OR sm.scope = $1)
  GROUP BY sm.scope, sm.query_normalized
) grouped`

	var total int
	if err := r.db.QueryRowContext(ctx, countQ, scope).Scan(&total); err != nil {
		return nil, 0, err
	}

	// export-demand.ts と同じ集計（sample_query_raw / unique_searchers）に
	// scope 列を足す。view は元クエリを持たないので SELECT しない。
	const listQ = `
SELECT
  sm.scope,
  sm.query_normalized,
  (ARRAY_AGG(sm.query_raw ORDER BY sm.created_at DESC))[1] AS sample_query_raw,
  COUNT(*)::int AS miss_count,
  COUNT(DISTINCT COALESCE(sm.user_id::text, sm.client_hash))::int AS unique_searchers,
  MAX(sm.created_at) AS last_seen_at
FROM search_misses sm
WHERE sm.result_count = 0
  AND ($1::text IS NULL OR sm.scope = $1)
GROUP BY sm.scope, sm.query_normalized
ORDER BY miss_count DESC, unique_searchers DESC
LIMIT $2 OFFSET $3`

	rows, err := r.db.QueryContext(ctx, listQ, scope, p.Limit, p.Offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	out := make([]SearchMissRow, 0)
	for rows.Next() {
		var row SearchMissRow
		if err := rows.Scan(
			&row.Scope,
			&row.QueryNormalized,
			&row.SampleQueryRaw,
			&row.MissCount,
			&row.UniqueSearchers,
			&row.LastSeenAt,
		); err != nil {
			return nil, 0, err
		}
		out = append(out, row)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}
	return out, total, nil
}
