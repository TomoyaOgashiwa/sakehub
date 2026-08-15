package admin

import (
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

func (h *Handler) Routes(r chi.Router) {
	r.Use(h.requireAdmin)
	r.Get("/overview", h.Overview)
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
