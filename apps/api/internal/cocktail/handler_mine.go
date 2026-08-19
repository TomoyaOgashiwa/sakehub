package cocktail

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/sakehub/api/internal/middleware"
	"github.com/sakehub/api/pkg/response"
)

// GetOwnedRecipe returns the authenticated owner's draft or published recipe.
// GET /api/auth/cocktail-recipes/{id}
func (h *Handler) GetOwnedRecipe(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	recipe, err := h.svc.GetOwnedRecipe(r.Context(), userID, chi.URLParam(r, "id"))
	if err != nil {
		writeOwnedRecipeError(w, err, "invalid recipe id")
		return
	}

	response.JSON(w, http.StatusOK, recipe)
}

// PatchOwnedRecipe applies a field-mask PATCH. Body is passed as a raw key set
// so omit vs null stays distinguishable (struct Decode would collapse both).
// PATCH /api/auth/cocktail-recipes/{id}
func (h *Handler) PatchOwnedRecipe(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	defer r.Body.Close()

	var raw map[string]json.RawMessage
	if err := json.NewDecoder(r.Body).Decode(&raw); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid json")
		return
	}
	if raw == nil {
		raw = map[string]json.RawMessage{}
	}

	recipe, err := h.svc.PatchOwnedRecipe(r.Context(), userID, chi.URLParam(r, "id"), raw)
	if err != nil {
		writeOwnedRecipeError(w, err, "invalid recipe id")
		return
	}

	response.JSON(w, http.StatusOK, recipe)
}

// DeleteOwnedDraft deletes the authenticated owner's draft. Published rows 400.
// DELETE /api/auth/cocktail-recipes/{id}
func (h *Handler) DeleteOwnedDraft(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	if err := h.svc.DeleteOwnedDraft(r.Context(), userID, chi.URLParam(r, "id")); err != nil {
		writeOwnedRecipeError(w, err, "invalid recipe id")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func writeOwnedRecipeError(w http.ResponseWriter, err error, invalidIDMessage string) {
	if errors.Is(err, ErrNotFound) {
		response.Error(w, http.StatusNotFound, "cocktail recipe not found")
		return
	}
	if errors.Is(err, ErrInvalidUUID) {
		response.Error(w, http.StatusBadRequest, invalidIDMessage)
		return
	}
	if errors.Is(err, ErrValidation) {
		response.Error(w, http.StatusBadRequest, clientValidationMessage(err))
		return
	}
	response.Error(w, http.StatusInternalServerError, "internal server error")
}
