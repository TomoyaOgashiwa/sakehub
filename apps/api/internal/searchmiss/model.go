package searchmiss

import (
	"errors"
	"regexp"
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

// clientHashPattern は crypto.randomUUID() が生成する標準 UUID 形式のみを受理する。
// 低エントロピーな自由形式の文字列を許すと、client_hash を回転させて
// unique_searchers を水増しできてしまうため、形式を固定して真正性を担保する。
var clientHashPattern = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`)

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
