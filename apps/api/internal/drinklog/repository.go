package drinklog

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
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
	FindByID(ctx context.Context, id, userID string) (*Log, error)
	Update(ctx context.Context, log *Log) error
	ListByUser(ctx context.Context, userID string, params ListParams) ([]Log, error)
	Delete(ctx context.Context, id, userID string) error
	CountInRange(ctx context.Context, userID string, from, to time.Time) (int, error)
	ReplaceInRange(ctx context.Context, userID string, from, to time.Time, incoming []Log) ([]Log, error)
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
			user_id, drink_id, custom_drink_name, drank_at, volume_ml, quantity, input_unit, input_value,
			serving_key, volume_precision, place_name, place_url
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		RETURNING id, created_at, updated_at`

	return r.db.QueryRowContext(ctx, q,
		log.UserID, log.DrinkID, log.CustomDrinkName, log.DrankAt, log.VolumeML, log.Quantity, log.InputUnit, log.InputValue,
		log.ServingKey, log.VolumePrecision, log.PlaceName, log.PlaceURL,
	).Scan(&log.ID, &log.CreatedAt, &log.UpdatedAt)
}

const logSelectColumns = `
	l.id, l.user_id, l.drink_id, l.custom_drink_name, l.drank_at, l.volume_ml, l.quantity, l.input_unit, l.input_value,
	l.serving_key, l.volume_precision, l.place_name, l.place_url, l.created_at, l.updated_at,
	d.id, d.slug, d.name, d.category, d.abv`

func scanLog(scanner interface {
	Scan(dest ...any) error
}) (Log, error) {
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
	if err := scanner.Scan(
		&log.ID, &log.UserID, &drinkID, &custom, &log.DrankAt, &log.VolumeML, &log.Quantity, &log.InputUnit, &log.InputValue,
		&sk, &log.VolumePrecision, &place, &placeURL, &log.CreatedAt, &log.UpdatedAt,
		&dID, &dSlug, &dName, &dCat, &abv,
	); err != nil {
		return Log{}, err
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
	return log, nil
}

func (r *repository) FindByID(ctx context.Context, id, userID string) (*Log, error) {
	q := `
		SELECT ` + logSelectColumns + `
		FROM drink_logs l
		LEFT JOIN drinks d ON d.id = l.drink_id
		WHERE l.id = $1 AND l.user_id = $2`

	log, err := scanLog(r.db.QueryRowContext(ctx, q, id, userID))
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &log, nil
}

func (r *repository) Update(ctx context.Context, log *Log) error {
	const q = `
		UPDATE drink_logs SET
			drink_id = $1,
			custom_drink_name = $2,
			drank_at = $3,
			volume_ml = $4,
			quantity = $5,
			input_unit = $6,
			input_value = $7,
			serving_key = $8,
			volume_precision = $9,
			place_name = $10,
			place_url = $11
		WHERE id = $12 AND user_id = $13
		RETURNING updated_at`

	err := r.db.QueryRowContext(ctx, q,
		log.DrinkID, log.CustomDrinkName, log.DrankAt, log.VolumeML, log.Quantity, log.InputUnit, log.InputValue,
		log.ServingKey, log.VolumePrecision, log.PlaceName, log.PlaceURL,
		log.ID, log.UserID,
	).Scan(&log.UpdatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return ErrNotFound
	}
	return err
}

func (r *repository) ListByUser(ctx context.Context, userID string, params ListParams) ([]Log, error) {
	q := `
		SELECT ` + logSelectColumns + `
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
		log, err := scanLog(rows)
		if err != nil {
			return nil, err
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

func (r *repository) CountInRange(ctx context.Context, userID string, from, to time.Time) (int, error) {
	const q = `SELECT COUNT(*) FROM drink_logs WHERE user_id = $1 AND drank_at >= $2 AND drank_at < $3`
	var n int
	if err := r.db.QueryRowContext(ctx, q, userID, from, to).Scan(&n); err != nil {
		return 0, err
	}
	return n, nil
}

func (r *repository) ReplaceInRange(ctx context.Context, userID string, from, to time.Time, incoming []Log) ([]Log, error) {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()

	rows, err := tx.QueryContext(ctx, `
		SELECT id, drank_at FROM drink_logs
		WHERE user_id = $1 AND drank_at >= $2 AND drank_at < $3
		FOR UPDATE`, userID, from, to)
	if err != nil {
		return nil, err
	}
	existingTimes := make(map[string]time.Time)
	for rows.Next() {
		var id string
		var drankAt time.Time
		if err := rows.Scan(&id, &drankAt); err != nil {
			rows.Close()
			return nil, err
		}
		existingTimes[id] = drankAt
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return nil, err
	}
	rows.Close()

	if len(existingTimes) > maxItemsPerBatch {
		return nil, fmt.Errorf("%w: too many logs in day to replace (max %d)", ErrConflict, maxItemsPerBatch)
	}

	incomingIDs := make(map[string]struct{}, len(incoming))
	for i := range incoming {
		id := strings.TrimSpace(incoming[i].ID)
		if id == "" {
			continue
		}
		if _, ok := existingTimes[id]; !ok {
			return nil, fmt.Errorf("%w: item id not in range", ErrValidation)
		}
		incomingIDs[id] = struct{}{}
		incoming[i].ID = id
	}

	for id := range existingTimes {
		if _, keep := incomingIDs[id]; keep {
			continue
		}
		if _, err := tx.ExecContext(ctx, `DELETE FROM drink_logs WHERE id = $1 AND user_id = $2`, id, userID); err != nil {
			return nil, err
		}
	}

	const insertQ = `
		INSERT INTO drink_logs (
			user_id, drink_id, custom_drink_name, drank_at, volume_ml, quantity, input_unit, input_value,
			serving_key, volume_precision, place_name, place_url
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		RETURNING id, created_at, updated_at`

	const updateQ = `
		UPDATE drink_logs SET
			drink_id = $1,
			custom_drink_name = $2,
			drank_at = $3,
			volume_ml = $4,
			quantity = $5,
			input_unit = $6,
			input_value = $7,
			serving_key = $8,
			volume_precision = $9,
			place_name = $10,
			place_url = $11
		WHERE id = $12 AND user_id = $13
		RETURNING updated_at`

	resultIDs := make([]string, 0, len(incoming))
	for i := range incoming {
		log := &incoming[i]
		log.UserID = userID
		if log.ID != "" {
			if orig, ok := existingTimes[log.ID]; ok {
				inOriginalDay := !log.DrankAt.Before(from) && log.DrankAt.Before(to)
				if inOriginalDay {
					log.DrankAt = orig
				}
			}
			err := tx.QueryRowContext(ctx, updateQ,
				log.DrinkID, log.CustomDrinkName, log.DrankAt, log.VolumeML, log.Quantity, log.InputUnit, log.InputValue,
				log.ServingKey, log.VolumePrecision, log.PlaceName, log.PlaceURL,
				log.ID, userID,
			).Scan(&log.UpdatedAt)
			if err != nil {
				return nil, err
			}
		} else {
			err := tx.QueryRowContext(ctx, insertQ,
				userID, log.DrinkID, log.CustomDrinkName, log.DrankAt, log.VolumeML, log.Quantity, log.InputUnit, log.InputValue,
				log.ServingKey, log.VolumePrecision, log.PlaceName, log.PlaceURL,
			).Scan(&log.ID, &log.CreatedAt, &log.UpdatedAt)
			if err != nil {
				return nil, err
			}
		}
		resultIDs = append(resultIDs, log.ID)
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}

	out := make([]Log, 0, len(resultIDs))
	for _, id := range resultIDs {
		found, err := r.FindByID(ctx, id, userID)
		if err != nil {
			return nil, err
		}
		out = append(out, *found)
	}
	return out, nil
}

func (r *repository) Summary(
	ctx context.Context, userID string, from, to time.Time,
) (logCount, skipped int, pureGrams float64, err error) {
	const q = `
		SELECT
			COALESCE(SUM(l.quantity), 0)::int AS log_count,
			COALESCE(SUM(l.quantity) FILTER (WHERE d.abv IS NULL), 0)::int AS skipped,
			COALESCE(
				SUM(
					CASE
						WHEN d.abv IS NULL THEN 0
						ELSE l.volume_ml * l.quantity * (d.abv / 100.0) * 0.789
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
