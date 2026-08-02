package searchmiss

import (
	"strings"
	"unicode"

	"golang.org/x/text/unicode/norm"
)

// NormalizeQuery applies NFKC, lowercases, and strips spaces / 中黒 variants.
// Used for query_normalized so JP naming variance collapses for ranking.
func NormalizeQuery(raw string) string {
	s := norm.NFKC.String(raw)
	s = strings.ToLower(s)

	var b strings.Builder
	b.Grow(len(s))
	for _, r := range s {
		switch {
		case r == '・' || r == '･' || r == '·':
			continue
		case unicode.IsSpace(r):
			continue
		default:
			b.WriteRune(r)
		}
	}
	return b.String()
}
