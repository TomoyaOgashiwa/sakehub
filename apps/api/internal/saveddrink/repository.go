package saveddrink

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/lib/pq"
)

type Repository interface {
	DrinkExists(ctx context.Context, drinkID string) (bool, error)
	Upsert(ctx context.Context, userID, drinkID, status string) (*SavedDrink, error)
	UpsertProvisional(ctx context.Context, userID, name, nameNormalized, status string) (*SavedDrink, error)
	Update(ctx context.Context, drinkID, userID string, status, note *string) (*SavedDrink, error)
	FindByDrinkAndUser(ctx context.Context, drinkID, userID string) (*SavedDrink, error)
	ListByUser(ctx context.Context, userID string, params ListParams) ([]SavedDrink, error)
	DeleteByDrinkAndUser(ctx context.Context, drinkID, userID string) error
	ListDrankPublished(ctx context.Context, userID string) ([]DrankDrink, error)
	CountPublishedByCategory(ctx context.Context) ([]CategoryTotal, error)
	ListUnsavedByManufacturer(ctx context.Context, excludeIDs []string, manufacturer string, category *string, limit int) ([]DepthNextDrink, error)
}

type repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &repository{db: db}
}

func (r *repository) DrinkExists(ctx context.Context, drinkID string) (bool, error) {
	const q = `SELECT EXISTS(SELECT 1 FROM drinks WHERE id = $1 AND visibility = 'published')`
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

func (r *repository) UpsertProvisional(ctx context.Context, userID, name, nameNormalized, status string) (*SavedDrink, error) {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// Owner-scoped lock so COUNT + INSERT cannot race past MaxProvisionalPerUser.
	if _, err := tx.ExecContext(ctx, `SELECT pg_advisory_xact_lock(hashtext($1))`, userID); err != nil {
		return nil, err
	}

	var exists bool
	if err := tx.QueryRowContext(ctx, `
		SELECT EXISTS(
			SELECT 1 FROM drinks
			WHERE visibility = 'provisional' AND submitted_by = $1 AND name_normalized = $2
		)`, userID, nameNormalized).Scan(&exists); err != nil {
		return nil, err
	}
	if !exists {
		var n int
		if err := tx.QueryRowContext(ctx, `
			SELECT COUNT(*) FROM drinks
			WHERE visibility = 'provisional' AND submitted_by = $1`, userID).Scan(&n); err != nil {
			return nil, err
		}
		if n >= MaxProvisionalPerUser {
			return nil, fmt.Errorf("%w: provisional limit reached", ErrValidation)
		}
	}

	const insertDrink = `
		INSERT INTO drinks (
			slug, name, name_normalized, category, description,
			visibility, submitted_by, image_source
		)
		VALUES (
			'p-' || replace(gen_random_uuid()::text, '-', ''),
			$1, $2, 'other', '', 'provisional', $3, 'none'
		)
		ON CONFLICT (submitted_by, name_normalized) WHERE visibility = 'provisional'
		DO UPDATE SET name = EXCLUDED.name
		RETURNING id`

	var drinkID string
	if err := tx.QueryRowContext(ctx, insertDrink, name, nameNormalized, userID).Scan(&drinkID); err != nil {
		return nil, err
	}

	const upsertSaved = `
		INSERT INTO saved_drinks (user_id, drink_id, status)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id, drink_id)
		DO UPDATE SET status = EXCLUDED.status
		RETURNING id, user_id, drink_id, status, note, created_at`

	var row SavedDrink
	if err := tx.QueryRowContext(ctx, upsertSaved, userID, drinkID, status).Scan(
		&row.ID, &row.UserID, &row.DrinkID, &row.Status, &row.Note, &row.CreatedAt,
	); err != nil {
		return nil, err
	}

	if err := tx.Commit(); err != nil {
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
			d.id, d.slug, d.name, d.name_en, d.category, d.image_url, d.visibility, d.manufacturer,
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
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	const delSaved = `DELETE FROM saved_drinks WHERE drink_id = $1 AND user_id = $2`
	if _, err := tx.ExecContext(ctx, delSaved, drinkID, userID); err != nil {
		return err
	}

	const delOrphan = `
		DELETE FROM drinks
		WHERE id = $1
		  AND visibility = 'provisional'
		  AND submitted_by = $2
		  AND NOT EXISTS (SELECT 1 FROM saved_drinks s WHERE s.drink_id = drinks.id)
		  AND NOT EXISTS (SELECT 1 FROM drink_logs l WHERE l.drink_id = drinks.id)`
	if _, err := tx.ExecContext(ctx, delOrphan, drinkID, userID); err != nil {
		return err
	}

	return tx.Commit()
}

func (r *repository) ListDrankPublished(ctx context.Context, userID string) ([]DrankDrink, error) {
	const q = `
		SELECT DISTINCT u.drink_id, d.category, COALESCE(d.manufacturer, '')
		FROM (
			SELECT s.drink_id
			FROM saved_drinks s
			INNER JOIN drinks d ON d.id = s.drink_id
			WHERE s.user_id = $1
			  AND s.status = 'drank'
			  AND d.visibility = 'published'
			UNION
			SELECT l.drink_id
			FROM drink_logs l
			INNER JOIN drinks d ON d.id = l.drink_id
			WHERE l.user_id = $1
			  AND l.drink_id IS NOT NULL
			  AND d.visibility = 'published'
		) u
		INNER JOIN drinks d ON d.id = u.drink_id`

	rows, err := r.db.QueryContext(ctx, q, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []DrankDrink
	for rows.Next() {
		var item DrankDrink
		if err := rows.Scan(&item.DrinkID, &item.Category, &item.Manufacturer); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if items == nil {
		items = []DrankDrink{}
	}
	return items, rows.Err()
}

func (r *repository) CountPublishedByCategory(ctx context.Context) ([]CategoryTotal, error) {
	const q = `
		SELECT category, COUNT(*)::int
		FROM drinks
		WHERE visibility = 'published'
		GROUP BY category`

	rows, err := r.db.QueryContext(ctx, q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []CategoryTotal
	for rows.Next() {
		var item CategoryTotal
		if err := rows.Scan(&item.Category, &item.Total); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if items == nil {
		items = []CategoryTotal{}
	}
	return items, rows.Err()
}

func (r *repository) ListUnsavedByManufacturer(
	ctx context.Context,
	excludeIDs []string,
	manufacturer string,
	category *string,
	limit int,
) ([]DepthNextDrink, error) {
	if excludeIDs == nil {
		excludeIDs = []string{}
	}
	const q = `
		SELECT slug, name
		FROM drinks
		WHERE visibility = 'published'
		  AND manufacturer = $1
		  AND ($2::text IS NULL OR category = $2)
		  AND NOT (id = ANY($3::uuid[]))
		ORDER BY name
		LIMIT $4`

	var cat any
	if category != nil && *category != "" {
		cat = *category
	}

	rows, err := r.db.QueryContext(ctx, q, manufacturer, cat, pq.Array(excludeIDs), limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []DepthNextDrink
	for rows.Next() {
		var item DepthNextDrink
		if err := rows.Scan(&item.Slug, &item.Name); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if items == nil {
		items = []DepthNextDrink{}
	}
	return items, rows.Err()
}

func scanListed(rows *sql.Rows) (SavedDrink, error) {
	var (
		item         SavedDrink
		drink        DrinkSummary
		nameEn       sql.NullString
		imageURL     sql.NullString
		manufacturer sql.NullString
		rating       sql.NullInt64
		comment      sql.NullString
	)
	err := rows.Scan(
		&item.ID, &item.UserID, &item.DrinkID, &item.Status, &item.Note, &item.CreatedAt,
		&drink.ID, &drink.Slug, &drink.Name, &nameEn, &drink.Category, &imageURL, &drink.Visibility, &manufacturer,
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
	if manufacturer.Valid && manufacturer.String != "" {
		drink.Manufacturer = &manufacturer.String
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
