package cocktail

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/sakehub/api/internal/middleware"
	"github.com/sakehub/api/pkg/response"
)

// clientValidationMessage returns a stable, client-safe validation detail.
func clientValidationMessage(err error) string {
	var ve *ValidationError
	if errors.As(err, &ve) && ve.Detail != "" {
		return ve.Detail
	}
	return "validation error"
}

func parseLimitOffset(r *http.Request, defaultLimit, maxLimit int) (limit, offset int) {
	limit = defaultLimit
	if raw := r.URL.Query().Get("limit"); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil {
			limit = n
		}
	}
	if raw := r.URL.Query().Get("offset"); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil {
			offset = n
		}
	}
	return clampListBounds(limit, offset, defaultLimit, maxLimit)
}

// RatingPublicRoutes registers rating routes that do not require authentication.
// Mounted at /api/public/cocktail-recipe-ratings
func (h *Handler) RatingPublicRoutes(r chi.Router) {
	r.Get("/", h.ListRatingsByRecipe)
}

// RatingAuthRoutes registers rating routes that require authentication.
// Mounted at /api/auth/cocktail-recipe-ratings
func (h *Handler) RatingAuthRoutes(r chi.Router) {
	r.Get("/mine", h.GetMyRating)
	r.Post("/", h.UpsertRating)
	r.Delete("/{id}", h.DeleteRating)
}

// ListRatingsByRecipe returns a page of ratings for a recipe.
// GET /api/public/cocktail-recipe-ratings?recipe_id={uuid}&limit=&offset=
func (h *Handler) ListRatingsByRecipe(w http.ResponseWriter, r *http.Request) {
	recipeID := r.URL.Query().Get("recipe_id")
	if recipeID == "" {
		response.Error(w, http.StatusBadRequest, "recipe_id is required")
		return
	}

	limit, offset := parseLimitOffset(r, DefaultRatingListLimit, MaxRatingListLimit)

	result, err := h.svc.ListRatingsByRecipe(r.Context(), recipeID, limit, offset)
	if err != nil {
		if errors.Is(err, ErrInvalidUUID) {
			response.Error(w, http.StatusBadRequest, "invalid recipe_id")
			return
		}
		if errors.Is(err, ErrNotFound) {
			response.Error(w, http.StatusNotFound, "cocktail recipe not found")
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusOK, result)
}

// GetMyRating returns the authenticated user's rating for a recipe (if any).
// GET /api/auth/cocktail-recipe-ratings/mine?recipe_id={uuid}
func (h *Handler) GetMyRating(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	recipeID := r.URL.Query().Get("recipe_id")
	if recipeID == "" {
		response.Error(w, http.StatusBadRequest, "recipe_id is required")
		return
	}

	rating, err := h.svc.GetRatingByRecipeAndUser(r.Context(), recipeID, userID)
	if err != nil {
		if errors.Is(err, ErrRatingNotFound) {
			response.JSON(w, http.StatusOK, map[string]any{"data": nil})
			return
		}
		if errors.Is(err, ErrInvalidUUID) {
			response.Error(w, http.StatusBadRequest, "invalid recipe_id")
			return
		}
		if errors.Is(err, ErrNotFound) {
			response.Error(w, http.StatusNotFound, "cocktail recipe not found")
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusOK, map[string]any{"data": rating})
}

// UpsertRating creates or updates the authenticated user's rating.
// POST /api/auth/cocktail-recipe-ratings
func (h *Handler) UpsertRating(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var input RatingUpsertInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid json")
		return
	}
	defer r.Body.Close()

	if input.RecipeID == "" {
		response.Error(w, http.StatusBadRequest, "recipe_id is required")
		return
	}

	rating, err := h.svc.UpsertRating(r.Context(), input, userID)
	if err != nil {
		if errors.Is(err, ErrInvalidRating) {
			response.Error(w, http.StatusBadRequest, "rating must be between 1 and 5")
			return
		}
		if errors.Is(err, ErrInvalidUUID) {
			response.Error(w, http.StatusBadRequest, "invalid recipe_id")
			return
		}
		if errors.Is(err, ErrValidation) {
			response.Error(w, http.StatusBadRequest, clientValidationMessage(err))
			return
		}
		if errors.Is(err, ErrNotFound) {
			response.Error(w, http.StatusNotFound, "cocktail recipe not found")
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusOK, rating)
}

// DeleteRating removes the authenticated user's rating.
// DELETE /api/auth/cocktail-recipe-ratings/{id}
func (h *Handler) DeleteRating(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	id := chi.URLParam(r, "id")
	if err := h.svc.DeleteRating(r.Context(), id, userID); err != nil {
		if errors.Is(err, ErrInvalidUUID) {
			response.Error(w, http.StatusBadRequest, "invalid rating id")
			return
		}
		if errors.Is(err, ErrForbidden) {
			response.Error(w, http.StatusForbidden, "not allowed")
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
