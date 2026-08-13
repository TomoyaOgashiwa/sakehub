package drink

import "time"

type Drink struct {
	ID            string    `json:"id"`
	Slug          string    `json:"slug"`
	Name          string    `json:"name"`
	NameEn        *string   `json:"name_en,omitempty"`
	Category      string    `json:"category"`
	Subcategory   *string   `json:"subcategory,omitempty"`
	Description   string    `json:"description"`
	ImageURL      *string   `json:"image_url,omitempty"`
	ImageSource   string    `json:"image_source"`
	ABV           *float64  `json:"abv,omitempty"`
	OriginCountry *string   `json:"origin_country,omitempty"`
	Manufacturer  *string   `json:"manufacturer,omitempty"`
	AverageRating float64   `json:"average_rating"`
	TotalReviews  int       `json:"total_reviews"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

type CreateInput struct {
	Slug          string   `json:"slug"`
	Name          string   `json:"name"`
	NameEn        *string  `json:"name_en,omitempty"`
	Category      string   `json:"category"`
	Subcategory   *string  `json:"subcategory,omitempty"`
	Description   string   `json:"description"`
	ImageURL      *string  `json:"image_url,omitempty"`
	ABV           *float64 `json:"abv,omitempty"`
	OriginCountry *string  `json:"origin_country,omitempty"`
	Manufacturer  *string  `json:"manufacturer,omitempty"`
}

type ListParams struct {
	Category string
	Query    string
	Limit    int
	Offset   int
}

const (
	SimilarityThreshold = 0.3
	MaxSuggestions      = 5
	// MinSuggestQueryLen skips trgm suggestions for 1-rune queries (e.g. 「酒」「あ」).
	// Aligned with saveddrink.MinNormalizedLen.
	MinSuggestQueryLen = 2
)
