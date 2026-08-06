package searchmiss

import (
	"strings"
	"unicode"

	"golang.org/x/text/unicode/norm"
)

// katakanaToHiraganaOffset is the codepoint distance between a (full-width)
// katakana letter and its hiragana counterpart, e.g. 'ア' U+30A2 → 'あ' U+3042.
const katakanaToHiraganaOffset = 0x60

// katakanaRangeStart/End cover the block that maps 1:1 onto hiragana via the
// fixed offset above (U+30A1 'ァ' .. U+30F6 'ヶ'). Rare letters beyond this
// (ヷヸヹヺ, U+30F7-30FA) have no hiragana equivalent and are left as-is.
const (
	katakanaRangeStart = 0x30A1
	katakanaRangeEnd   = 0x30F6
)

// NormalizeQuery applies NFKC, lowercases, folds katakana to hiragana,
// and strips spaces / 中黒 / 長音 variants.
// Used for query_normalized so JP naming variance collapses for ranking:
// 「獺祭」「だっさい」「ダッサイ」「ダッサイー」のような表記ゆれが同じ
// query_normalized に畳み込まれないと search_miss_ranking の需要集計が
// 実際より過小に分散してしまう。
func NormalizeQuery(raw string) string {
	s := norm.NFKC.String(raw)
	s = strings.ToLower(s)

	var b strings.Builder
	b.Grow(len(s))
	for _, r := range s {
		switch {
		case r == '・' || r == '･' || r == '·':
			continue
		case r == 'ー' || r == 'ｰ':
			// 長音記号は仮名の音を伸ばすだけなので除去し、表記ゆれを畳み込む。
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
