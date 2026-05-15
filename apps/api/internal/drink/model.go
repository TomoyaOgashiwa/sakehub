package drink

import "time"

type Drink struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Category  string    `json:"category"`
	ABV       *float64  `json:"abv,omitempty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type CreateInput struct {
	Name     string   `json:"name"`
	Category string   `json:"category"`
	ABV      *float64 `json:"abv,omitempty"`
}
