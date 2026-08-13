package drink

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
)

var ErrNotFound = errors.New("drink not found")

// allColumns is the shared SELECT column list for drinks.
// average_rating and total_reviews are computed dynamically from the ratings table.
// search_vector is excluded because it is a generated column used only for queries.
const allColumns = `id, slug, name, name_en, category, subcategory, description,
	image_url, image_source, abv, origin_country, manufacturer,
	COALESCE((SELECT AVG(r.rating)::NUMERIC(3,2) FROM ratings r WHERE r.drink_id = id), 0) AS average_rating,
	COALESCE((SELECT COUNT(*) FROM ratings r WHERE r.drink_id = id), 0)::INTEGER AS total_reviews,
	created_at, updated_at`

type Repository interface {
	FindByID(ctx context.Context, id string) (*Drink, error)
	FindBySlug(ctx context.Context, slug string) (*Drink, error)
	List(ctx context.Context, params ListParams) ([]Drink, int, error)
	SuggestSimilar(ctx context.Context, query string, limit int) ([]Drink, error)
	Insert(ctx context.Context, d *Drink) error
}

type repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
	return &repository{db: db}
}

func (r *repository) scanDrink(row interface{ Scan(dest ...any) error }) (*Drink, error) {
	var d Drink
	err := row.Scan(
		&d.ID, &d.Slug, &d.Name, &d.NameEn, &d.Category, &d.Subcategory,
		&d.Description, &d.ImageURL, &d.ImageSource, &d.ABV, &d.OriginCountry, &d.Manufacturer,
		&d.AverageRating, &d.TotalReviews, &d.CreatedAt, &d.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &d, nil
}

func (r *repository) FindByID(ctx context.Context, id string) (*Drink, error) {
	q := fmt.Sprintf(`SELECT %s FROM drinks WHERE id = $1 AND visibility = 'published'`, allColumns)

	d, err := r.scanDrink(r.db.QueryRowContext(ctx, q, id))
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return d, nil
}

func (r *repository) FindBySlug(ctx context.Context, slug string) (*Drink, error) {
	q := fmt.Sprintf(`SELECT %s FROM drinks WHERE slug = $1 AND visibility = 'published'`, allColumns)

	d, err := r.scanDrink(r.db.QueryRowContext(ctx, q, slug))
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return d, nil
}

// List returns drinks matching the given filters along with the total count.
// Filtering by category is optional. Search matches full-text (simple) plus
// case-insensitive substring on name/name_en/manufacturer/description (Japanese-friendly).
// COUNT(*) OVER() is used so that the total and the page data are fetched in a single query.
func (r *repository) List(ctx context.Context, params ListParams) ([]Drink, int, error) {
	var (
		conditions []string
		args       []any
		argIdx     int
	)

	conditions = append(conditions, "visibility = 'published'")

	if params.Category != "" {
		argIdx++
		conditions = append(conditions, fmt.Sprintf("category = $%d", argIdx))
		args = append(args, params.Category)
	}

	if params.Query != "" {
		argIdx++
		ph := fmt.Sprintf("$%d", argIdx)
		// FTS (simple) は分かち書きされない CJK に弱いため、strpos で日本語名の部分一致も OR する。
		// aliases（かな/ローマ字表記の別名候補）も同様にチェックし、例: 「だっさい」で
		// 漢字名「獺祭」として登録されたドリンクにヒットさせる。
		match := fmt.Sprintf(`(
(search_vector @@ plainto_tsquery('simple', %s))
OR strpos(name, %s) > 0
OR strpos(lower(COALESCE(name_en, '')), lower(%s)) > 0
OR strpos(lower(COALESCE(manufacturer, '')), lower(%s)) > 0
OR strpos(lower(description), lower(%s)) > 0
OR EXISTS (SELECT 1 FROM unnest(aliases) AS alias WHERE strpos(lower(alias), lower(%s)) > 0)
)`, ph, ph, ph, ph, ph, ph)
		conditions = append(conditions, match)
		args = append(args, params.Query)
	}

	where := ""
	if len(conditions) > 0 {
		where = "WHERE " + strings.Join(conditions, " AND ")
	}

	limit := params.Limit
	if limit <= 0 {
		limit = 20
	}
	offset := params.Offset
	if offset < 0 {
		offset = 0
	}

	argIdx++
	limitPlaceholder := fmt.Sprintf("$%d", argIdx)
	argIdx++
	offsetPlaceholder := fmt.Sprintf("$%d", argIdx)
	args = append(args, limit, offset)

	// COUNT(*) OVER() returns the total matching rows alongside each data row,
	// eliminating the need for a separate COUNT query.
	q := fmt.Sprintf(
		`SELECT %s, COUNT(*) OVER() AS total FROM drinks %s ORDER BY created_at DESC LIMIT %s OFFSET %s`,
		allColumns, where, limitPlaceholder, offsetPlaceholder,
	)

	rows, err := r.db.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var (
		drinks []Drink
		total  int
	)
	for rows.Next() {
		var d Drink
		if err := rows.Scan(
			&d.ID, &d.Slug, &d.Name, &d.NameEn, &d.Category, &d.Subcategory,
			&d.Description, &d.ImageURL, &d.ImageSource, &d.ABV, &d.OriginCountry, &d.Manufacturer,
			&d.AverageRating, &d.TotalReviews, &d.CreatedAt, &d.UpdatedAt,
			&total,
		); err != nil {
			return nil, 0, err
		}
		drinks = append(drinks, d)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}
	if drinks == nil {
		drinks = []Drink{}
	}

	return drinks, total, nil
}

// suggestionColumns is a thin projection for zero-hit similar drinks.
// Ratings aggregates stay off this path so trgm candidates are not scanned with
// correlated AVG/COUNT before LIMIT.
const suggestionColumns = `id, slug, name, name_en, category, subcategory, description,
	image_url, image_source, abv, origin_country, manufacturer,
	created_at, updated_at`

func (r *repository) scanSuggestion(row interface{ Scan(dest ...any) error }) (*Drink, error) {
	var d Drink
	err := row.Scan(
		&d.ID, &d.Slug, &d.Name, &d.NameEn, &d.Category, &d.Subcategory,
		&d.Description, &d.ImageURL, &d.ImageSource, &d.ABV, &d.OriginCountry, &d.Manufacturer,
		&d.CreatedAt, &d.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &d, nil
}

func (r *repository) SuggestSimilar(ctx context.Context, query string, limit int) ([]Drink, error) {
	if limit <= 0 {
		limit = MaxSuggestions
	}

	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// % uses gin_trgm_ops (idx_drinks_name_trgm). similarity() > n does not.
	// Threshold is a package constant, not request input.
	setLocal := fmt.Sprintf("SET LOCAL pg_trgm.similarity_threshold = %g", SimilarityThreshold)
	if _, err := tx.ExecContext(ctx, setLocal); err != nil {
		return nil, err
	}

	q := fmt.Sprintf(`
		SELECT %s
		FROM (
			SELECT %s,
				GREATEST(
					similarity(name, $1),
					COALESCE((SELECT max(similarity(a, $1)) FROM unnest(aliases) a), 0)
				) AS sim
			FROM drinks
			WHERE visibility = 'published'
			  AND (
				name %% $1
				OR EXISTS (SELECT 1 FROM unnest(aliases) a WHERE a %% $1)
			  )
		) ranked
		ORDER BY sim DESC
		LIMIT $2`, suggestionColumns, suggestionColumns)

	rows, err := tx.QueryContext(ctx, q, query, limit)
	if err != nil {
		return nil, err
	}

	var drinks []Drink
	for rows.Next() {
		d, err := r.scanSuggestion(rows)
		if err != nil {
			rows.Close()
			return nil, err
		}
		drinks = append(drinks, *d)
	}
	scanErr := rows.Err()
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if scanErr != nil {
		return nil, scanErr
	}
	if drinks == nil {
		drinks = []Drink{}
	}
	if err := tx.Commit(); err != nil {
		return nil, err
	}
	return drinks, nil
}

func (r *repository) Insert(ctx context.Context, d *Drink) error {
	const q = `INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, image_source, abv, origin_country, manufacturer)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING id, created_at, updated_at`

	if d.ImageSource == "" {
		d.ImageSource = "none"
	}

	if err := r.db.QueryRowContext(ctx, q,
		d.Slug, d.Name, d.NameEn, d.Category, d.Subcategory,
		d.Description, d.ImageURL, d.ImageSource, d.ABV, d.OriginCountry, d.Manufacturer,
	).Scan(&d.ID, &d.CreatedAt, &d.UpdatedAt); err != nil {
		return err
	}
	// New drinks have no ratings yet.
	d.AverageRating = 0
	d.TotalReviews = 0
	return nil
}
