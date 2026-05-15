# SakeHub Supabase

Supabase CLI で管理するローカル開発環境の設定・マイグレーションです。

## ローカル環境の構成

| サービス         | URL                    | 説明                           |
| ---------------- | ---------------------- | ------------------------------ |
| API（PostgREST） | http://localhost:54321 | REST API / Auth エンドポイント |
| PostgreSQL       | localhost:54322        | データベース直接接続           |
| Studio           | http://localhost:54323 | Supabase ダッシュボード        |

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

### 用語と前提

| 項目                         | 説明                                                                                                      |
| ---------------------------- | --------------------------------------------------------------------------------------------------------- |
| **ソース・オブ・トゥルース** | この repo の `supabase/migrations/` 以下のタイムスタンプ付き SQL ファイル。テーブル定義・RLS はここに書く |
| **ローカルの Supabase**      | `supabase start` で Docker 上に立つ Postgres（ホストでは `localhost:54322`）                              |
| **実行場所**                 | 必ず **リポジトリのルート**（`pnpm-workspace.yaml` があるディレクトリ）で CLI を実行する                  |

Docker Desktop（または同等）が動いていることと、事前に **`supabase start`** が成功していることを前提にしてください。未起動の場合は、この README の「起動 / 停止」を先に済ませます。

---

### 初めてセットアップするとき（既存マイグレーションだけを DB に載せたい）

1. プロジェクトルートでローカルスタックを起動する

   ```bash
   supabase start
   ```

2. **ローカル DB を migrations の内容まで作り直し**、`seed.sql` も流す

   ```bash
   supabase db reset
   ```

   このときに起きることの要点:
   - ローカル Postgres が **現在の migrations セットに準拠した状態までリセット**される
   - `migrations/` 内のファイルが **ファイル名順（タイムスタンプ順）で順番に適用**される
   - 処理の最後に **`supabase/seed.sql`** が自動実行される（初期データ投入）

起動状態やキーを再確認するときは `supabase status` を使えます。

---

### 開発中によくある 2 パターン（テーブルを「反映」の仕方）

#### A. とにかくローカルを正しい状態に揃える（開発で一番多い）

**データを消してよい／最初から確認したい**ときは `db reset` 一択で構いません。

```bash
supabase db reset
```

- メリット: migrations と seed が常にセットで適用される
- **注意**: ローカルの DB に入っていた開発用データは消えます。残したいときは別途バックアップするか、`migration up`（後述）を検討

シードだけ流したくないとき:

```bash
supabase db reset --no-seed
```

---

#### B. データを残したまま「まだ当たっていない migration だけ」当てる

既にローカル DB が動いていて、**新しく追加した migration ファイルだけ**適用したい場合:

```bash
supabase migration up
```

- デフォルトで **ローカル DB**（`--local` が既定）に、未適用の migration を順に適用します
- **seed.sql は自動では流れません**。初期データを入れ直したいときは手動で SQL を流すか、必要なら `db reset` を使います

適用状況の確認:

```bash
supabase migration list
```

---

### 新しいテーブルやカラムを追加するときの流れ

1. 空の migration を作る（ファイル名は CLI がタイムスタンプで付与します）

   ```bash
   supabase migration new add_something
   ```

2. 生成された `supabase/migrations/<timestamp>_add_something.sql` に `CREATE TABLE` などを書く

3. ローカルに反映する
   - いつも通り全体を揃える: `supabase db reset`
   - または: `supabase migration up`

4. うまくいったか確認する（次節）

---

### Studio や SQL で「反映されたか」確認する

- **Studio**: http://localhost:54323 → Table Editor でテーブル一覧を確認
- **任意の SQL**（ローカル DB が既定対象。必要なら `--local` を明示）:

  ```bash
  supabase db query "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY 1;"
  ```

  `supabase db query --help` でリモート `--linked` や `-f` でファイル指定などを確認できます。

---

### 既存のローカル DB から migration を「逆生成」するとき

Studio や SQL で手を入れたあと、差分を migration ファイルにまとめたい場合は（公式のワークフローに沿って）次を使います。

```bash
supabase db diff -f <migration_name>
```

詳細は [Supabase CLI: Database migrations](https://supabase.com/docs/guides/cli/local-development#database-migrations) を参照してください。

---

### トラブルシューティング（よくあること）

| 症状                                 | 確認すること                                                                                                                       |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `connection refused` など            | `supabase start` が成功しているか、`supabase status` でコンテナが Up か                                                            |
| migration エラーで止まる             | 該当 SQL の文法・依存順（例: 存在しないテーブルへの FK）を修正し、再実行                                                           |
| 「反映したはずなのにテーブルがない」 | 別の Postgres（例: ホストの 5432）を見ていないか。SakeHub のローカルは **54322**（`config.toml` の `[db] port`）                   |
| CLI の挙動が古い                     | `supabase --version` を確認し、[CLI の更新](https://supabase.com/docs/guides/cli/getting-started#updating-the-supabase-cli) を検討 |

---

### リモート（Supabase Cloud）へ同じ migration を載せる（参考）

ローカル専用の話から一歩外れますが、ホストされているプロジェクトへ migration を反映するときは **プロジェクトに link したうえで**（例）

```bash
supabase db push
```

などを使います。初回リンクや運用ポリシーは [Deploying migrations](https://supabase.com/docs/guides/cli/github-action) および `supabase db push --help` を参照してください。

---

## シードデータ

`seed.sql` にローカル開発用の初期データを記述します。

### いつ実行されるか

| 方法                 | 内容                                                                                                                |
| -------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `supabase db reset`  | ローカル DB を作り直したあと、**migrations 適用の直後に `seed.sql` が自動実行**される（`--no-seed` を付けない限り） |
| 下記の「シード単体」 | **いまの DB に対して** `seed.sql` だけを流す（テーブルはすでに存在している前提）                                    |

### シードだけ再実行したい（リポジトリルートで）

pnpm から（中身は Supabase CLI の `db query`）:

```bash
pnpm supabase:seed
```

CLI を直接使う場合:

```bash
supabase db query --local --file supabase/seed.sql
```

`migration up` だけでは seed は走りません。初期データが欲しいときは上記か `db reset` を使ってください。

### 注意（重複 INSERT）

現在の `seed.sql` は **`INSERT` のみ**です。既に同じ行がテーブルに入っている状態で実行すると **主キーや UNIQUE 制約で失敗**します。そのときは `db reset` で空の状態から入れるか、`drinks` などを事前に `TRUNCATE` するなどしてから再実行してください。

## Studio（管理画面）

起動中は http://localhost:54323 でテーブルの確認・編集、Auth ユーザーの管理、SQL エディタなどが利用できます。
