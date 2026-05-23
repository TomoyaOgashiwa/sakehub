package cocktail

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

func (h *Handler) Routes(r chi.Router) {
	r.Post("/", h.Create)
}

type createRequest struct {
	Name        string            `json:"name"`
	Memo        *string           `json:"memo,omitempty"`
	ImageURL    *string           `json:"image_url,omitempty"`
	Status      string            `json:"status"`
	Ingredients []IngredientInput `json:"ingredients"`
}

func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req createRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.Error(w, http.StatusBadRequest, "invalid json")
		return
	}
	defer r.Body.Close()

	if req.Status == "" {
		req.Status = "draft"
	}

	input := CreateInput{
		UserID:      userID,
		Name:        req.Name,
		Memo:        req.Memo,
		ImageURL:    req.ImageURL,
		Status:      req.Status,
		Ingredients: req.Ingredients,
	}

	recipe, err := h.svc.Create(r.Context(), input)
	if err != nil {
		if errors.Is(err, ErrValidation) {
			response.Error(w, http.StatusBadRequest, err.Error())
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusCreated, recipe)
}
