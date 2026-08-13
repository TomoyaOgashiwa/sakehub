package normalize

import (
	"strings"
	"unicode"

	"golang.org/x/text/unicode/norm"
)

// katakanaToHiraganaOffset は全角カタカナ文字とそのひらがな対応文字の
// コードポイント差。例: 'ア' U+30A2 → 'あ' U+3042。
const katakanaToHiraganaOffset = 0x60

const (
	katakanaRangeStart = 0x30A1
	katakanaRangeEnd   = 0x30F6
)

// Query は NFKC・小文字化・カタカナ→ひらがな畳み込みを行い、
// 空白 / 中黒 / 長音記号を除去する。
// search_misses.query_normalized と仮の印の UNIQUE 名に同じ規則を使う。
func Query(raw string) string {
	s := norm.NFKC.String(raw)
	s = strings.ToLower(s)

	var b strings.Builder
	b.Grow(len(s))
	for _, r := range s {
		switch {
		case r == '・' || r == '･' || r == '·':
			continue
		case r == 'ー' || r == 'ｰ':
			continue
		case unicode.IsSpace(r):
			continue
		case r >= katakanaRangeStart && r <= katakanaRangeEnd:
			b.WriteRune(r - katakanaToHiraganaOffset)
		default:
			b.WriteRune(r)
		}
	}
	return b.String()
}
