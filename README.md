# SakeHub

A community platform for sake and spirits enthusiasts.

## Tech Stack

| Layer    | Technology                                               |
| -------- | -------------------------------------------------------- |
| Monorepo | pnpm workspaces + Turborepo                              |
| Web      | Next.js 16 (App Router, Turbopack) + React 19 + Tailwind CSS + shadcn/ui + SWR |
| Mobile   | Expo + React Native + NativeWind                         |
| Backend  | Go + Chi router                                          |
| Database | Supabase (PostgreSQL)                                    |

## Getting Started

### Prerequisites

以下をあらかじめインストールしてください。

- [Node.js 24+](https://nodejs.org/)
- [pnpm 11+](https://pnpm.io/) — `corepack enable` のうえ `packageManager` に従う、または `npm install -g pnpm@11`
- [Go 1.26+](https://go.dev/dl/)
- [Docker](https://www.docker.com/)（Supabase CLI のローカルスタックが使用します）
- [Supabase CLI](https://supabase.com/docs/guides/cli) — `brew install supabase/tap/supabase`

### 1. リポジトリのセットアップ

```bash
# 依存関係インストール
pnpm install

# 環境変数ファイルを作成
cp .env.example .env
```

### 2. Supabase ローカル環境を起動

```bash
supabase start
```

起動後、ターミナルにキーが表示されます。`.env` の以下の値を更新してください。

```env
NEXT_PUBLIC_SUPABASE_URL=http://localhost:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=<表示された anon / publishable key>
SUPABASE_JWT_SECRET=<表示された JWT secret>
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

`anon` と `DATABASE_URL`、`JWT secret` は `supabase status` で再表示できます。

スキーマとシードをまとめて当てたいときは **`supabase db reset`**（migrations → `[db.seed]` の SQL）を使います。  
シードだけ載せたいときは **`pnpm supabase:seed`**（ローカルフル）、本番向け共通シードは **`pnpm supabase:seed:prod`** です。

### 3. Go API を起動

Supabase が起動した状態で、ホスト上から API を実行します。

```bash
cd apps/api && air
```

ホットリロードが不要なら `go run ./cmd/server` でも構いません。本番コンテナビルド用の `Dockerfile` は `apps/api/Dockerfile` にあります。

API は `http://localhost:8080` で起動します。  
`GET /api/health` でレスポンスを確認できます。

### 4. Web / Mobile 開発サーバーを起動

```bash
pnpm dev:web     # Web: http://localhost:3000
pnpm dev:mobile  # Mobile: Expo DevTools が起動
```

### ローカル URL まとめ

| サービス        | URL                    |
| --------------- | ---------------------- |
| Web             | http://localhost:3000  |
| Go API          | http://localhost:8080  |
| Supabase API    | http://localhost:54321 |
| Supabase Studio | http://localhost:54323 |
| PostgreSQL      | localhost:54322        |

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
└── supabase/       # Supabase CLI project
```
