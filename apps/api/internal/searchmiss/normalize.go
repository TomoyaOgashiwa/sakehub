package searchmiss

import "github.com/sakehub/api/pkg/normalize"

// NormalizeQuery は pkg/normalize.Query と同じ規則。
// drinklog など既存呼び出し用の薄いラッパ。
func NormalizeQuery(raw string) string {
	return normalize.Query(raw)
}
