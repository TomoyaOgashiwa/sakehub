package router

import (
	"database/sql"
	"time"

	keyfunc "github.com/MicahParks/keyfunc/v3"
	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"go.uber.org/zap"
	"golang.org/x/time/rate"

	"github.com/sakehub/api/internal/admin"
	"github.com/sakehub/api/internal/cocktail"
	"github.com/sakehub/api/internal/drink"
	"github.com/sakehub/api/internal/drinklog"
	"github.com/sakehub/api/internal/handler"
	"github.com/sakehub/api/internal/middleware"
	"github.com/sakehub/api/internal/review"
	"github.com/sakehub/api/internal/saveddrink"
	"github.com/sakehub/api/internal/searchmiss"
	"github.com/sakehub/api/internal/user"
	"github.com/sakehub/api/pkg/config"
	"github.com/sakehub/api/pkg/ratelimit"
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

	adminH := admin.NewHandler(admin.NewService(admin.NewRepository(db)))
	userH := user.NewHandler(user.NewService(user.NewRepository(db)))
	drinkH := drink.NewHandler(drink.NewService(drink.NewRepository(db), logger))
	cocktailH := cocktail.NewHandler(cocktail.NewService(cocktail.NewRepository(db)))
	reviewH := review.NewHandler(review.NewService(review.NewRepository(db)))
	drinkLogH := drinklog.NewHandler(drinklog.NewService(drinklog.NewRepository(db)))
	savedDrinkH := saveddrink.NewHandler(saveddrink.NewService(saveddrink.NewRepository(db)))
	searchMissH := searchmiss.NewHandler(searchmiss.NewService(searchmiss.NewRepository(db)))

	// client_hash 回転による unique_searchers 水増しを緩和する目的の
	// IP 単位レート制限。1 req/3s（バースト 10）は確定検索を連続で行う
	// 通常利用は妨げず、スクリプトによる連打だけを弾く想定。
	searchMissLimiter := ratelimit.NewKeyLimiter(rate.Every(3*time.Second), 10, 10*time.Minute)

	r.Route("/api", func(r chi.Router) {
		r.Get("/health", handler.Health)
		r.Route("/drinks", drinkH.Routes)
		r.Route("/cocktails", cocktailH.CocktailRoutes)

		r.Route("/search-misses", func(r chi.Router) {
			r.Use(middleware.OptionalAuth(kf))
			r.Use(searchMissLimiter.Middleware)
			searchMissH.Routes(r)
		})

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
			r.Route("/drink-logs", drinkLogH.AuthRoutes)
			r.Route("/saved-drinks", savedDrinkH.AuthRoutes)
		})

		r.Group(func(r chi.Router) {
			r.Use(middleware.RequireAuth(kf))
			r.Route("/users", userH.Routes)
		})

		r.Route("/admin", func(r chi.Router) {
			r.Use(middleware.RequireAuth(kf))
			adminH.Routes(r)
		})
	})

	return r
}
