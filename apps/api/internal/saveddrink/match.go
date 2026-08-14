package saveddrink

import "github.com/sakehub/api/pkg/normalize"

// publishedKeyIndex maps a normalized name/alias to published drinks that own it.
// A drink contributes each distinct non-empty key from its name and aliases only.
func publishedKeyIndex(published []PublishedIdentity) map[string][]PublishedIdentity {
	index := make(map[string][]PublishedIdentity)
	for _, drink := range published {
		seen := make(map[string]struct{})
		add := func(raw string) {
			key := normalize.Query(raw)
			if key == "" {
				return
			}
			if _, ok := seen[key]; ok {
				return
			}
			seen[key] = struct{}{}
			index[key] = append(index[key], drink)
		}
		add(drink.Name)
		for _, alias := range drink.Aliases {
			add(alias)
		}
	}
	return index
}

func uniquePublishedForKey(hits []PublishedIdentity) (PublishedIdentity, []string, bool) {
	if len(hits) == 0 {
		return PublishedIdentity{}, nil, false
	}
	byID := make(map[string]PublishedIdentity, len(hits))
	for _, hit := range hits {
		byID[hit.ID] = hit
	}
	if len(byID) == 1 {
		for _, hit := range byID {
			return hit, nil, true
		}
	}
	slugs := make([]string, 0, len(byID))
	for _, hit := range byID {
		slugs = append(slugs, hit.Slug)
	}
	return PublishedIdentity{}, slugs, false
}
