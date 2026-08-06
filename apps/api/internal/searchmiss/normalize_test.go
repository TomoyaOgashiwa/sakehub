package searchmiss

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

// fixturePath resolves the shared normalize contract-test fixture. Both this
// Go test and packages/drink-seed/src/normalize.check.ts assert against the
// same cases, so the two intentionally-duplicated implementations
// (NormalizeQuery here and normalizeJa in TS) can't silently drift.
func fixturePath(t *testing.T) string {
	t.Helper()
	// apps/api/internal/searchmiss -> repo root
	path, err := filepath.Abs(filepath.Join("..", "..", "..", "..", "testdata", "normalize-cases.json"))
	if err != nil {
		t.Fatalf("resolve fixture path: %v", err)
	}
	return path
}

type normalizeFixture struct {
	Cases []struct {
		In   string `json:"in"`
		Want string `json:"want"`
	} `json:"cases"`
}

func loadNormalizeFixture(t *testing.T) normalizeFixture {
	t.Helper()

	data, err := os.ReadFile(fixturePath(t))
	if err != nil {
		t.Fatalf("read fixture: %v", err)
	}

	var fx normalizeFixture
	if err := json.Unmarshal(data, &fx); err != nil {
		t.Fatalf("parse fixture: %v", err)
	}
	if len(fx.Cases) == 0 {
		t.Fatal("fixture has no cases")
	}
	return fx
}

func TestNormalizeQuery(t *testing.T) {
	t.Parallel()

	fx := loadNormalizeFixture(t)
	for _, tc := range fx.Cases {
		got := NormalizeQuery(tc.In)
		if got != tc.Want {
			t.Errorf("NormalizeQuery(%q) = %q, want %q", tc.In, got, tc.Want)
		}
	}
}
