package saveddrink

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

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
	CountDrankByCategory(ctx context.Context, userID string) ([]CategoryCount, error)
	CountPublishedByCategory(ctx context.Context) ([]CategoryTotal, error)
	CountProvisional(ctx context.Context, userID string) (int, error)
	ListMakers(ctx context.Context, userID string, category *string) ([]DepthMaker, error)
	ListUnsavedByManufacturer(ctx context.Context, userID, manufacturer string, category *string, limit int) ([]DepthNextDrink, error)
	ListPublishedIdentities(ctx context.Context) ([]PublishedIdentity, error)
	ListUnmergedProvisionals(ctx context.Context) ([]ProvisionalCandidate, error)
	MergeProvisionalInto(ctx context.Context, provisionalID, publishedID string) (MergeOneResult, error)
	DeleteMergedOrphans(ctx context.Context) (int, error)
}

// drankUnionCTE is unique published drink_id: saved.drank ∪ catalog drink_logs.
// Placeholder $1 must be user_id. Matches category-list union=drank.
const drankUnionCTE = `
drank AS (
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
)`

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
	if params.DrankUnion {
		return r.listDrankUnion(ctx, userID, params)
	}

	var b strings.Builder
	b.WriteString(`
		SELECT
			s.id, s.user_id, s.drink_id, s.status, s.note, s.created_at,
			d.id, d.slug, d.name, d.name_en, d.category, d.image_url, d.visibility, d.manufacturer,
			r.rating, r.comment
		FROM saved_drinks s
		INNER JOIN drinks d ON d.id = s.drink_id
		LEFT JOIN ratings r ON r.drink_id = s.drink_id AND r.user_id = s.user_id
		WHERE s.user_id = $1`)
	args := []any{userID}
	n := 2
	if params.Status != "" {
		fmt.Fprintf(&b, " AND s.status = $%d", n)
		args = append(args, params.Status)
		n++
	}
	if params.Category != "" {
		fmt.Fprintf(&b, " AND d.category = $%d", n)
		args = append(args, params.Category)
		n++
	}
	if params.Visibility != "" {
		fmt.Fprintf(&b, " AND d.visibility = $%d", n)
		args = append(args, params.Visibility)
		n++
	} else if params.PublishedOnly {
		b.WriteString(" AND d.visibility = 'published'")
	}
	fmt.Fprintf(&b, " ORDER BY s.created_at DESC LIMIT $%d OFFSET $%d", n, n+1)
	args = append(args, params.Limit, params.Offset)

	rows, err := r.db.QueryContext(ctx, b.String(), args...)
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

