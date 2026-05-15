# AGENTS.md — `apps/api` (SakeHub Go API)

[ルート AGENTS.md](../../AGENTS.md) を**先に**読み、本ファイルを **追加の API 固有ルール** として参照してください。

---

## 1. スタック概要

| 項目           | バージョン / 採用技術                                                                 |
| -------------- | ------------------------------------------------------------------------------------- |
| 言語           | **Go 1.26**                                                                           |
| HTTP ルーター  | **chi v5** (`github.com/go-chi/chi/v5`)                                               |
| CORS           | `github.com/go-chi/cors`                                                              |
| ロガー         | **`go.uber.org/zap`**（プロダクション）。`log/slog`（標準）への移行は別 PR で一括実施 |
| DB ドライバ    | `github.com/lib/pq`（`database/sql`）                                                 |
| .env ロード    | `github.com/joho/godotenv`（ローカル開発用）                                          |
| ホットリロード | **Air** (`github.com/air-verse/air`)                                                  |
| デプロイ       | `Dockerfile`（multi-stage / `golang:1.26-bookworm` → `alpine:3.19`）                  |

> ⚠️ **Go 1.26 の前提**:
>
> - **Green Tea GC** がデフォルト化（GC overhead 10-40% 削減）。チューニング不要だが負荷試験時の挙動が変わることを認識する。
> - **`new` が式を受け付ける**（`p := new(complexExpr)` が可能）。冗長な変数宣言を避ける場面で活用してよい。
> - **`log/slog`** に `slog.MultiHandler` 追加。複数出力先（JSON + コンソールなど）が標準で実現可能。
> - **`go fix` がモダナイザに刷新**。古いイディオムの自動置換が可能。
> - **ジェネリクスが自己参照可能**（`type Tree[T Tree[T]] struct{}` のような形）。

---

## 2. コマンド

```bash
# 開発（ホットリロード推奨）
cd apps/api
go install github.com/air-verse/air@latest    # 初回のみ
air

# ホットリロードなし
cd apps/api && go run ./cmd/server

# テスト / 静的解析
cd apps/api
go test ./...
go vet ./...
go fmt ./...        # gofmt と goimports（後者は別途 install）

# Docker ビルド（本番イメージ）
docker build -t sakehub-api -f apps/api/Dockerfile apps/api

# 依存追加 / 整理
cd apps/api && go get github.com/some/lib@latest
cd apps/api && go mod tidy
```

> **エージェントへ**: コミット前に必ず `go vet ./...` と `go fmt ./...` を実行する。`go test ./...` も該当ディレクトリのテストがあれば回す。

---

## 3. ディレクトリ構成（フィーチャーベース + 共有レイヤ）

```
apps/api/
├── cmd/
│   └── server/
│       └── main.go              # エントリポイント（HTTP サーバー起動 / graceful shutdown）
├── internal/
│   ├── user/                    # user フィーチャー
│   │   ├── handler.go           #   HTTP ハンドラ
│   │   ├── model.go             #   ドメインモデル / DTO
│   │   ├── service.go           #   ビジネスロジック
│   │   └── repository.go        #   インターフェース + SQL 実装
│   ├── drink/                   # drink フィーチャー
│   │   ├── handler.go
│   │   ├── model.go
│   │   ├── service.go
│   │   └── repository.go
│   ├── middleware/              # 共有: 認証・ロギング等（フィーチャー化しない）
│   ├── router/                  # 共有: chi ルート定義（フィーチャー化しない）
│   └── handler/                 # 共有: インフラ系ハンドラ（health 等、フィーチャー化しない）
├── pkg/
│   ├── config/                  # 環境変数読み込み（Config struct）
│   ├── response/                # JSON レスポンスヘルパー
│   └── validator/               # 入力バリデーション
├── migrations/                  # SQL マイグレーション（参考。実体は ../../supabase/migrations）
├── .air.toml                    # Air 設定
├── Dockerfile
├── go.mod
└── go.sum
```

### フィーチャーベースにするもの

ドメインロジックを持つ機能単位ごとにディレクトリを切る。各フィーチャーの Go パッケージ名はフィーチャー名そのもの（`package user`, `package drink`）。

- `handler.go` — HTTP ハンドラ（入出力のみ）
- `model.go` — ドメインモデル / DTO
- `service.go` — ビジネスロジック（repository をインターフェースで受け取る）
- `repository.go` — インターフェース定義 + SQL 実装

ファイルが大きくなった場合は `handler_create.go`, `handler_get.go` のようにサフィックスで分割する。

### フィーチャーベースにしないもの（共有関心事）

- **`internal/router/`** — 全フィーチャーのルートを集約する場所。各フィーチャーの handler をインポートして配線する。
- **`internal/middleware/`** — 認証（JWT 検証）、ロギング等。複数フィーチャーで共有される横断的関心事。
- **`internal/handler/`** — health check のようなドメインロジックを持たないインフラ系ハンドラ。

