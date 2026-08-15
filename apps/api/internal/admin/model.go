package admin

import (
	"errors"
	"time"
)

var (
	ErrNotFound     = errors.New("admin subject not found")
	ErrUnauthorized = errors.New("unauthorized")
	ErrValidation   = errors.New("validation error")
)

const (
	AppRoleAdmin            = "admin"
	DefaultSearchMissLimit  = 100
	MaxSearchMissLimit      = 100
	DefaultProvisionalLimit = 100
	MaxProvisionalLimit     = 100
	searchMissScopeAll      = "all"
	searchMissScopeDrink    = "drink"
	searchMissScopeCocktail = "cocktail"
	searchMissScopeIng      = "ingredient"
	savedStatusDrank        = "drank"
	savedStatusWant         = "want"
)

type Overview struct {
	DrinkMissRows     int `json:"drink_miss_rows"`
	DrinkMissQueries  int `json:"drink_miss_queries"`
	ProvisionalDrinks int `json:"provisional_drinks"`
	PublishedDrinks   int `json:"published_drinks"`
}

type SearchMissListParams struct {
	Scope  string
	Limit  int
	Offset int
}

type SearchMissRow struct {
	Scope           string    `json:"scope"`
	QueryNormalized string    `json:"query_normalized"`
	SampleQueryRaw  string    `json:"sample_query_raw"`
	MissCount       int       `json:"miss_count"`
	UniqueSearchers int       `json:"unique_searchers"`
	LastSeenAt      time.Time `json:"last_seen_at"`
}

type SearchMissListResult struct {
	Data   []SearchMissRow `json:"data"`
	Total  int             `json:"total"`
	Limit  int             `json:"limit"`
	Offset int             `json:"offset"`
}

type ProvisionalDrinkListParams struct {
	Limit  int
	Offset int
}

// ProvisionalDrinkRow is one unmerged personal stake across all users.
// Visibility is always provisional; published catalog rows are never included.
type ProvisionalDrinkRow struct {
	ID                   string    `json:"id"`
	Name                 string    `json:"name"`
	NameNormalized       string    `json:"name_normalized"`
	SubmittedBy          string    `json:"submitted_by"`
	SubmitterDisplayName string    `json:"submitter_display_name"`
	SubmitterEmail       string    `json:"submitter_email"`
	CreatedAt            time.Time `json:"created_at"`
	HasSavedDrink        bool      `json:"has_saved_drink"`
	SavedStatus          *string   `json:"saved_status"`
}

type ProvisionalDrinkListResult struct {
	Data   []ProvisionalDrinkRow `json:"data"`
	Total  int                   `json:"total"`
	Limit  int                   `json:"limit"`
	Offset int                   `json:"offset"`
}
