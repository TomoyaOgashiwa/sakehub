package drinklog

import "time"

type VolumeUnit string

const (
	UnitML VolumeUnit = "ml"
	UnitOZ VolumeUnit = "oz"
)

type VolumePrecision string

const (
	PrecisionExact     VolumePrecision = "exact"
	PrecisionEstimated VolumePrecision = "estimated"
)

// DrinkSummary is the catalog slice embedded on list responses.
type DrinkSummary struct {
	ID       string   `json:"id"`
	Slug     string   `json:"slug"`
	Name     string   `json:"name"`
	Category string   `json:"category"`
	ABV      *float64 `json:"abv,omitempty"`
}

// Log is a personal drinking volume record.
type Log struct {
	ID              string          `json:"id"`
	UserID          string          `json:"user_id"`
	DrinkID         *string         `json:"drink_id,omitempty"`
	CustomDrinkName *string         `json:"custom_drink_name,omitempty"`
	DrankAt         time.Time       `json:"drank_at"`
	VolumeML        float64         `json:"volume_ml"`
	InputUnit       VolumeUnit      `json:"input_unit"`
	InputValue      float64         `json:"input_value"`
	ServingKey      *string         `json:"serving_key,omitempty"`
	VolumePrecision VolumePrecision `json:"volume_precision"`
	PlaceName       *string         `json:"place_name,omitempty"`
	PlaceURL        *string         `json:"place_url,omitempty"`
	CreatedAt       time.Time       `json:"created_at"`
	UpdatedAt       time.Time       `json:"updated_at"`
	Drink           *DrinkSummary   `json:"drink,omitempty"`
}

// CreateItemInput is one drink line inside a batch create.
type CreateItemInput struct {
	DrinkID         *string         `json:"drink_id,omitempty"`
	CustomDrinkName *string         `json:"custom_drink_name,omitempty"`
	InputUnit       VolumeUnit      `json:"input_unit"`
	InputValue      float64         `json:"input_value"`
	ServingKey      *string         `json:"serving_key,omitempty"`
	VolumePrecision VolumePrecision `json:"volume_precision"`
}

// CreateBatchInput creates one or more logs that share drank_at / place.
type CreateBatchInput struct {
	DrankAt   *time.Time        `json:"drank_at,omitempty"`
	PlaceName *string           `json:"place_name,omitempty"`
	PlaceURL  *string           `json:"place_url,omitempty"`
	Items     []CreateItemInput `json:"items"`
}

// Summary is a period aggregate for pure alcohol intake.
type Summary struct {
	From              time.Time `json:"from"`
	To                time.Time `json:"to"`
	LogCount          int       `json:"log_count"`
	PureAlcoholGrams  float64   `json:"pure_alcohol_grams"`
	SkippedMissingABV int       `json:"skipped_missing_abv"`
}

// ListParams controls pagination and optional date filters.
type ListParams struct {
	Limit  int
	Offset int
	From   *time.Time
	To     *time.Time
}
