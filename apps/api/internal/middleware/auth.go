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

			ctx, ok := parseToken(r.Context(), raw, kf)
			if !ok {
				response.Error(w, http.StatusUnauthorized, "invalid token")
				return
			}
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// OptionalAuth extracts user_id/role when a valid Bearer token is present.
// Missing or invalid tokens are ignored so public endpoints stay open.
func OptionalAuth(kf keyfunc.Keyfunc) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			h := r.Header.Get("Authorization")
			raw := strings.TrimPrefix(h, "Bearer ")
			if raw != "" && raw != h {
				if ctx, ok := parseToken(r.Context(), raw, kf); ok {
					r = r.WithContext(ctx)
				}
			}
			next.ServeHTTP(w, r)
		})
	}
}

func parseToken(ctx context.Context, raw string, kf keyfunc.Keyfunc) (context.Context, bool) {
	token, err := jwt.Parse(raw, kf.Keyfunc,
		jwt.WithValidMethods([]string{"ES256", "RS256"}),
		jwt.WithExpirationRequired(),
	)
	if err != nil || !token.Valid {
		return ctx, false
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return ctx, false
	}

	if sub, ok := claims["sub"].(string); ok {
		ctx = context.WithValue(ctx, CtxUserID, sub)
	}
	if role, ok := claims["role"].(string); ok {
		ctx = context.WithValue(ctx, CtxRole, role)
	}
	return ctx, true
}

func UserID(ctx context.Context) string {
	if v, ok := ctx.Value(CtxUserID).(string); ok {
		return v
	}
	return ""
}
