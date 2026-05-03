# SakeHub Supabase

Supabase CLI で管理するローカル開発環境の設定・マイグレーションです。

## ローカル環境の構成

| サービス | URL | 説明 |
|---|---|---|
| API（PostgREST） | http://localhost:54321 | REST API / Auth エンドポイント |
| PostgreSQL | localhost:54322 | データベース直接接続 |
| Studio | http://localhost:54323 | Supabase ダッシュボード |

設定は `config.toml` で管理しています。

## ディレクトリ構成

```
supabase/
├── config.toml     # Supabase CLI プロジェクト設定
├── migrations/     # SQLマイグレーションファイル（連番管理）
└── seed.sql        # ローカル開発用シードデータ
```

## 必要なツール

```bash
# Supabase CLI のインストール（Homebrew）
brew install supabase/tap/supabase

# バージョン確認
supabase --version
```

## 起動 / 停止

```bash
# プロジェクトルートから実行

# ローカル Supabase スタック起動
supabase start

# 停止
supabase stop

# 停止してデータも削除
supabase stop --no-backup
```

起動後、アクセスキーがターミナルに表示されます。`.env` に貼り付けて使用してください。

ローカルではこのスタックのみを DB の正としてください。ポート `54322` と競合する別の Postgres コンテナと同時には起動しないでください（Go API はホストから `DATABASE_URL` で接続します）。

```
API URL: http://localhost:54321
anon key: eyJ...
service_role key: eyJ...
```

## マイグレーション

```bash
# 新しいマイグレーションファイルを作成
supabase migration new <migration_name>

# マイグレーションをローカルDBに適用
supabase db reset

# 現在の DB スキーマからマイグレーションを生成
supabase db diff -f <migration_name>
```

## シードデータ

`seed.sql` にローカル開発用の初期データを記述します。`supabase db reset` 実行時に自動で適用されます。

## Studio（管理画面）

起動中は http://localhost:54323 でテーブルの確認・編集、Auth ユーザーの管理、SQL エディタなどが利用できます。
