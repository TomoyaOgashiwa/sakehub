package review

import "time"

// Review represents a user's star rating and optional comment for a drink.
type Review struct {
	ID        string    `json:"id"`
	DrinkID   string    `json:"drink_id"`
	UserID    string    `json:"user_id"`
	Rating    int       `json:"rating"`
	Comment   string    `json:"comment"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// UpsertInput is used for both create and update operations.
// The handler performs an INSERT ON CONFLICT UPDATE so the client always
// sends the same request regardless of whether a review already exists.
type UpsertInput struct {
	DrinkID string `json:"drink_id"`
	Rating  int    `json:"rating"`
	Comment string `json:"comment"`
}
