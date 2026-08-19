package cocktail

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
)

// allowedDraftPatchKeys is the field mask for draft PATCH. Unknown keys and
// is_official are rejected rather than silently ignored.
var allowedDraftPatchKeys = map[string]struct{}{
	"cocktail_id": {},
	"name":        {},
	"status":      {},
	"ingredients": {},
	"steps":       {},
	"image_url":   {},
	"memo":        {},
}

// allowedPublishedPatchKeys is the appearance-only mask. Body keys that are
// valid on draft (ingredients / steps / cocktail_id / status) are 400 here so
// a stale full form cannot silently leave the recipe body unchanged.
var allowedPublishedPatchKeys = map[string]struct{}{
	"name":      {},
	"image_url": {},
	"memo":      {},
}

func (s *Service) GetOwnedRecipe(ctx context.Context, userID, id string) (*Recipe, error) {
	if !isUUID(id) {
		return nil, ErrInvalidUUID
	}

	recipe, err := s.repo.FindOwnedRecipeByID(ctx, id, userID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return nil, err
		}
		return nil, fmt.Errorf("cocktail.GetOwnedRecipe: %w", err)
	}
	return recipe, nil
}

func (s *Service) PatchOwnedRecipe(ctx context.Context, userID, id string, raw map[string]json.RawMessage) (*Recipe, error) {
	if !isUUID(id) {
		return nil, ErrInvalidUUID
	}
	if err := validatePatchKeys(raw); err != nil {
		return nil, err
	}

	current, err := s.repo.FindOwnedRecipeByID(ctx, id, userID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return nil, err
		}
		return nil, fmt.Errorf("cocktail.PatchOwnedRecipe: %w", err)
	}

	if current.Status == "published" {
		if err := validatePublishedPatchKeys(raw); err != nil {
			return nil, err
		}
		input, err := parsePublishedMeta(raw, current)
		if err != nil {
			return nil, err
		}
		recipe, err := s.repo.UpdatePublishedMeta(ctx, id, userID, input)
		if err != nil {
			if errors.Is(err, ErrValidation) || errors.Is(err, ErrNotFound) {
				return nil, err
			}
			return nil, fmt.Errorf("cocktail.PatchOwnedRecipe: %w", err)
		}
		return recipe, nil
	}

	input, err := parseDraftPatch(raw, current)
	if err != nil {
		return nil, err
	}
	if err := validate(input.asCreateInput()); err != nil {
		return nil, err
	}

	recipe, err := s.repo.UpdateDraft(ctx, id, userID, input)
	if err != nil {
		if errors.Is(err, ErrValidation) || errors.Is(err, ErrNotFound) {
			return nil, err
		}
		return nil, fmt.Errorf("cocktail.PatchOwnedRecipe: %w", err)
	}
	return recipe, nil
}

func (s *Service) DeleteOwnedDraft(ctx context.Context, userID, id string) error {
	if !isUUID(id) {
		return ErrInvalidUUID
	}

	if err := s.repo.DeleteDraft(ctx, id, userID); err != nil {
		if errors.Is(err, ErrValidation) || errors.Is(err, ErrNotFound) {
			return err
		}
		return fmt.Errorf("cocktail.DeleteOwnedDraft: %w", err)
	}
	return nil
}

func validatePatchKeys(raw map[string]json.RawMessage) error {
	if _, ok := raw["is_official"]; ok {
		return validationErrorf("%s", msgIsOfficialForbidden)
	}
	for key := range raw {
		if _, ok := allowedDraftPatchKeys[key]; !ok {
			return validationErrorf("unknown field: %s", key)
		}
	}
	return nil
}

func validatePublishedPatchKeys(raw map[string]json.RawMessage) error {
	for key := range raw {
		if _, ok := allowedPublishedPatchKeys[key]; !ok {
			return validationErrorf("%s", msgPublishedMetaOnly)
		}
	}
	return nil
}

