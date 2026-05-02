# SakeHub

A community platform for sake and spirits enthusiasts.

## Tech Stack

| Layer | Technology |
|---|---|
| Monorepo | pnpm workspaces + Turborepo |
| Web | Next.js 15 (App Router) + Tailwind CSS + shadcn/ui + SWR |
| Mobile | Expo + React Native + NativeWind |
| Backend | Go + Chi router |
| Database | Supabase (PostgreSQL) |

## Getting Started

### Prerequisites

- Node.js 20+
- pnpm 9+
- Go 1.23+
- Docker & Docker Compose
- Supabase CLI

### Setup

```bash
# Install dependencies
pnpm install

# Copy environment variables
cp .env.example .env

# Start Supabase local stack
supabase start

# Start Go API (via Docker)
docker compose up api

# Start web & mobile dev servers
pnpm dev
```

## Project Structure

```
sakehub/
├── apps/
│   ├── web/        # Next.js (App Router)
│   ├── mobile/     # Expo (React Native)
│   └── api/        # Go backend
├── packages/
│   ├── types/      # Shared TypeScript types
│   ├── utils/      # Shared utilities
│   └── eslint-config/
├── supabase/       # Supabase CLI project
└── docker-compose.yml
```
