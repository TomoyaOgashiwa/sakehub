package drinklog

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"time"

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

// AuthRoutes registers authenticated drink-log routes.
// Mounted at /api/auth/drink-logs
func (h *Handler) AuthRoutes(r chi.Router) {
	r.Get("/", h.List)
	r.Get("/summary", h.Summary)
	r.Put("/day", h.ReplaceDay)
	r.Post("/", h.CreateBatch)
	r.Get("/{id}", h.Get)
	r.Patch("/{id}", h.Update)
	r.Delete("/{id}", h.Delete)
}

func (h *Handler) CreateBatch(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var input CreateBatchInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid json")
		return
	}
	defer r.Body.Close()

	logs, err := h.svc.CreateBatch(r.Context(), input, userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	response.JSON(w, http.StatusCreated, map[string]any{"data": logs})
}

func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	params := ListParams{
		Limit:  50,
		Offset: 0,
	}
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
	from, err := parseOptionalTime(r.URL.Query().Get("from"))
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid from")
		return
	}
	to, err := parseOptionalTime(r.URL.Query().Get("to"))
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid to")
		return
	}
	params.From = from
	params.To = to

	logs, err := h.svc.List(r.Context(), userID, params)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	response.JSON(w, http.StatusOK, map[string]any{"data": logs})
}

func (h *Handler) Summary(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	fromRaw := r.URL.Query().Get("from")
	toRaw := r.URL.Query().Get("to")
	if fromRaw == "" || toRaw == "" {
		response.Error(w, http.StatusBadRequest, "from and to are required")
		return
	}

	from, err := time.Parse(time.RFC3339, fromRaw)
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid from")
		return
	}
	to, err := time.Parse(time.RFC3339, toRaw)
	if err != nil {
		response.Error(w, http.StatusBadRequest, "invalid to")
		return
	}

	summary, err := h.svc.Summary(r.Context(), userID, from, to)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	response.JSON(w, http.StatusOK, summary)
}

func (h *Handler) ReplaceDay(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var input ReplaceDayInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid json")
		return
	}
	defer r.Body.Close()

	logs, err := h.svc.ReplaceDay(r.Context(), userID, input)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	response.JSON(w, http.StatusOK, map[string]any{"data": logs})
}

func (h *Handler) Get(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	id := chi.URLParam(r, "id")
	log, err := h.svc.GetByID(r.Context(), id, userID)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	response.JSON(w, http.StatusOK, log)
}

func (h *Handler) Update(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var input UpdateInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid json")
		return
	}
	defer r.Body.Close()

	id := chi.URLParam(r, "id")
	log, err := h.svc.Update(r.Context(), id, userID, input)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	response.JSON(w, http.StatusOK, log)
}

func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	id := chi.URLParam(r, "id")
	if err := h.svc.Delete(r.Context(), id, userID); err != nil {
		writeServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func parseOptionalTime(raw string) (*time.Time, error) {
	if raw == "" {
		return nil, nil
	}
	t, err := time.Parse(time.RFC3339, raw)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrValidation):
		response.Error(w, http.StatusBadRequest, err.Error())
	case errors.Is(err, ErrConflict):
		response.Error(w, http.StatusConflict, err.Error())
	case errors.Is(err, ErrDrinkNotFound):
		response.Error(w, http.StatusNotFound, "drink not found")
	case errors.Is(err, ErrNotFound):
		response.Error(w, http.StatusNotFound, "drink log not found")
	case errors.Is(err, ErrForbidden):
		response.Error(w, http.StatusForbidden, "not allowed")
	default:
		response.Error(w, http.StatusInternalServerError, "internal server error")
	}
}
