package drink

import "testing"

func TestParseSort(t *testing.T) {
	t.Parallel()

	cases := []struct {
		name string
		raw  string
		want string
	}{
		{name: "empty", raw: "", want: SortNewest},
		{name: "newest", raw: "newest", want: SortNewest},
		{name: "abv_desc", raw: "abv_desc", want: SortAbvDesc},
		{name: "abv_asc", raw: "abv_asc", want: SortAbvAsc},
		{name: "unknown", raw: "nope", want: SortNewest},
		{name: "wrong_case", raw: "ABV_DESC", want: SortNewest},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			if got := ParseSort(tc.raw); got != tc.want {
				t.Fatalf("ParseSort(%q) = %q, want %q", tc.raw, got, tc.want)
			}
		})
	}
}

func TestListOrderByWhitelist(t *testing.T) {
	t.Parallel()

	cases := []struct {
		name string
		sort string
		want string
	}{
		{name: "newest", sort: SortNewest, want: "ORDER BY created_at DESC, id DESC"},
		{name: "empty", sort: "", want: "ORDER BY created_at DESC, id DESC"},
		{name: "unknown", sort: "nope", want: "ORDER BY created_at DESC, id DESC"},
		{name: "abv_desc", sort: SortAbvDesc, want: "ORDER BY abv DESC NULLS LAST, created_at DESC, id DESC"},
		{name: "abv_asc", sort: SortAbvAsc, want: "ORDER BY abv ASC NULLS LAST, created_at DESC, id DESC"},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			if got := listOrderBy(tc.sort); got != tc.want {
				t.Fatalf("listOrderBy(%q) = %q, want %q", tc.sort, got, tc.want)
			}
		})
	}
}
