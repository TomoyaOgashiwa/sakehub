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
// search_vector is excluded because it is a generated column used only for queries.
const allColumns = `id, slug, name, name_en, category, subcategory, description,
	image_url, abv, origin_country, manufacturer,
	average_rating, total_reviews, created_at, updated_at`

type Repository interface {
	FindByID(ctx context.Context, id string) (*Drink, error)
	FindBySlug(ctx context.Context, slug string) (*Drink, error)
	List(ctx context.Context, params ListParams) ([]Drink, int, error)
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
		&d.Description, &d.ImageURL, &d.ABV, &d.OriginCountry, &d.Manufacturer,
		&d.AverageRating, &d.TotalReviews, &d.CreatedAt, &d.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &d, nil
}

func (r *repository) FindByID(ctx context.Context, id string) (*Drink, error) {
	q := fmt.Sprintf(`SELECT %s FROM drinks WHERE id = $1`, allColumns)

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
	q := fmt.Sprintf(`SELECT %s FROM drinks WHERE slug = $1`, allColumns)

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
// Filtering by category and full-text search query are both optional.
func (r *repository) List(ctx context.Context, params ListParams) ([]Drink, int, error) {
	var (
		conditions []string
		args       []any
		argIdx     int
	)

	if params.Category != "" {
		argIdx++
		conditions = append(conditions, fmt.Sprintf("category = $%d", argIdx))
		args = append(args, params.Category)
	}

	if params.Query != "" {
		argIdx++
		conditions = append(conditions, fmt.Sprintf("search_vector @@ plainto_tsquery('simple', $%d)", argIdx))
		args = append(args, params.Query)
	}

	where := ""
	if len(conditions) > 0 {
		where = "WHERE " + strings.Join(conditions, " AND ")
	}

	countQ := fmt.Sprintf(`SELECT COUNT(*) FROM drinks %s`, where)
	var total int
	if err := r.db.QueryRowContext(ctx, countQ, args...).Scan(&total); err != nil {
		return nil, 0, err
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

	q := fmt.Sprintf(
		`SELECT %s FROM drinks %s ORDER BY created_at DESC LIMIT %s OFFSET %s`,
		allColumns, where, limitPlaceholder, offsetPlaceholder,
	)

	rows, err := r.db.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var drinks []Drink
	for rows.Next() {
		var d Drink
		if err := rows.Scan(
			&d.ID, &d.Slug, &d.Name, &d.NameEn, &d.Category, &d.Subcategory,
			&d.Description, &d.ImageURL, &d.ABV, &d.OriginCountry, &d.Manufacturer,
			&d.AverageRating, &d.TotalReviews, &d.CreatedAt, &d.UpdatedAt,
		); err != nil {
			return nil, 0, err
		}
		drinks = append(drinks, d)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}

	return drinks, total, nil
}

func (r *repository) Insert(ctx context.Context, d *Drink) error {
	const q = `INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, average_rating, total_reviews, created_at, updated_at`

	return r.db.QueryRowContext(ctx, q,
		d.Slug, d.Name, d.NameEn, d.Category, d.Subcategory,
		d.Description, d.ImageURL, d.ABV, d.OriginCountry, d.Manufacturer,
	).Scan(&d.ID, &d.AverageRating, &d.TotalReviews, &d.CreatedAt, &d.UpdatedAt)
}
