package drinklog

import (
	"context"
	"database/sql"
	"errors"
	"time"
	"unicode/utf8"
)

type drinkMeta struct {
	Category string
	ABV      sql.NullFloat64
}

type Repository interface {
	FindDrinkMeta(ctx context.Context, drinkID string) (*drinkMeta, error)
	Insert(ctx context.Context, log *Log) error
	ListByUser(ctx context.Context, userID string, params ListParams) ([]Log, error)
	Delete(ctx context.Context, id, userID string) error
	Summary(ctx context.Context, userID string, from, to time.Time) (logCount, skipped int, pureGrams float64, err error)
	InsertSearchMiss(ctx context.Context, userID, queryRaw string) error
}

type repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindDrinkMeta(ctx context.Context, drinkID string) (*drinkMeta, error) {
	const q = `SELECT category, abv FROM drinks WHERE id = $1`

	var meta drinkMeta
	err := r.db.QueryRowContext(ctx, q, drinkID).Scan(&meta.Category, &meta.ABV)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrDrinkNotFound
	}
	if err != nil {
		return nil, err
	}
	return &meta, nil
}

func (r *repository) Insert(ctx context.Context, log *Log) error {
	const q = `
		INSERT INTO drink_logs (
			user_id, drink_id, custom_drink_name, drank_at, volume_ml, input_unit, input_value,
			serving_key, volume_precision, place_name, place_url
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING id, created_at, updated_at`

	return r.db.QueryRowContext(ctx, q,
		log.UserID, log.DrinkID, log.CustomDrinkName, log.DrankAt, log.VolumeML, log.InputUnit, log.InputValue,
		log.ServingKey, log.VolumePrecision, log.PlaceName, log.PlaceURL,
	).Scan(&log.ID, &log.CreatedAt, &log.UpdatedAt)
}

func (r *repository) ListByUser(ctx context.Context, userID string, params ListParams) ([]Log, error) {
	const q = `
		SELECT
			l.id, l.user_id, l.drink_id, l.custom_drink_name, l.drank_at, l.volume_ml, l.input_unit, l.input_value,
			l.serving_key, l.volume_precision, l.place_name, l.place_url, l.created_at, l.updated_at,
			d.id, d.slug, d.name, d.category, d.abv
		FROM drink_logs l
		LEFT JOIN drinks d ON d.id = l.drink_id
		WHERE l.user_id = $1
			AND ($2::timestamptz IS NULL OR l.drank_at >= $2)
			AND ($3::timestamptz IS NULL OR l.drank_at < $3)
		ORDER BY l.drank_at DESC
		LIMIT $4 OFFSET $5`

	rows, err := r.db.QueryContext(ctx, q, userID, params.From, params.To, params.Limit, params.Offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var logs []Log
	for rows.Next() {
		var (
			log      Log
			drinkID  sql.NullString
			custom   sql.NullString
			sk       sql.NullString
			place    sql.NullString
			placeURL sql.NullString
			dID      sql.NullString
			dSlug    sql.NullString
			dName    sql.NullString
			dCat     sql.NullString
			abv      sql.NullFloat64
		)
		if err := rows.Scan(
			&log.ID, &log.UserID, &drinkID, &custom, &log.DrankAt, &log.VolumeML, &log.InputUnit, &log.InputValue,
			&sk, &log.VolumePrecision, &place, &placeURL, &log.CreatedAt, &log.UpdatedAt,
			&dID, &dSlug, &dName, &dCat, &abv,
		); err != nil {
			return nil, err
		}
		if drinkID.Valid {
			log.DrinkID = &drinkID.String
		}
		if custom.Valid {
			log.CustomDrinkName = &custom.String
		}
		if sk.Valid {
			log.ServingKey = &sk.String
		}
		if place.Valid {
			log.PlaceName = &place.String
		}
		if placeURL.Valid {
			log.PlaceURL = &placeURL.String
		}
		if dID.Valid {
			drink := DrinkSummary{
				ID:       dID.String,
				Slug:     dSlug.String,
				Name:     dName.String,
				Category: dCat.String,
			}
			if abv.Valid {
				v := abv.Float64
				drink.ABV = &v
			}
			log.Drink = &drink
		}
		logs = append(logs, log)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if logs == nil {
		logs = []Log{}
	}
	return logs, nil
}

func (r *repository) Delete(ctx context.Context, id, userID string) error {
	const q = `DELETE FROM drink_logs WHERE id = $1 AND user_id = $2`

	result, err := r.db.ExecContext(ctx, q, id, userID)
	if err != nil {
		return err
	}
	n, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return ErrForbidden
	}
	return nil
}

func (r *repository) Summary(
	ctx context.Context, userID string, from, to time.Time,
) (logCount, skipped int, pureGrams float64, err error) {
	const q = `
		SELECT
			COUNT(*)::int AS log_count,
			COUNT(*) FILTER (WHERE d.abv IS NULL)::int AS skipped,
			COALESCE(
				SUM(
					CASE
						WHEN d.abv IS NULL THEN 0
						ELSE l.volume_ml * (d.abv / 100.0) * 0.789
					END
				),
				0
			) AS pure_grams
		FROM drink_logs l
		LEFT JOIN drinks d ON d.id = l.drink_id
		WHERE l.user_id = $1
			AND l.drank_at >= $2
			AND l.drank_at < $3`

	err = r.db.QueryRowContext(ctx, q, userID, from, to).Scan(&logCount, &skipped, &pureGrams)
	if err != nil {
		return 0, 0, 0, err
	}
	pureGrams = round2(pureGrams)
	return logCount, skipped, pureGrams, nil
}

// InsertSearchMiss records an unregistered drink name for catalog demand.
func (r *repository) InsertSearchMiss(ctx context.Context, userID, queryRaw string) error {
	normalized := normalizeMissQuery(queryRaw)
	if utf8.RuneCountInString(normalized) < 2 || utf8.RuneCountInString(normalized) > 40 {
		return nil
	}
	if utf8.RuneCountInString(queryRaw) == 0 || utf8.RuneCountInString(queryRaw) > 200 {
		return nil
	}

	const q = `
		INSERT INTO search_misses (scope, query_raw, query_normalized, result_count, user_id)
		VALUES ('drink', $1, $2, 0, $3)`

	_, err := r.db.ExecContext(ctx, q, queryRaw, normalized, userID)
	return err
}
