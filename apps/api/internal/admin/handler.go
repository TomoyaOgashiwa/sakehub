package admin

import (
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

func (h *Handler) Routes(r chi.Router) {
	r.Use(h.requireAdmin)
	r.Get("/overview", h.Overview)
	r.Get("/search-misses", h.SearchMisses)
	r.Get("/provisional-drinks", h.ProvisionalDrinks)
}

func (h *Handler) requireAdmin(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID := middleware.UserID(r.Context())
		ok, err := h.svc.IsAdmin(r.Context(), userID)
		if err != nil {
			if errors.Is(err, ErrUnauthorized) {
				response.Error(w, http.StatusUnauthorized, "unauthorized")
				return
			}
			response.Error(w, http.StatusInternalServerError, "internal server error")
			return
		}
		if !ok {
			response.Error(w, http.StatusForbidden, "forbidden")
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (h *Handler) Overview(w http.ResponseWriter, r *http.Request) {
	o, err := h.svc.Overview(r.Context())
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}
	response.JSON(w, http.StatusOK, o)
}

func (h *Handler) SearchMisses(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	limit, offset, err := parseLimitOffset(q.Get("limit"), q.Get("offset"))
	if err != nil {
		response.Error(w, http.StatusBadRequest, err.Error())
		return
	}

	result, err := h.svc.ListSearchMisses(r.Context(), SearchMissListParams{
		Scope:  q.Get("scope"),
		Limit:  limit,
		Offset: offset,
	})
	if err != nil {
		if errors.Is(err, ErrValidation) {
			response.Error(w, http.StatusBadRequest, "validation error")
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}
	response.JSON(w, http.StatusOK, result)
}

func (h *Handler) ProvisionalDrinks(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	limit, offset, err := parseLimitOffset(q.Get("limit"), q.Get("offset"))
	if err != nil {
		response.Error(w, http.StatusBadRequest, err.Error())
		return
	}

	result, err := h.svc.ListProvisionalDrinks(r.Context(), ProvisionalDrinkListParams{
		Limit:  limit,
		Offset: offset,
	})
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}
	response.JSON(w, http.StatusOK, result)
}

func parseLimitOffset(limitRaw, offsetRaw string) (int, int, error) {
	limit := 0
	if limitRaw != "" {
		n, err := strconv.Atoi(limitRaw)
		if err != nil || n <= 0 {
			return 0, 0, errors.New("invalid limit")
		}
		limit = n
	}
	offset := 0
	if offsetRaw != "" {
		n, err := strconv.Atoi(offsetRaw)
		if err != nil || n < 0 {
			return 0, 0, errors.New("invalid offset")
		}
		offset = n
	}
	return limit, offset, nil
}