func parsePublishedMeta(raw map[string]json.RawMessage, current *Recipe) (PublishedMetaInput, error) {
	input := PublishedMetaInput{
		Name:     current.Name,
		Memo:     current.Memo,
		ImageURL: current.ImageURL,
	}

	if err := unmarshalStringField(raw, "name", &input.Name); err != nil {
		return PublishedMetaInput{}, err
	}
	name := strings.TrimSpace(input.Name)
	if name == "" {
		return PublishedMetaInput{}, validationErrorf("name is required")
	}
	if len([]rune(name)) > 100 {
		return PublishedMetaInput{}, validationErrorf("name must be 100 characters or fewer")
	}
	input.Name = name

	if err := unmarshalNullableString(raw, "image_url", &input.ImageURL); err != nil {
		return PublishedMetaInput{}, err
	}
	if err := unmarshalNullableString(raw, "memo", &input.Memo); err != nil {
		return PublishedMetaInput{}, err
	}
	if input.Memo != nil && len([]rune(*input.Memo)) > 1000 {
		return PublishedMetaInput{}, validationErrorf("memo must be 1000 characters or fewer")
	}

	return input, nil
}

func parseDraftPatch(raw map[string]json.RawMessage, current *Recipe) (DraftUpdateInput, error) {
	input := DraftUpdateInput{
		Status:      "draft",
		Ingredients: []IngredientInput{},
		Steps:       []StepInput{},
		Memo:        current.Memo,
		ImageURL:    current.ImageURL,
	}

	if err := unmarshalStringField(raw, "cocktail_id", &input.CocktailID); err != nil {
		return DraftUpdateInput{}, err
	}
	if err := unmarshalStringField(raw, "name", &input.Name); err != nil {
		return DraftUpdateInput{}, err
	}

	if rawStatus, ok := raw["status"]; ok {
		var status string
		if err := json.Unmarshal(rawStatus, &status); err != nil {
			return DraftUpdateInput{}, validationErrorf("status must be a string")
		}
		if strings.TrimSpace(status) != "" {
			input.Status = status
		}
	}

	if rawIngs, ok := raw["ingredients"]; ok {
		ings, err := unmarshalIngredientArray(rawIngs)
		if err != nil {
			return DraftUpdateInput{}, err
		}
		input.Ingredients = ings
	}
	if rawSteps, ok := raw["steps"]; ok {
		steps, err := unmarshalStepArray(rawSteps)
		if err != nil {
			return DraftUpdateInput{}, err
		}
		input.Steps = steps
	}

	if err := unmarshalNullableString(raw, "image_url", &input.ImageURL); err != nil {
		return DraftUpdateInput{}, err
	}
	if err := unmarshalNullableString(raw, "memo", &input.Memo); err != nil {
		return DraftUpdateInput{}, err
	}

	return input, nil
}

func unmarshalStringField(raw map[string]json.RawMessage, key string, dest *string) error {
	payload, ok := raw[key]
	if !ok {
		return nil
	}
	if isJSONNull(payload) {
		return validationErrorf("%s must be a string", key)
	}
	if err := json.Unmarshal(payload, dest); err != nil {
		return validationErrorf("%s must be a string", key)
	}
	return nil
}

func unmarshalNullableString(raw map[string]json.RawMessage, key string, dest **string) error {
	payload, ok := raw[key]
	if !ok {
		return nil
	}
	if isJSONNull(payload) {
		*dest = nil
		return nil
	}
	var s string
	if err := json.Unmarshal(payload, &s); err != nil {
		return validationErrorf("%s must be a string or null", key)
	}
	*dest = &s
	return nil
}

func unmarshalIngredientArray(raw json.RawMessage) ([]IngredientInput, error) {
	if isJSONNull(raw) {
		return []IngredientInput{}, nil
	}
	var ings []IngredientInput
	if err := json.Unmarshal(raw, &ings); err != nil {
		return nil, validationErrorf("ingredients must be an array")
	}
	if ings == nil {
		return []IngredientInput{}, nil
	}
	return ings, nil
}

func unmarshalStepArray(raw json.RawMessage) ([]StepInput, error) {
	if isJSONNull(raw) {
		return []StepInput{}, nil
	}
	var steps []StepInput
	if err := json.Unmarshal(raw, &steps); err != nil {
		return nil, validationErrorf("steps must be an array")
	}
	if steps == nil {
		return []StepInput{}, nil
	}
	return steps, nil
}

func isJSONNull(raw json.RawMessage) bool {
	return bytes.Equal(bytes.TrimSpace(raw), []byte("null"))
}
