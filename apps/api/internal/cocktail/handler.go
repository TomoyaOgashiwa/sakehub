package cocktail

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

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

// CocktailRoutes registers public routes for the cocktails master.
// Mounted at /api/cocktails
func (h *Handler) CocktailRoutes(r chi.Router) {
	r.Get("/", h.ListCocktails)
	r.Get("/by-slug/{slug}", h.GetCocktailBySlug)
}

// PublicRecipeRoutes registers public recipe routes.
// Mounted at /api/cocktail-recipes
func (h *Handler) PublicRecipeRoutes(r chi.Router) {
	r.Get("/{id}", h.GetRecipe)
}

// AuthRecipeRoutes registers recipe routes that require authentication.
// Mounted at /api/cocktail-recipes (auth group)
func (h *Handler) AuthRecipeRoutes(r chi.Router) {
	r.Post("/", h.Create)
}

// AuthMineRoutes registers the authenticated owner's recipe list.
// Mounted at /api/auth/cocktail-recipes
func (h *Handler) AuthMineRoutes(r chi.Router) {
	r.Get("/mine", h.ListMine)
}

// ListCocktails returns cocktail master records with published recipe counts.
// GET /api/cocktails?q=&base_spirit=&limit=&offset=
// Default sort: recipe_count DESC, name ASC.
func (h *Handler) ListCocktails(w http.ResponseWriter, r *http.Request) {
	limit, offset := parseLimitOffset(r, DefaultCocktailListLimit, MaxCocktailListLimit)

	params := ListParams{
		Query:      strings.TrimSpace(r.URL.Query().Get("q")),
		BaseSpirit: strings.TrimSpace(r.URL.Query().Get("base_spirit")),
		Limit:      limit,
		Offset:     offset,
	}

	cocktails, total, err := h.svc.ListCocktails(r.Context(), params)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusOK, map[string]any{
		"data":   cocktails,
		"total":  total,
		"limit":  params.Limit,
		"offset": params.Offset,
	})
}

// GetCocktailBySlug returns a cocktail master record with a page of published recipes.
// GET /api/cocktails/by-slug/{slug}?limit=&offset=
func (h *Handler) GetCocktailBySlug(w http.ResponseWriter, r *http.Request) {
	slug := chi.URLParam(r, "slug")
	limit, offset := parseLimitOffset(r, DefaultPublishedRecipeLimit, MaxPublishedRecipeLimit)

	detail, err := h.svc.GetCocktailBySlug(r.Context(), slug, limit, offset)
	if err != nil {
		if errors.Is(err, ErrCocktailNotFound) {
			response.Error(w, http.StatusNotFound, "cocktail not found")
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusOK, detail)
}

// ListMine returns the authenticated user's draft + published recipes.
// GET /api/auth/cocktail-recipes/mine?limit=&offset=
func (h *Handler) ListMine(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserID(r.Context())
	if userID == "" {
		response.Error(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	limit, offset := parseLimitOffset(r, DefaultMineRecipeLimit, MaxMineRecipeLimit)

	recipes, total, err := h.svc.ListMine(r.Context(), userID, limit, offset)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusOK, map[string]any{
		"data":   recipes,
		"total":  total,
		"limit":  limit,
		"offset": offset,
	})
}

// GetRecipe returns a published recipe with ingredients and rating aggregates.
// GET /api/cocktail-recipes/{id}
func (h *Handler) GetRecipe(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	recipe, err := h.svc.GetRecipeByID(r.Context(), id)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			response.Error(w, http.StatusNotFound, "cocktail recipe not found")
			return
		}
		if errors.Is(err, ErrInvalidUUID) {
			response.Error(w, http.StatusBadRequest, "invalid recipe id")
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusOK, recipe)
}

type createRequest struct {
	CocktailID  string            `json:"cocktail_id"`
	Name        string            `json:"name"`
	Memo        *string           `json:"memo,omitempty"`
	ImageURL    *string           `json:"image_url,omitempty"`
	Status      string            `json:"status"`
	Ingredients []IngredientInput `json:"ingredients"`
	Steps       []StepInput       `json:"steps"`
}

// Create registers a new recipe owned by the authenticated user.
// POST /api/cocktail-recipes
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
		CocktailID:  req.CocktailID,
		Name:        req.Name,
		Memo:        req.Memo,
		ImageURL:    req.ImageURL,
		Status:      req.Status,
		Ingredients: req.Ingredients,
		Steps:       req.Steps,
	}

	recipe, err := h.svc.Create(r.Context(), input)
	if err != nil {
		if errors.Is(err, ErrValidation) {
			response.Error(w, http.StatusBadRequest, clientValidationMessage(err))
			return
		}
		response.Error(w, http.StatusInternalServerError, "internal server error")
		return
	}

	response.JSON(w, http.StatusCreated, recipe)
}
