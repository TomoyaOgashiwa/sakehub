package ratelimit

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"golang.org/x/time/rate"
)

func TestKeyLimiter_AllowsUpToBurstThenBlocks(t *testing.T) {
	l := NewKeyLimiter(rate.Every(time.Hour), 2, time.Minute)

	if !l.Allow("a") {
		t.Fatal("expected first request to be allowed")
	}
	if !l.Allow("a") {
		t.Fatal("expected second request (within burst) to be allowed")
	}
	if l.Allow("a") {
		t.Fatal("expected third request to be rate limited")
	}
}

func TestKeyLimiter_KeysAreIndependent(t *testing.T) {
	l := NewKeyLimiter(rate.Every(time.Hour), 1, time.Minute)

	if !l.Allow("a") {
		t.Fatal("expected key a's first request to be allowed")
	}
	if !l.Allow("b") {
		t.Fatal("expected key b's first request to be allowed independently of a")
	}
	if l.Allow("a") {
		t.Fatal("expected key a's second request to be rate limited")
	}
}

func TestClientIP(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/", nil)
	req.RemoteAddr = "203.0.113.5:54321"

	if got := ClientIP(req); got != "203.0.113.5" {
		t.Fatalf("ClientIP() = %q, want %q", got, "203.0.113.5")
	}
}

func TestClientIP_FallsBackToRawRemoteAddr(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/", nil)
	req.RemoteAddr = "not-a-host-port"

	if got := ClientIP(req); got != "not-a-host-port" {
		t.Fatalf("ClientIP() = %q, want %q", got, "not-a-host-port")
	}
}

func TestMiddleware_BlocksOverLimit(t *testing.T) {
	l := NewKeyLimiter(rate.Every(time.Hour), 1, time.Minute)

	handler := l.Middleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodPost, "/", nil)
	req.RemoteAddr = "198.51.100.1:1234"

	rec1 := httptest.NewRecorder()
	handler.ServeHTTP(rec1, req)
	if rec1.Code != http.StatusOK {
		t.Fatalf("first request: got status %d, want %d", rec1.Code, http.StatusOK)
	}

	rec2 := httptest.NewRecorder()
	handler.ServeHTTP(rec2, req)
	if rec2.Code != http.StatusTooManyRequests {
		t.Fatalf("second request: got status %d, want %d", rec2.Code, http.StatusTooManyRequests)
	}
}