### レイヤ依存ルール

フィーチャーベースでも各フィーチャー内のレイヤ依存方向は維持する:

```
handler (net/http)
  ↓ uses
service (純粋なビジネスロジック)
  ↓ uses interface
repository (database/sql)
  ↓
PostgreSQL (Supabase)
```

- **フィーチャー間の直接 import は原則禁止**。フィーチャー間連携が必要な場合は service 層で interface を定義してインジェクトする。
- `router` は各フィーチャーの handler を import する**唯一の集約ポイント**。
- `middleware` はどのフィーチャーからも import 可能（ただし handler 層のみ）。
- `internal/` 配下は **外部からの import 禁止** が Go 言語標準で保証される。再利用したいコードは `pkg/` に置く。

---

## 4. ルーティング規約（chi v5）

`internal/router/router.go` の構成:

```go
func New(logger *zap.Logger, db *sql.DB) *chi.Mux {
  r := chi.NewRouter()

  r.Use(chimw.RequestID)
  r.Use(chimw.RealIP)
  r.Use(chimw.Recoverer)
  r.Use(chimw.Heartbeat("/ping"))

  r.Use(cors.Handler(cors.Options{ /* ... */ }))

  // フィーチャーごとに DI を組み立て
  userH := user.NewHandler(user.NewService(user.NewRepository(db)))
  drinkH := drink.NewHandler(drink.NewService(drink.NewRepository(db)))

  r.Route("/api", func(r chi.Router) {
    r.Get("/health", handler.Health)
    r.Route("/users", userH.Routes)
    r.Route("/drinks", drinkH.Routes)
  })

  return r
}
```

**規約**:

- すべてのアプリケーションルートは `/api` プレフィックス配下に置く。
- `r.Route("/users", func(r chi.Router) { ... })` で機能単位にネスト。
- 認証必須ルートは **専用サブルーター**で `r.Group(func(r chi.Router) { r.Use(authMiddleware); ... })`。
- パスパラメータは `chi.URLParam(r, "id")` で取得。
- HTTP メソッドは明示（`r.Get`, `r.Post`, `r.Put`, `r.Patch`, `r.Delete`）。`r.Handle` の汎用は避ける。
- ミドルウェアは **chi 標準** を最大限活用：
  - `RequestID` → 全レスポンスに `X-Request-ID` を返し、構造化ログに紐付け。
  - `Recoverer` → panic を 500 に変換。
  - `Heartbeat("/ping")` → ヘルスチェック専用。
  - `RealIP` → `X-Forwarded-For` を考慮した IP 取得。
  - `Logger` を新規追加するなら **`go-chi/httplog`**（`log/slog` ベース）を推奨。

---

## 5. ハンドラ実装パターン

```go
// internal/drink/handler.go
package drink

import (
  "encoding/json"
  "net/http"

  "github.com/go-chi/chi/v5"
  "github.com/sakehub/api/pkg/response"
)

type Handler struct {
  svc *Service
}

func NewHandler(svc *Service) *Handler {
  return &Handler{svc: svc}
}

func (h *Handler) Routes(r chi.Router) {
  r.Get("/{id}", h.Get)
  r.Post("/", h.Create)
}

func (h *Handler) Get(w http.ResponseWriter, r *http.Request) {
  id := chi.URLParam(r, "id")

  d, err := h.svc.GetByID(r.Context(), id)
  if err != nil {
    response.Error(w, http.StatusInternalServerError, err.Error())
    return
  }

  response.JSON(w, http.StatusOK, d)
}

func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
  var req CreateInput
  if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
    response.Error(w, http.StatusBadRequest, "invalid json")
    return
  }
  defer r.Body.Close()

  d, err := h.svc.Create(r.Context(), req)
  if err != nil {
    response.Error(w, http.StatusInternalServerError, err.Error())
    return
  }

  response.JSON(w, http.StatusCreated, d)
}
```

**規約**:

- ハンドラは **薄く保つ**: 入力デコード → service 呼び出し → 出力エンコードのみ。ビジネス判定は service へ。
- 必ず `r.Context()` を service / repository に渡す。リクエストキャンセル / タイムアウト伝播のため。
- レスポンスヘルパー (`pkg/response`) を必ず使う。直接 `w.Write([]byte(...))` を散らさない。
- エラーは型付きで返し、`response.Error` 内で **`errors.Is` / `errors.As`** でステータスをマッピング:
  - `ErrNotFound` → 404
  - `ErrUnauthorized` → 401
  - `ErrForbidden` → 403
  - `ErrValidation` → 400
  - その他 → 500（詳細はログに出すが本文には出さない）

---

## 6. サービス層

