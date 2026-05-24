package review

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/sakehub/api/internal/middleware"
	"github.com/sakehub/api/pkg/response"
)

// AuthRoutes registers routes that require authentication.
// Mounted at /api/auth/reviews
func (h *Handler) AuthRoutes(r chi.Router) {
	r.Get("/mine", h.GetMine)
	r.Post("/", h.Upsert)
	r.Delete("/{id}", h.Delete)
}

// GetMine returns the authenticated user's review for a drink (if any).
// GET /api/auth/reviews/mine?drink_id={uuid}
func (h *Handler) GetMine(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	drinkID := r.URL.Query().Get("drink_id")
	if drinkID == "" {
		response.Error(w, http.StatusBadRequest, "drink_id is required")
		return
	}

	rev, err := h.svc.GetByDrinkAndUser(r.Context(), drinkID, userID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			response.JSON(w, http.StatusOK, map[string]any{"data": nil})
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusOK, map[string]any{"data": rev})
}

// Upsert creates or updates the authenticated user's review.
// POST /api/auth/reviews
func (h *Handler) Upsert(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var input UpsertInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid json")
		return
	}
	defer r.Body.Close()

	if input.DrinkID == "" {
		response.Error(w, http.StatusBadRequest, "drink_id is required")
		return
	}

	rev, err := h.svc.Upsert(r.Context(), input, userID)
	if err != nil {
		if errors.Is(err, ErrInvalidRating) {
			response.Error(w, http.StatusBadRequest, err.Error())
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusOK, rev)
}

// Delete removes the authenticated user's review.
// DELETE /api/auth/reviews/{id}
func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	id := chi.URLParam(r, "id")
	if err := h.svc.Delete(r.Context(), id, userID); err != nil {
		if errors.Is(err, ErrForbidden) {
			response.Error(w, http.StatusForbidden, "not allowed")
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
