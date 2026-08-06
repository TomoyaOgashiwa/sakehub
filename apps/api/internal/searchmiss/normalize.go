package searchmiss

import (
	"strings"
	"unicode"

	"golang.org/x/text/unicode/norm"
)

// katakanaToHiraganaOffset は全角カタカナ文字とそのひらがな対応文字の
// コードポイント差。例: 'ア' U+30A2 → 'あ' U+3042。
const katakanaToHiraganaOffset = 0x60

// katakanaRangeStart/End は上記オフセットでひらがなへ 1:1 対応する
// カタカナ範囲（U+30A1 'ァ' .. U+30F6 'ヶ'）。この範囲外の稀な文字
// （ヷヸヹヺ, U+30F7-30FA）にはひらがな対応がないためそのまま残す。
const (
	katakanaRangeStart = 0x30A1
	katakanaRangeEnd   = 0x30F6
)

// NormalizeQuery は NFKC・小文字化・カタカナ→ひらがな畳み込みを行い、
// 空白 / 中黒 / 長音記号を除去する。
// query_normalized 用で、日本語の表記ゆれをランキング用に畳み込む:
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
