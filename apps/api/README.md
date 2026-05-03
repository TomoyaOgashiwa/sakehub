# SakeHub API

Go 製 REST API サーバー。Chi ルーターを使用し、Supabase（PostgreSQL）に接続します。

## 技術スタック

| 項目 | 技術 |
|---|---|
| 言語 | Go 1.26+ |
| ルーター | go-chi/chi v5 |
| DB ドライバ | lib/pq |
| ロガー | go.uber.org/zap |
| ホットリロード | Air |

## ディレクトリ構成

```
apps/api/
├── cmd/
│   └── server/         # エントリポイント (main.go)
├── internal/
│   ├── handler/        # HTTPハンドラ
│   ├── middleware/      # カスタムミドルウェア
│   ├── model/          # データモデル
│   ├── repository/     # DB アクセス層
│   ├── router/         # ルーティング定義
│   └── service/        # ビジネスロジック
├── migrations/         # SQLマイグレーションファイル
├── pkg/
│   ├── config/         # 設定読み込み
│   ├── response/       # レスポンスヘルパー
│   └── validator/      # バリデーションユーティリティ
├── .air.toml           # Air ホットリロード設定
├── Dockerfile          # 本番用コンテナイメージビルド
└── go.mod
```

## 環境変数

ルートの `.env` ファイルで管理します。

| 変数名 | デフォルト値 | 説明 |
|---|---|---|
| `API_PORT` | `8080` | サーバーのリッスンポート |
| `DATABASE_URL` | `postgresql://postgres:postgres@127.0.0.1:54322/postgres` | Supabase CLI ローカル DB（`supabase status` と一致させる） |
| `SUPABASE_JWT_SECRET` | ― | Supabase JWT 検証用シークレット |

## 起動方法

ローカルではプロジェクト直下で **`supabase start`** で DB と Studio を起動してから、ここでは **ホストで** API を実行します。

### Air（推奨・ホットリロード）

```bash
cd apps/api

# Air がなければインストール
go install github.com/air-verse/air@latest

# ホットリロードで起動
air
```

### ホットリロードなし

```bash
cd apps/api
go run ./cmd/server
```

## API エンドポイント

| メソッド | パス | 説明 |
|---|---|---|
| `GET` | `/ping` | ヘルスチェック（Chi Heartbeat） |
| `GET` | `/api/health` | アプリケーションヘルスチェック |

## CORS 設定

開発環境では以下のオリジンを許可しています。

- `http://localhost:3000`（Web）
- `http://localhost:8081`（Mobile / Expo）