```go
// internal/drink/service.go
package drink

import (
  "context"
  "fmt"
)

type Service struct {
  repo Repository
}

func NewService(repo Repository) *Service {
  return &Service{repo: repo}
}

func (s *Service) GetByID(ctx context.Context, id string) (*Drink, error) {
  d, err := s.repo.FindByID(ctx, id)
  if err != nil {
    return nil, fmt.Errorf("drink.GetByID: %w", err)
  }
  return d, nil
}
```

**規約**:

- service は **repository をインターフェースで受け取る**（テスト時にモック差し替え）。
- ドメインルール（バリデーション、計算、外部 API 呼び出しオーケストレーション）はここに集中。
- エラーは `fmt.Errorf("...: %w", err)` でラップしてコンテキストを保持。

---

## 7. リポジトリ層（lib/pq）

```go
// internal/drink/repository.go
package drink

import (
  "context"
  "database/sql"
  "errors"
)

type Repository interface {
  FindByID(ctx context.Context, id string) (*Drink, error)
  Insert(ctx context.Context, d *Drink) error
}

type repository struct {
  db *sql.DB
}

func NewRepository(db *sql.DB) Repository {
  return &repository{db: db}
}

func (r *repository) FindByID(ctx context.Context, id string) (*Drink, error) {
  const q = `SELECT id, name, category, abv FROM drinks WHERE id = $1`

  var d Drink
  err := r.db.QueryRowContext(ctx, q, id).Scan(&d.ID, &d.Name, &d.Category, &d.ABV)
  if errors.Is(err, sql.ErrNoRows) {
    return nil, ErrNotFound
  }
  if err != nil {
    return nil, err
  }
  return &d, nil
}
```

**規約**:

- SQL は **常にプレースホルダ `$1, $2`**。文字列結合で値を埋め込まない（SQL Injection 防止）。
- `QueryRowContext` / `QueryContext` / `ExecContext` を使い、コンテキストを必ず渡す。
- `*sql.Rows` は必ず `defer rows.Close()`。
- トランザクションは `BeginTx(ctx, nil)` → `defer tx.Rollback()` → `tx.Commit()` のパターン。
- マイグレーションは **`supabase/migrations/`** が信頼できる情報源（このディレクトリの `migrations/` は参考リンク用）。新スキーマは `supabase migration new <name>` で作る。

---

## 8. 認証ミドルウェア（Supabase JWT 検証）

`Authorization: Bearer <access_token>` ヘッダーから JWT を取り出し、`SUPABASE_JWT_SECRET` で検証して `user_id`, `role` を `context.Context` に載せる。

```go
// internal/middleware/auth.go
package middleware

import (
  "context"
  "net/http"
  "os"
  "strings"

  "github.com/golang-jwt/jwt/v5"
)

type ctxKey string

const (
  CtxUserID ctxKey = "user_id"
  CtxRole   ctxKey = "role"
)

func RequireAuth(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    h := r.Header.Get("Authorization")
    raw := strings.TrimPrefix(h, "Bearer ")
    if raw == "" || raw == h {
      http.Error(w, "missing bearer token", http.StatusUnauthorized)
      return
    }

    secret := []byte(os.Getenv("SUPABASE_JWT_SECRET"))
    token, err := jwt.Parse(raw, func(t *jwt.Token) (any, error) {
      if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
        return nil, jwt.ErrSignatureInvalid
      }
      return secret, nil
    })
    if err != nil || !token.Valid {
      http.Error(w, "invalid token", http.StatusUnauthorized)
      return
    }

    claims, ok := token.Claims.(jwt.MapClaims)
    if !ok {
      http.Error(w, "invalid claims", http.StatusUnauthorized)
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
```

**規約**:

- 検証アルゴリズムは現状 **HS256（対称鍵）**。Supabase が非対称鍵（RS256/ES256）に切り替わった環境では JWKS 取得 + 検証へ更新する（`github.com/MicahParks/keyfunc/v3` 等が利用可能）。
- ハンドラからユーザー ID を取り出すヘルパーを作る:
  ```go
  func UserID(ctx context.Context) string {
    if v, ok := ctx.Value(middleware.CtxUserID).(string); ok {
      return v
    }
    return ""
  }
  ```
- 認証ロジックを各ハンドラに散らさず、**ミドルウェアで一元管理**。

---

## 9. 設定 / 起動

`pkg/config/config.go` を経由してすべての環境変数を読み込み、`Config struct` で受け渡す。

```go
type Config struct {
  Port        string
  DatabaseURL string
  JWTSecret   string
}

func Load() Config {
  return Config{
    Port:        getEnv("API_PORT", "8080"),
    DatabaseURL: getEnv("DATABASE_URL", ""),
    JWTSecret:   getEnv("SUPABASE_JWT_SECRET", ""),
  }
}
```

**規約**:

