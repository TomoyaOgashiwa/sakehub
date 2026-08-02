package searchmiss

import (
	"errors"
	"time"
)

var (
	ErrValidation = errors.New("validation error")
	ErrSkip       = errors.New("search miss skipped")
)

const (
	MinNormalizedLen = 2
	MaxNormalizedLen = 40
	MaxRawLen        = 200
)

var validScopes = map[string]bool{
	"cocktail":   true,
	"drink":      true,
	"ingredient": true,
}

type Miss struct {
	ID              string    `json:"id"`
	Scope           string    `json:"scope"`
	QueryRaw        string    `json:"query_raw"`
	QueryNormalized string    `json:"query_normalized"`
	ResultCount     int       `json:"result_count"`
	UserID          *string   `json:"user_id,omitempty"`
	ClientHash      *string   `json:"client_hash,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
}

type CreateInput struct {
	Scope       string  `json:"scope"`
	QueryRaw    string  `json:"query_raw"`
	ResultCount int     `json:"result_count"`
	ClientHash  *string `json:"client_hash,omitempty"`
}
