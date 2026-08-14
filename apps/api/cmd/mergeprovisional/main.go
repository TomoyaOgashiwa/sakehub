package main

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"time"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"

	"github.com/sakehub/api/internal/saveddrink"
	"github.com/sakehub/api/pkg/config"
)

func main() {
	_ = godotenv.Load("../../.env")
	_ = godotenv.Load(".env")

	cfg := config.Load()
	if cfg.DatabaseURL == "" {
		fmt.Fprintln(os.Stderr, "DATABASE_URL is required")
		os.Exit(1)
	}

	db, err := sql.Open("postgres", cfg.DatabaseURL)
	if err != nil {
		fmt.Fprintf(os.Stderr, "open database: %v\n", err)
		os.Exit(1)
	}
	defer db.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	if err := db.PingContext(ctx); err != nil {
		fmt.Fprintf(os.Stderr, "ping database: %v\n", err)
		os.Exit(1)
	}

	svc := saveddrink.NewService(saveddrink.NewRepository(db))
	report, err := svc.MergeExactNames(ctx)
	if err != nil {
		fmt.Fprintf(os.Stderr, "merge: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf(
		"remapped=%d discarded=%d deleted=%d skipped_ambiguous=%d\n",
		report.Remapped, report.Discarded, report.Deleted, report.SkippedAmbiguous,
	)
	for _, slug := range report.AmbiguousSlugs {
		fmt.Printf("ambiguous: %s\n", slug)
	}
}
