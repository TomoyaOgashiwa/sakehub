package searchmiss

import "testing"

func TestNormalizeQuery(t *testing.T) {
	t.Parallel()

	cases := []struct {
		in   string
		want string
	}{
		{"Gin Tonic", "gintonic"},
		{"ジン・トニック", "ジントニック"},
		{"　モヒート　", "モヒート"},
		{"ＡＢＣ", "abc"}, // NFKC full-width latin
		{"Whisky", "whisky"},
	}

	for _, tc := range cases {
		got := NormalizeQuery(tc.in)
		if got != tc.want {
			t.Fatalf("NormalizeQuery(%q) = %q, want %q", tc.in, got, tc.want)
		}
	}
}
