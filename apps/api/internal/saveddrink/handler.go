package saveddrink

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

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

// AuthRoutes registers authenticated saved-drink routes.
// Mounted at /api/auth/saved-drinks
func (h *Handler) AuthRoutes(r chi.Router) {
	r.Get("/", h.List)
	r.Get("/mine", h.GetMine)
	r.Get("/depth", h.Depth)
	r.Post("/", h.Save)
	r.Post("/provisional", h.SaveProvisional)
	r.Patch("/{drink_id}", h.Patch)
	r.Delete("/{drink_id}", h.Unsave)
}

func (h *Handler) Save(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var input SaveInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid json")
		return
	}
	defer r.Body.Close()

	row, err := h.svc.Save(r.Context(), userID, input)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	response.JSON(w, http.StatusOK, row)
}

func (h *Handler) SaveProvisional(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var input SaveProvisionalInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid json")
		return
	}
	defer r.Body.Close()

	row, err := h.svc.SaveProvisional(r.Context(), userID, input)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	response.JSON(w, http.StatusOK, row)
}

func (h *Handler) Patch(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var input PatchInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid json")
		return
	}
	defer r.Body.Close()

	drinkID := chi.URLParam(r, "drink_id")
	row, err := h.svc.Patch(r.Context(), drinkID, userID, input)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	response.JSON(w, http.StatusOK, row)
}

func (h *Handler) GetMine(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	drinkID := r.URL.Query().Get("drink_id")
	row, err := h.svc.GetMine(r.Context(), drinkID, userID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			response.JSON(w, http.StatusOK, map[string]any{"data": nil})
			return
		}
		writeServiceError(w, err)
		return
	}

	response.JSON(w, http.StatusOK, map[string]any{"data": row})
}

func (h *Handler) Depth(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	depth, err := h.svc.Depth(r.Context(), userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	response.JSON(w, http.StatusOK, map[string]any{"data": depth})
}

func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	params := ListParams{Limit: defaultListLimit, Offset: 0}
	if v := r.URL.Query().Get("limit"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n <= 0 {
			response.Error(w, http.StatusBadRequest, "invalid limit")
			return
		}
		params.Limit = n
	}
	if v := r.URL.Query().Get("offset"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 0 {
			response.Error(w, http.StatusBadRequest, "invalid offset")
			return
		}
		params.Offset = n
	}

	items, err := h.svc.List(r.Context(), userID, params)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	response.JSON(w, http.StatusOK, map[string]any{"data": items})
}

func (h *Handler) Unsave(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	drinkID := chi.URLParam(r, "drink_id")
	if err := h.svc.Unsave(r.Context(), drinkID, userID); err != nil {
		writeServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrValidation):
		response.Error(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, ErrDrinkNotFound):
		response.Error(w, http.StatusNotFound, "drink not found")
	case errors.Is(err, ErrNotFound):
		response.Error(w, http.StatusNotFound, "saved drink not found")
	default:
		response.Error(w, http.StatusInternalServerError, "internal server error")
	}
}
