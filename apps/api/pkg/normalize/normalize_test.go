package normalize

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func fixturePath(t *testing.T) string {
	t.Helper()
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

func TestQuery(t *testing.T) {
	t.Parallel()

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

	for _, tc := range fx.Cases {
		got := Query(tc.In)
		if got != tc.Want {
			t.Errorf("Query(%q) = %q, want %q", tc.In, got, tc.Want)
		}
	}
}
