package searchmiss

import "testing"

func TestNormalizeQuery(t *testing.T) {
	t.Parallel()

	cases := []struct {
		in   string
		want string
	}{
		{"Gin Tonic", "gintonic"},
		{"ジン・トニック", "じんとにっく"},
		{"　モヒート　", "もひと"},
		{"ＡＢＣ", "abc"}, // NFKC 全角ラテン文字
		{"Whisky", "whisky"},

		// カタカナ → ひらがな畳み込み（表記ゆれの吸収）
		{"ダッサイ", "だっさい"},
		{"だっさい", "だっさい"},
		{"獺祭", "獺祭"}, // 漢字はそのまま（別途 aliases で吸収する想定）

		// 長音記号「ー」の除去（半角ｰも含む）
		{"ウイスキー", "ういすき"},
		{"ｳｲｽｷｰ", "ういすき"},

		// 濁点/半濁点付きカタカナも 1:1 で畳み込まれる
		{"ヴィンテージ", "ゔぃんてじ"},
	}

	for _, tc := range cases {
		got := NormalizeQuery(tc.in)
		if got != tc.want {
			t.Fatalf("NormalizeQuery(%q) = %q, want %q", tc.in, got, tc.want)
		}
	}
}
