# SakeHub Supabase

Supabase CLI で管理するローカル開発環境の設定・マイグレーションです。

## ローカル環境の構成

| サービス         | URL                                              | 説明                           |
| ---------------- | ------------------------------------------------ | ------------------------------ |
| API（PostgREST） | [http://localhost:54321](http://localhost:54321) | REST API / Auth エンドポイント |
| PostgreSQL       | localhost:54322                                  | データベース直接接続           |
| Studio           | [http://localhost:54323](http://localhost:54323) | Supabase ダッシュボード        |

設定は `config.toml` で管理しています。

ローカル Postgres のメジャーバージョンは `config.toml` の `db.major_version`（現在 **17**）です。メジャー変更後はデータディレクトリが非互換のため、`supabase stop --no-backup` → `supabase start` → `supabase db reset` でスタックを作り直してください。

## ディレクトリ構成

```
supabase/
├── config.toml     # Supabase CLI プロジェクト設定
├── migrations/     # SQLマイグレーションファイル（連番管理）
├── seed.sql        # 分割案内のみ（実体は seeds/）
└── seeds/
    ├── official_cocktails.sql  # 公式カクテル（ローカル / 本番 共通）
    ├── drinks.sql              # drinks マスタ（ローカル / 本番 共通）
    └── local_demo.sql          # デモユーザー・評価・個別レシピ（ローカル専用）
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

Docker Desktop（または同等）が動いていることと、事前に `**supabase start`\*\* が成功していることを前提にしてください。未起動の場合は、この README の「起動 / 停止」を先に済ませます。

---

### 初めてセットアップするとき（既存マイグレーションだけを DB に載せたい）

1. プロジェクトルートでローカルスタックを起動する

```bash
 supabase start
```

2. **ローカル DB を migrations の内容まで作り直し**、`[db.seed]` の SQL も流す

```bash
 supabase db reset
```

このときに起きることの要点:

- ローカル Postgres が **現在の migrations セットに準拠した状態までリセット**される
- `migrations/` 内のファイルが **ファイル名順（タイムスタンプ順）で順番に適用**される
- 処理の最後に `config.toml` の `[db.seed].sql_paths`（公式カクテル → drinks → local_demo）が自動実行される

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
- **seed は自動では流れません**。初期データを入れ直したいときは `pnpm supabase:seed` か `db reset` を使います

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

- **Studio**: [http://localhost:54323](http://localhost:54323) → Table Editor でテーブル一覧を確認
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

シードは用途別に `supabase/seeds/` へ分割しています。

| ファイル                       | 内容                                               | ローカル | 本番 |
| ------------------------------ | -------------------------------------------------- | -------- | ---- |
| `seeds/official_cocktails.sql` | 公式カクテルマスタ・公式レシピ（生成物）           | ✅       | ✅   |
| `seeds/drinks.sql`             | drinks マスタ                                      | ✅       | ✅   |
| `seeds/local_demo.sql`         | デモユーザー・ドリンク評価・個別レシピ・レシピ評価 | ✅       | ❌   |
| `seeds/local_zero_hit.sql`     | お酒検索ゼロ件の再現（類似フィクスチャ・仮の印）   | ✅       | ❌   |
| `seeds/local_stake_merge_published.sql` | 杭マージ再現用 published（手動。自動 seed しない） | 手動     | ❌   |

`config.toml` の `[db.seed].sql_paths` はローカル用に上記 4 ファイルを順に指定しています。

### いつ実行されるか

| 方法                 | 内容                                                                                                                |
| -------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `supabase db reset`  | ローカル DB を作り直したあと、migrations の直後に `[db.seed]` の SQL が自動実行される（`--no-seed` を付けない限り） |
| 下記の「シード単体」 | **いまの DB に対して** seed だけを流す（テーブルはすでに存在している前提）                                          |

### シードだけ再実行したい（リポジトリルートで）

```bash
pnpm supabase:seed          # ローカル: 共通 + local_demo + local_zero_hit
pnpm supabase:seed:shared   # ローカル: 共通のみ（評価・個別レシピなし）
pnpm supabase:seed:prod     # リンク済みリモート: 共通のみ（local_demo なし）
```

`migration up` だけでは seed は走りません。初期データが欲しいときは上記か `db reset` を使ってください。

### 注意（重複 INSERT）

`drinks.sql` / `official_cocktails.sql` / `local_zero_hit.sql` は upsert（`ON CONFLICT`）です。`local_demo.sql` は基本的に **INSERT のみ**で、既に同じ行がある状態で再実行すると UNIQUE 制約で失敗します。空の状態から入れるなら `db reset` を使ってください。

ゼロ件画面の再現クエリは `seeds/local_zero_hit.sql` 先頭コメントを参照（類似あり: `Zenhito Cedr Malt`、類似なし: `xqzt9zeroHitNoCatalog`）。仮の印は `rater01@example.com` / `password123`（バッジは「図鑑待ち」、見返しは `/list?pending=1`）。

杭を published に付け替えるローカル再現は自動 seed に載せない。`local_zero_hit.sql` 投入後に:

```bash
supabase db query --local --file supabase/seeds/local_stake_merge_published.sql
pnpm seed:drinks:merge
```

`pnpm supabase:seed:prod` の対象に `local_zero_hit.sql` / `local_stake_merge_published.sql` は無い。

### カタログ画像（Storage）

本番シード用の商品画像は public バケット **`catalog-images`** に WebP で置く。

| Path                    | 用途             |
| ----------------------- | ---------------- |
| `drinks/{slug}.webp`    | drinks マスタ    |
| `cocktails/{slug}.webp` | cocktails マスタ |

- `image_url` には linked（prod）の絶対公開 URL を入れる（ローカル seed でも同じ URL を参照してよい）
- ユーザーレシピ写真は別バケット `cocktail-images`（`{user_id}/…`）
- 生成・投入ツール: [`packages/catalog-image-seed`](../packages/catalog-image-seed/README.md)

```bash
OPENAI_API_KEY=... pnpm seed:images:generate
SUPABASE_URL=https://xxxx.supabase.co SUPABASE_SERVICE_ROLE_KEY=... pnpm seed:images:upload
pnpm seed:drinks:validate && pnpm seed:drinks:build
pnpm seed:cocktails:validate && pnpm seed:cocktails:build
pnpm supabase:seed:prod
```

費用目安（OpenAI `gpt-image-1.5` medium / 1024×1024）: 約 **$0.034 / 枚**。Phase 1（≈80 枚・再生成なし）は約 **$2.7**。Supabase Free の file storage 枠は **1 GB**（Phase 1 は数〜十数 MB）。

## Studio（管理画面）

起動中は [http://localhost:54323](http://localhost:54323) でテーブルの確認・編集、Auth ユーザーの管理、SQL エディタなどが利用できます。
