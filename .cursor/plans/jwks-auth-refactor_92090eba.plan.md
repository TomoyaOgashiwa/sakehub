---
name: jwks-auth-refactor
overview: Go API の JWT 検証を、HS256 共有シークレット方式から Supabase の JWKS（ES256 非対称鍵）検証へリファクタし、Unauthorized を解消する。
todos:
  - id: dep
    content: apps/api に github.com/MicahParks/keyfunc/v3 を追加し go mod tidy
    status: completed
  - id: config
    content: config.go の JWTSecret を SupabaseURL に置換
    status: completed
  - id: keyfunc
    content: main.go で起動時に JWKS keyfunc を生成し router.New に渡す
    status: completed
  - id: middleware
    content: auth.go の RequireAuth を keyfunc ベースの ES256/RS256 検証へリファクタ
    status: completed
  - id: router
    content: router.go の RequireAuth 呼び出しを keyfunc 引数に更新
    status: completed
  - id: env
    content: .env / .env.example の SUPABASE_JWT_SECRET を SUPABASE_URL に置換
    status: completed
  - id: docs
    content: apps/api AGENTS.md/README.md とルート AGENTS.md の環境変数記述を更新
    status: completed
  - id: verify
    content: go vet/build と Web からのレビュー投稿で 401 解消を確認
    status: in_progress
isProject: false
---

# Go API の JWT 検証を JWKS（非対称鍵）方式へリファクタ

## 根本原因

- ローカル Supabase は新方式に移行済みで **JWT secret は存在しない**。access token は JWKS（`http://127.0.0.1:54321/auth/v1/.well-known/jwks.json`）で公開される **ES256 非対称鍵** で署名されている。
- [apps/api/internal/middleware/auth.go](apps/api/internal/middleware/auth.go) は HS256 + 共有シークレット（`SUPABASE_JWT_SECRET=your-jwt-secret` というプレースホルダ）でしか検証できず、署名方式が不一致のため認証付きルートが常に 401 になる。
- Web 側（[apps/web/.env.local](apps/web/.env.local)・[middleware.ts](apps/web/src/middleware.ts)・[actions.ts](apps/web/src/app/drinks/[slug]/actions.ts)）は正常。修正対象はバックエンドの検証ロジックのみ。

## 方針

apps/api の [AGENTS.md](apps/api/AGENTS.md) 第8節が推奨する `github.com/MicahParks/keyfunc/v3` で JWKS を取得・キャッシュし、`golang-jwt/v5` で ES256/RS256 トークンを検証する（Supabase 公式推奨の方式）。

## 変更内容

### 1. 依存追加

- `apps/api` で `go get github.com/MicahParks/keyfunc/v3` → `go mod tidy`。

### 2. 設定: [apps/api/pkg/config/config.go](apps/api/pkg/config/config.go)

- `JWTSecret` を削除し、`SupabaseURL string` を追加。
- `SupabaseURL: getEnv("SUPABASE_URL", "http://127.0.0.1:54321")`。
- JWKS URL は `SupabaseURL + "/auth/v1/.well-known/jwks.json"` で導出。

### 3. キーセット生成: [apps/api/cmd/server/main.go](apps/api/cmd/server/main.go)

- 起動時に一度だけ `keyfunc.NewDefault([]string{jwksURL})` を生成（バックグラウンドで自動リフレッシュ・キャッシュ）。
- 初期取得失敗時はログを出しつつ起動継続できるようハンドリング（Supabase 起動順序に依存しないため）。
- 生成した `keyfunc.Keyfunc` を `router.New(...)` に渡す（シグネチャに引数追加）。

### 4. 認証ミドルウェア: [apps/api/internal/middleware/auth.go](apps/api/internal/middleware/auth.go)

- `RequireAuth(jwtSecret string)` → `RequireAuth(kf keyfunc.Keyfunc)` に変更。
- HMAC 限定チェックを撤廃し、以下で検証:

```go
token, err := jwt.Parse(raw, kf.Keyfunc,
  jwt.WithValidMethods([]string{"ES256", "RS256"}),
  jwt.WithAudience("authenticated"),
  jwt.WithExpirationRequired(),
)
```

- 既存の `sub` → `CtxUserID`、`role` → `CtxRole` の取り出しと `UserID(ctx)` ヘルパーは維持。

### 5. ルーター配線: [apps/api/internal/router/router.go](apps/api/internal/router/router.go)

- `New(logger, db, cfg, kf)` へ更新し、3箇所の `middleware.RequireAuth(cfg.JWTSecret)` を `middleware.RequireAuth(kf)` に置換。

### 6. 環境変数

- [.env](.env): `SUPABASE_JWT_SECRET=your-jwt-secret` を削除し `SUPABASE_URL=http://127.0.0.1:54321` を追加。
- [.env.example](.env.example): 同様に `SUPABASE_JWT_SECRET` を `SUPABASE_URL` に置換。

### 7. ドキュメント更新

- [apps/api/AGENTS.md](apps/api/AGENTS.md) 第8・9節、[apps/api/README.md](apps/api/README.md) の環境変数表、ルート [AGENTS.md](AGENTS.md) の表を、`SUPABASE_JWT_SECRET`(HS256) から `SUPABASE_URL`(JWKS/ES256) ベースの記述へ更新。

## 検証

- `cd apps/api && go vet ./... && go build ./...`。
- Supabase 起動中に Web からレビュー投稿 → API の `/api/auth/reviews` が 200 を返し、401 が解消することを確認。

## 補足（任意・今回の必須ではない）

- Web 側はバグなし。将来的な整合性のため `NEXT_PUBLIC_SUPABASE_ANON_KEY` を `..._PUBLISHABLE_KEY` 等へ改名する余地はあるが、ログインが動作しているため本リファクタの範囲外とする。
