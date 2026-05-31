package middleware

import (
	"context"
	"net/http"
	"strings"

	keyfunc "github.com/MicahParks/keyfunc/v3"
	"github.com/golang-jwt/jwt/v5"
	"github.com/sakehub/api/pkg/response"
)

type ctxKey string

const (
	CtxUserID ctxKey = "user_id"
	CtxRole   ctxKey = "role"
)

func RequireAuth(kf keyfunc.Keyfunc) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			h := r.Header.Get("Authorization")
			raw := strings.TrimPrefix(h, "Bearer ")
			if raw == "" || raw == h {
				response.Error(w, http.StatusUnauthorized, "missing bearer token")
				return
			}

			token, err := jwt.Parse(raw, kf.Keyfunc,
				jwt.WithValidMethods([]string{"ES256", "RS256"}),
				jwt.WithExpirationRequired(),
			)
			if err != nil || !token.Valid {
				response.Error(w, http.StatusUnauthorized, "invalid token")
				return
			}

			claims, ok := token.Claims.(jwt.MapClaims)
			if !ok {
				response.Error(w, http.StatusUnauthorized, "invalid claims")
				return
			}

			ctx := r.Context()
			if sub, ok := claims["sub"].(string); ok {
				ctx = context.WithValue(ctx, CtxUserID, sub)
			}
			if role, ok := claims["role"].(string); ok {
				ctx = context.WithValue(ctx, CtxRole, role)
			}
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func UserID(ctx context.Context) string {
	if v, ok := ctx.Value(CtxUserID).(string); ok {
		return v
	}
	return ""
}
