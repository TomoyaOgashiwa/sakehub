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
	ID           string  `json:"id"`
	Slug         string  `json:"slug"`
	Name         string  `json:"name"`
	NameEn       *string `json:"name_en,omitempty"`
	Category     string  `json:"category"`
	ImageURL     *string `json:"image_url,omitempty"`
	Visibility   string  `json:"visibility"`
	Manufacturer *string `json:"manufacturer,omitempty"`
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
	Limit         int
	Offset        int
	Status        string
	Category      string
	PublishedOnly bool
}

func validProductCategory(category string) bool {
	switch category {
	case "beer", "wine", "whisky", "sake", "shochu", "vodka", "gin", "rum", "tequila", "brandy", "liqueur", "other":
		return true
	default:
		return false
	}
}

const (
	maxDepthMakers     = 3
	maxDepthNextDrinks = 3
	minMakerDrank      = 2
)

// DrankDrink is one published unique drink_id in the drank union.
type DrankDrink struct {
	DrinkID      string
	Category     string
	Manufacturer string
}

type CategoryTotal struct {
	Category string
	Total    int
}

type DepthNextDrink struct {
	Slug string `json:"slug"`
	Name string `json:"name"`
}

type DepthSpecialty struct {
	Category string `json:"category"`
	Drank    int    `json:"drank"`
	Total    int    `json:"total"`
}

type DepthMaker struct {
	Manufacturer string           `json:"manufacturer"`
	Drank        int              `json:"drank"`
	NextDrinks   []DepthNextDrink `json:"next_drinks"`
}

// ListDepth is the personal fill map for /list. Not a title ladder.
type ListDepth struct {
	Specialty  *DepthSpecialty  `json:"specialty"`
	Categories []DepthSpecialty `json:"categories"`
	Makers     []DepthMaker     `json:"makers"`
	MakerScope string           `json:"maker_scope"`
}
