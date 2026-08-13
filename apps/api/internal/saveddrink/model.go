package saveddrink

import "time"

const (
	StatusDrank = "drank"
	StatusWant  = "want"
	MaxNoteLen  = 280
	// MaxProvisionalRaw is the max rune length of the trimmed display name.
	// Keep in sync with apps/web MAX_PROVISIONAL_NAME_LEN in saved-drink-actions.ts.
	MaxProvisionalRaw = 200
	MinNormalizedLen  = 2
	MaxNormalizedLen  = 40
	// MaxProvisionalPerUser caps distinct provisional drinks per owner.
	// Re-saving the same normalized name upserts and does not count as new.
	MaxProvisionalPerUser = 100
	VisibilityPublished   = "published"
	VisibilityProvisional = "provisional"
)

// DrinkSummary is the catalog slice embedded on list responses.
type DrinkSummary struct {
	ID         string  `json:"id"`
	Slug       string  `json:"slug"`
	Name       string  `json:"name"`
	NameEn     *string `json:"name_en,omitempty"`
	Category   string  `json:"category"`
	ImageURL   *string `json:"image_url,omitempty"`
	Visibility string  `json:"visibility"`
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

type SaveProvisionalInput struct {
	Name   string `json:"name"`
	Status string `json:"status"`
}

type PatchInput struct {
	Status *string `json:"status"`
	Note   *string `json:"note"`
}

type ListParams struct {
	Limit  int
	Offset int
}
