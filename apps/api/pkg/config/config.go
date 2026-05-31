package config

import "os"

type Config struct {
	Port        string
	DatabaseURL string
	SupabaseURL string
}

func Load() *Config {
	return &Config{
		Port:        getEnv("API_PORT", "8080"),
		DatabaseURL: getEnv("DATABASE_URL", "postgresql://postgres:postgres@127.0.0.1:54322/postgres"),
		SupabaseURL: getEnv("SUPABASE_URL", "http://127.0.0.1:54321"),
	}
}

func (c *Config) JWKSUrl() string {
	return c.SupabaseURL + "/auth/v1/.well-known/jwks.json"
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
