// Package ratelimit provides a simple in-memory per-key rate limiter
// middleware. It is intentionally lightweight (no external store) since
// the API currently runs as a single instance; if it is ever scaled
// horizontally, this should move to a shared store (e.g. Redis) so limits
// are enforced across instances.
package ratelimit

import (
	"net"
	"net/http"
	"sync"
	"time"

	"golang.org/x/time/rate"

	"github.com/sakehub/api/pkg/response"
)

type visitor struct {
	limiter  *rate.Limiter
	lastSeen time.Time
}

// KeyLimiter enforces a token-bucket rate limit per string key (e.g. client
// IP). Stale entries are swept periodically so memory does not grow
// unbounded under sustained traffic from many distinct keys.
type KeyLimiter struct {
	mu       sync.Mutex
	visitors map[string]*visitor
	r        rate.Limit
	burst    int
	ttl      time.Duration
}

// NewKeyLimiter creates a limiter allowing r events/sec (with the given
// burst) per key. Keys unseen for longer than ttl are evicted.
func NewKeyLimiter(r rate.Limit, burst int, ttl time.Duration) *KeyLimiter {
	l := &KeyLimiter{
		visitors: make(map[string]*visitor),
		r:        r,
		burst:    burst,
		ttl:      ttl,
	}
	go l.cleanupLoop()
	return l
}

// Allow reports whether an event for key is permitted right now.
func (l *KeyLimiter) Allow(key string) bool {
	l.mu.Lock()
	defer l.mu.Unlock()

	v, ok := l.visitors[key]
	if !ok {
		v = &visitor{limiter: rate.NewLimiter(l.r, l.burst)}
		l.visitors[key] = v
	}
	v.lastSeen = time.Now()
	return v.limiter.Allow()
}

func (l *KeyLimiter) cleanupLoop() {
	ticker := time.NewTicker(l.ttl)
	defer ticker.Stop()
	for range ticker.C {
		cutoff := time.Now().Add(-l.ttl)
		l.mu.Lock()
		for key, v := range l.visitors {
			if v.lastSeen.Before(cutoff) {
				delete(l.visitors, key)
			}
		}
		l.mu.Unlock()
	}
}

// ClientIP extracts the request's client IP, preferring the value chi's
// RealIP middleware has already written into r.RemoteAddr.
func ClientIP(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

// Middleware rejects requests over the limit with 429, keyed by client IP.
func (l *KeyLimiter) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !l.Allow(ClientIP(r)) {
			response.Error(w, http.StatusTooManyRequests, "too many requests")
			return
		}
		next.ServeHTTP(w, r)
	})
}