- 起動時に必須環境変数の **空チェック** を行い、欠落していれば `logger.Fatal` で落とす（早期失敗）。
- DB 接続は `cmd/server/main.go` で **1 回だけ** `sql.Open` し、`*sql.DB` をリポジトリにインジェクトする。`sql.Open` は接続を張らないので `db.PingContext(ctx)` で疎通確認を入れる。
- グレースフルシャットダウンは **既存パターンを維持**（SIGINT / SIGTERM → 10 秒 timeout で `srv.Shutdown(ctx)`）。

---

## 10. ロギング

- `zap.NewProduction()` を使用し、`logger.Sync()` を `defer`。
- HTTP リクエスト単位のログにはミドルウェアで `RequestID`、`Method`、`Path`、`Status`、`Duration` を含める。
- 構造化フィールドを必ず使う:
  ```go
  logger.Info("user authenticated", zap.String("user_id", uid), zap.String("role", role))
  ```
  文字列結合 (`fmt.Sprintf`) でメッセージを膨らませない。
- 機微情報（パスワード、トークン本体、メール等）はログに出さない。
- Go 1.26 の `log/slog` への移行を検討する場合は、`slog.MultiHandler` で zap 出力と並行運用してから切替える。

---

## 11. テスト方針

- ユニット: `internal/<feature>/service_test.go` で repository をインターフェースモック化してテスト。
- ハンドラ: `httptest.NewRecorder` + `httptest.NewRequest` でルータを叩く。
- DB を実際に叩く統合テストは `testcontainers-go` か **Supabase ローカル**を `supabase start` した状態で別パッケージに分離（`//go:build integration` タグ）。
- `t.Cleanup` で資源を解放し、`t.Parallel()` を可能な限り付ける。

---

## 12. パフォーマンス / 信頼性

- HTTP サーバー設定（既存値）:
  - `ReadTimeout: 15s`
  - `WriteTimeout: 15s`
  - `IdleTimeout: 60s`
  - 値を変更する場合は負荷試験の結果に基づく。
- 外部 API / DB 呼び出しは **必ず `context.WithTimeout`** で打ち切れるようにする（クライアントが切断したら即停止）。
- ミドルウェアでパニックは `Recoverer` が拾うが、業務ロジックでは `panic` を絶対に発生させない。エラーは値で返す。
- 並行処理は `errgroup`（`golang.org/x/sync/errgroup`）でキャンセル伝播を含めて書く。`go func()` を素手で打ち上げて `wait` 漏れを起こさない。

---

## 13. Docker / デプロイ

`Dockerfile`（multi-stage）の前提:

- ビルダー: `golang:1.26.2-bookworm`、CGO 無効 (`CGO_ENABLED=0`) で **静的バイナリ**化。
- ランナー: `alpine:3.19` + `ca-certificates`。
- Go バージョンを上げる場合は `go.mod` の `go 1.26` と Dockerfile を **同時に更新** する。

---

## 14. アンチパターン（避ける）

❌ ハンドラ関数の中で SQL を書く（リポジトリ層へ）。**理由**: 関心事が混ざってテスト不能になり、仕様変更時の影響範囲が爆発する。
❌ グローバル変数として `*sql.DB` や `*zap.Logger` を保持する（依存注入で渡す）。**理由**: テスト差し替えが難しくなり、初期化順依存のバグを生みやすい。
❌ `panic`/`log.Fatal` を業務コード（ハンドラ・サービス）で使う（起動時のみ許容）。**理由**: 1件の入力不正でプロセス全体を落とし、可用性を損なう。
❌ `context.Background()` を業務コードに直接書く（`r.Context()` を伝搬する）。**理由**: クライアント切断時も処理が止まらず、無駄な DB/外部 API 負荷が残る。
❌ SQL 文字列に変数を `fmt.Sprintf` で埋め込む（プレースホルダを使う）。**理由**: SQL Injection の入口になり、監査観点でも即 NG になる。
❌ レスポンスを `fmt.Fprintf(w, ...)` で書き散らす（`response.JSON` を使う）。**理由**: 形式が不統一になり、エラー表現やクライアント実装の一貫性を崩す。
❌ ミドルウェアで cookie / セッションを独自実装する（Supabase Auth が source of truth）。**理由**: 認証の単一情報源が壊れ、期限切れ・権限判定の齟齬を招く。
❌ `internal/` 内の構造体/関数を外部パッケージから import しようとする（言語仕様で禁止）。**理由**: ビルド不能であり、設計意図（内部実装の隠蔽）にも反する。
❌ chi のミドルウェアを `r.Route` の中で `r.Use` するときに **既にハンドラ登録された後** に呼ぶ（chi の制約。先に Use → 後に Get/Post）。**理由**: 実行時 panic でサーバー起動・ルーティング登録が失敗する。
