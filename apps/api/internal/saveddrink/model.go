package saveddrink

import "time"

const (
	StatusDrank = "drank"
	StatusWant  = "want"
	MaxNoteLen  = 280
)

// DrinkSummary is the catalog slice embedded on list responses.
type DrinkSummary struct {
	ID       string  `json:"id"`
	Slug     string  `json:"slug"`
	Name     string  `json:"name"`
	NameEn   *string `json:"name_en,omitempty"`
	Category string  `json:"category"`
	ImageURL *string `json:"image_url,omitempty"`
}

// SavedDrink is a personal 1-per-user catalog mark. Rating is optional.
type SavedDrink struct {
	ID        string        `json:"id"`
	UserID    string        `json:"user_id"`
	DrinkID   string        `json:"drink_id"`
	Status    string        `json:"status"`
	Note      string        `json:"note"`
	CreatedAt time.Time     `json:"created_at"`
	Drink     *DrinkSummary `json:"drink,omitempty"`
	Rating    *int          `json:"rating,omitempty"`
	Comment   *string       `json:"comment,omitempty"`
}

type SaveInput struct {
	DrinkID string `json:"drink_id"`
	Status  string `json:"status"`
}

type PatchInput struct {
	Status *string `json:"status"`
	Note   *string `json:"note"`
}

type ListParams struct {
	Limit  int
	Offset int
}
