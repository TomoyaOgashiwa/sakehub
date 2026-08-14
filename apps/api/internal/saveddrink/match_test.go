package saveddrink

import (
	"slices"
	"testing"
)

func TestPublishedKeyIndexExactName(t *testing.T) {
	t.Parallel()
	index := publishedKeyIndex([]PublishedIdentity{{
		ID:   "pub-1",
		Slug: "zh-unlisted-label",
		Name: "禅人未登録ラベル",
	}})
	got, slugs, ok := uniquePublishedForKey(index["禅人未登録らべる"])
	if !ok || got.ID != "pub-1" {
		t.Fatalf("got %+v slugs %v ok %v", got, slugs, ok)
	}
}

func TestCoarseDassaiDoesNotMatchExpression(t *testing.T) {
	t.Parallel()
	index := publishedKeyIndex([]PublishedIdentity{{
		ID:   "d45",
		Slug: "dassai-45",
		Name: "獺祭 純米大吟醸 磨き四割五分",
		Aliases: []string{
			"だっさい45",
			"だっさいよんわりごぶ",
		},
	}})
	if _, _, ok := uniquePublishedForKey(index["獺祭"]); ok {
		t.Fatal("coarse 獺祭 must not match 獺祭 純米大吟醸45")
	}
	if _, _, ok := uniquePublishedForKey(index["だっさい"]); ok {
		t.Fatal("だっさい must not match dassai-45 aliases")
	}
}

func TestAliasExactMatch(t *testing.T) {
	t.Parallel()
	index := publishedKeyIndex([]PublishedIdentity{{
		ID:   "d23",
		Slug: "dassai-23",
		Name: "獺祭 純米大吟醸 磨き二割三分",
		Aliases: []string{
			"だっさい",
			"だっさい23",
		},
	}})
	got, _, ok := uniquePublishedForKey(index["だっさい"])
	if !ok || got.ID != "d23" {
		t.Fatalf("alias だっさい should match dassai-23, got %+v ok %v", got, ok)
	}
}

func TestAmbiguousSharedAliasIsSkipped(t *testing.T) {
	t.Parallel()
	index := publishedKeyIndex([]PublishedIdentity{
		{ID: "a", Slug: "sku-a", Name: "Sku A", Aliases: []string{"共有名"}},
		{ID: "b", Slug: "sku-b", Name: "Sku B", Aliases: []string{"共有名"}},
	})
	_, slugs, ok := uniquePublishedForKey(index["共有名"])
	if ok {
		t.Fatal("shared alias must be ambiguous")
	}
	if !slices.Contains(slugs, "sku-a") || !slices.Contains(slugs, "sku-b") {
		t.Fatalf("ambiguous slugs %v", slugs)
	}
}

func TestNameEnIsNotAMatchKey(t *testing.T) {
	t.Parallel()
	index := publishedKeyIndex([]PublishedIdentity{{
		ID:   "d23",
		Slug: "dassai-23",
		Name: "獺祭 純米大吟醸 磨き二割三分",
	}})
	if _, _, ok := uniquePublishedForKey(index["dassai23junmaidaiginjo"]); ok {
		t.Fatal("name_en must not be a merge key")
	}
}

func TestDuplicateAliasOnSameDrinkIsOneKey(t *testing.T) {
	t.Parallel()
	index := publishedKeyIndex([]PublishedIdentity{{
		ID:      "one",
		Slug:    "one",
		Name:    "Example",
		Aliases: []string{"Example", "EXAMPLE"},
	}})
	got, slugs, ok := uniquePublishedForKey(index["example"])
	if !ok || got.ID != "one" || slugs != nil {
		t.Fatalf("got %+v slugs %v ok %v", got, slugs, ok)
	}
}
