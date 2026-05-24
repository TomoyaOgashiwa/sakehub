package review

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/sakehub/api/pkg/response"
)

// PublicRoutes registers routes that do not require authentication.
// Mounted at /api/public/reviews
func (h *Handler) PublicRoutes(r chi.Router) {
	r.Get("/", h.ListByDrink)
}

// ListByDrink returns all reviews for a drink.
// GET /api/public/reviews?drink_id={uuid}
func (h *Handler) ListByDrink(w http.ResponseWriter, r *http.Request) {
	drinkID := r.URL.Query().Get("drink_id")
	if drinkID == "" {
		response.Error(w, http.StatusBadRequest, "drink_id is required")
		return
	}

	reviews, err := h.svc.ListByDrink(r.Context(), drinkID)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusOK, map[string]any{"data": reviews})
}
