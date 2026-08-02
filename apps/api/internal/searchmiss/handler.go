package searchmiss

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/sakehub/api/internal/middleware"
	"github.com/sakehub/api/pkg/response"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// Routes registers public search-miss logging routes.
// Mounted at /api/search-misses (auth optional via OptionalAuth).
func (h *Handler) Routes(r chi.Router) {
	r.Post("/", h.Create)
}

// Create inserts a zero-hit search miss.
// POST /api/search-misses
func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateInput
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid json")
		return
	}
	defer r.Body.Close()

	userID := middleware.UserID(r.Context())

	miss, err := h.svc.Create(r.Context(), req, userID)
	if err != nil {
		if errors.Is(err, ErrSkip) {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		if errors.Is(err, ErrValidation) {
			response.Error(w, http.StatusBadRequest, "validation error")
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusCreated, miss)
}