func (r *repository) listDrankUnion(ctx context.Context, userID string, params ListParams) ([]SavedDrink, error) {
	q := `
		WITH ` + drankUnionCTE + `
		SELECT
			s.id, s.user_id, u.drink_id, s.status, s.note, s.created_at,
			d.id, d.slug, d.name, d.name_en, d.category, d.image_url, d.visibility, d.manufacturer,
			r.rating, r.comment,
			d.created_at
		FROM drank u
		INNER JOIN drinks d ON d.id = u.drink_id
		LEFT JOIN saved_drinks s ON s.drink_id = u.drink_id AND s.user_id = $1
		LEFT JOIN ratings r ON r.drink_id = u.drink_id AND r.user_id = $1
		WHERE ($2::text IS NULL OR d.category = $2)
		ORDER BY COALESCE(s.created_at, d.created_at) DESC
		LIMIT $3 OFFSET $4`

	var cat any
	if params.Category != "" {
		cat = params.Category
	}

	rows, err := r.db.QueryContext(ctx, q, userID, cat, params.Limit, params.Offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []SavedDrink
	for rows.Next() {
		item, err := scanListedUnion(rows, userID)
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

func (r *repository) CountDrankByCategory(ctx context.Context, userID string) ([]CategoryCount, error) {
	q := `
		WITH ` + drankUnionCTE + `
		SELECT d.category, COUNT(*)::int
		FROM drank u
		INNER JOIN drinks d ON d.id = u.drink_id
		GROUP BY d.category`

	rows, err := r.db.QueryContext(ctx, q, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []CategoryCount
	for rows.Next() {
		var item CategoryCount
		if err := rows.Scan(&item.Category, &item.Drank); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if items == nil {
		items = []CategoryCount{}
	}
	return items, rows.Err()
}

func (r *repository) CountProvisional(ctx context.Context, userID string) (int, error) {
	const q = `
		SELECT COUNT(*)::int
		FROM saved_drinks s
		INNER JOIN drinks d ON d.id = s.drink_id
		WHERE s.user_id = $1
		  AND d.visibility = 'provisional'`
	var n int
	if err := r.db.QueryRowContext(ctx, q, userID).Scan(&n); err != nil {
		return 0, err
	}
	return n, nil
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

func (r *repository) ListMakers(ctx context.Context, userID string, category *string) ([]DepthMaker, error) {
	q := fmt.Sprintf(`
		WITH `+drankUnionCTE+`
		SELECT d.manufacturer, COUNT(*)::int
		FROM drank u
		INNER JOIN drinks d ON d.id = u.drink_id
		WHERE ($2::text IS NULL OR d.category = $2)
		  AND d.manufacturer IS NOT NULL
		  AND btrim(d.manufacturer) <> ''
		GROUP BY d.manufacturer
		HAVING COUNT(*) >= %d
		ORDER BY COUNT(*) DESC, d.manufacturer
		LIMIT %d`, minMakerDrank, maxDepthMakers)

	var cat any
	if category != nil && *category != "" {
		cat = *category
	}

	rows, err := r.db.QueryContext(ctx, q, userID, cat)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []DepthMaker
	for rows.Next() {
		var item DepthMaker
		if err := rows.Scan(&item.Manufacturer, &item.Drank); err != nil {
			return nil, err
		}
		item.NextDrinks = []DepthNextDrink{}
		items = append(items, item)
	}
	if items == nil {
		items = []DepthMaker{}
	}
	return items, rows.Err()
}

func (r *repository) ListUnsavedByManufacturer(
	ctx context.Context,
	userID, manufacturer string,
	category *string,
	limit int,
) ([]DepthNextDrink, error) {
	q := `
		WITH ` + drankUnionCTE + `
		SELECT d.slug, d.name
		FROM drinks d
		WHERE d.visibility = 'published'
		  AND d.manufacturer = $2
		  AND ($3::text IS NULL OR d.category = $3)
		  AND NOT EXISTS (SELECT 1 FROM drank u WHERE u.drink_id = d.id)
		ORDER BY d.name
		LIMIT $4`

	var cat any
	if category != nil && *category != "" {
		cat = *category
	}

	rows, err := r.db.QueryContext(ctx, q, userID, manufacturer, cat, limit)
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

func (r *repository) ListPublishedIdentities(ctx context.Context) ([]PublishedIdentity, error) {
	const q = `
		SELECT id, slug, name, aliases
		FROM drinks
		WHERE visibility = 'published'`
	rows, err := r.db.QueryContext(ctx, q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []PublishedIdentity
	for rows.Next() {
		var item PublishedIdentity
		var aliases pq.StringArray
		if err := rows.Scan(&item.ID, &item.Slug, &item.Name, &aliases); err != nil {
			return nil, err
		}
		item.Aliases = []string(aliases)
		if item.Aliases == nil {
			item.Aliases = []string{}
		}
		items = append(items, item)
	}
	if items == nil {
		items = []PublishedIdentity{}
	}
	return items, rows.Err()
}

func (r *repository) ListUnmergedProvisionals(ctx context.Context) ([]ProvisionalCandidate, error) {
	const q = `
		SELECT id, name_normalized
		FROM drinks
		WHERE visibility = 'provisional'
		  AND merged_into_id IS NULL
		  AND name_normalized IS NOT NULL`
	rows, err := r.db.QueryContext(ctx, q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []ProvisionalCandidate
	for rows.Next() {
		var item ProvisionalCandidate
		if err := rows.Scan(&item.ID, &item.NameNormalized); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if items == nil {
		items = []ProvisionalCandidate{}
	}
	return items, rows.Err()
}

func (r *repository) MergeProvisionalInto(ctx context.Context, provisionalID, publishedID string) (MergeOneResult, error) {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return MergeOneResult{}, err
	}
	defer tx.Rollback()

	if _, err := tx.ExecContext(ctx, `
		UPDATE drinks
		SET merged_into_id = $2
		WHERE id = $1
		  AND visibility = 'provisional'
		  AND merged_into_id IS NULL`, provisionalID, publishedID); err != nil {
		return MergeOneResult{}, err
	}

	remap, err := tx.ExecContext(ctx, `
		UPDATE saved_drinks s
		SET drink_id = $2
		WHERE s.drink_id = $1
		  AND NOT EXISTS (
			SELECT 1 FROM saved_drinks x
			WHERE x.user_id = s.user_id AND x.drink_id = $2
		  )`, provisionalID, publishedID)
	if err != nil {
		return MergeOneResult{}, err
	}
	remapped, err := remap.RowsAffected()
	if err != nil {
		return MergeOneResult{}, err
	}

	discard, err := tx.ExecContext(ctx, `DELETE FROM saved_drinks WHERE drink_id = $1`, provisionalID)
	if err != nil {
		return MergeOneResult{}, err
	}
	discarded, err := discard.RowsAffected()
	if err != nil {
		return MergeOneResult{}, err
	}

	del, err := tx.ExecContext(ctx, `
		DELETE FROM drinks
		WHERE id = $1
		  AND visibility = 'provisional'
		  AND NOT EXISTS (SELECT 1 FROM saved_drinks s WHERE s.drink_id = drinks.id)
		  AND NOT EXISTS (SELECT 1 FROM drink_logs l WHERE l.drink_id = drinks.id)`, provisionalID)
	if err != nil {
		return MergeOneResult{}, err
	}
	deletedRows, err := del.RowsAffected()
	if err != nil {
		return MergeOneResult{}, err
	}

	if err := tx.Commit(); err != nil {
		return MergeOneResult{}, err
	}
	return MergeOneResult{
		Remapped:  int(remapped),
		Discarded: int(discarded),
		Deleted:   deletedRows > 0,
	}, nil
}

func (r *repository) DeleteMergedOrphans(ctx context.Context) (int, error) {
	const q = `
		DELETE FROM drinks
		WHERE visibility = 'provisional'
		  AND merged_into_id IS NOT NULL
		  AND NOT EXISTS (SELECT 1 FROM saved_drinks s WHERE s.drink_id = drinks.id)
		  AND NOT EXISTS (SELECT 1 FROM drink_logs l WHERE l.drink_id = drinks.id)`
	res, err := r.db.ExecContext(ctx, q)
	if err != nil {
		return 0, err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return 0, err
	}
	return int(n), nil
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

func scanListedUnion(rows *sql.Rows, userID string) (SavedDrink, error) {
	var (
		item         SavedDrink
		drink        DrinkSummary
		savedID      sql.NullString
		savedUser    sql.NullString
		status       sql.NullString
		note         sql.NullString
		savedAt      sql.NullTime
		nameEn       sql.NullString
		imageURL     sql.NullString
		manufacturer sql.NullString
		rating       sql.NullInt64
		comment      sql.NullString
		drinkCreated time.Time
	)
	err := rows.Scan(
		&savedID, &savedUser, &item.DrinkID, &status, &note, &savedAt,
		&drink.ID, &drink.Slug, &drink.Name, &nameEn, &drink.Category, &imageURL, &drink.Visibility, &manufacturer,
		&rating, &comment,
		&drinkCreated,
	)
	if err != nil {
		return SavedDrink{}, err
	}
	if savedID.Valid {
		item.ID = savedID.String
		item.UserID = savedUser.String
		item.Status = status.String
		if note.Valid {
			item.Note = note.String
		}
		if savedAt.Valid {
			item.CreatedAt = savedAt.Time
		}
	} else {
		item.ID = ""
		item.UserID = userID
		item.Status = StatusDrank
		item.Note = ""
		item.CreatedAt = drinkCreated
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
