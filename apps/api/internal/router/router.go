package router

import (
	"database/sql"

	keyfunc "github.com/MicahParks/keyfunc/v3"
	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"go.uber.org/zap"

	"github.com/sakehub/api/internal/cocktail"
	"github.com/sakehub/api/internal/drink"
	"github.com/sakehub/api/internal/handler"
	"github.com/sakehub/api/internal/middleware"
	"github.com/sakehub/api/internal/review"
	"github.com/sakehub/api/internal/user"
	"github.com/sakehub/api/pkg/config"
)

func New(logger *zap.Logger, db *sql.DB, cfg *config.Config, kf keyfunc.Keyfunc) *chi.Mux {
	r := chi.NewRouter()

	r.Use(chimw.RequestID)
	r.Use(chimw.RealIP)
	r.Use(chimw.Recoverer)
	r.Use(chimw.Heartbeat("/ping"))

	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:3000", "http://localhost:8081"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	userH := user.NewHandler(user.NewService(user.NewRepository(db)))
	drinkH := drink.NewHandler(drink.NewService(drink.NewRepository(db)))
	cocktailH := cocktail.NewHandler(cocktail.NewService(cocktail.NewRepository(db)))
	reviewH := review.NewHandler(review.NewService(review.NewRepository(db)))

	r.Route("/api", func(r chi.Router) {
		r.Get("/health", handler.Health)
		r.Route("/drinks", drinkH.Routes)
		r.Route("/cocktails", cocktailH.CocktailRoutes)

		r.Route("/cocktail-recipes", func(r chi.Router) {
			r.Group(func(r chi.Router) {
				r.Use(middleware.RequireAuth(kf))
				cocktailH.AuthRecipeRoutes(r)
			})
			cocktailH.PublicRecipeRoutes(r)
		})

		r.Route("/public", func(r chi.Router) {
			r.Route("/reviews", reviewH.PublicRoutes)
			r.Route("/cocktail-recipe-ratings", cocktailH.RatingPublicRoutes)
		})

		r.Route("/auth", func(r chi.Router) {
			r.Use(middleware.RequireAuth(kf))
			r.Route("/reviews", reviewH.AuthRoutes)
			r.Route("/cocktail-recipe-ratings", cocktailH.RatingAuthRoutes)
		})

		r.Group(func(r chi.Router) {
			r.Use(middleware.RequireAuth(kf))
			r.Route("/users", userH.Routes)
		})
	})

	return r
}
