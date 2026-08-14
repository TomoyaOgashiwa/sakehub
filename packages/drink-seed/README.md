# @sakehub/drink-seed

`drinks` マスタの投入パイプライン。JSON データファイルを単一情報源とし、決定的な SQL を生成する。
`packages/cocktail-seed` と同じ思想（承認 = PR マージ、監査ログ = git、管理画面や RBAC は作らない）。

## フロー

```
search_misses (scope=drink, ゼロヒット) → export-demand.ts → data/pending.txt
       ↓
draft.ts（任意・LLM。identity フィールドのみ生成）→ data/drafts/*.json
       ↓ 人手で fact-check（abv / manufacturer / originCountry / description を埋める）して移動
data/drinks/*.json → validate.ts → build-seed.ts → supabase/seeds/drinks.sql
```

**正本は `data/drinks/*.json` のみ。** `data/batches/` は生成途中の非正本で gitignore 対象（コミットしない）。
`scripts/generate-phase1-*.mjs` / `fix-*.mjs` はワンショット／移行用。日常の追加・修正は JSON を直接編集し、`validate` → `build` する。

`build-seed.ts` は外部通信なし・決定的。同じ JSON から常に同じ SQL を出す。
`validate` は truncated manufacturer（`No` / `EJ VS` / `Original` 等）や description の `from null` も拒否する。

## なぜ管理画面ではなくこの形なのか

- 承認 = PR マージ、差分レビュー = `git diff`、却下 = ファイル削除、ロールバック = revert。
- 現状 `public.users` に role カラムがなく、Go API の `CtxRole` もどこからも読まれていない
  （RBAC 基盤ゼロ）。非エンジニア運営メンバーが承認に入る、または週次の処理件数が
  数十件を超えて PR 運用が回らなくなるまでは、管理画面 + RBAC への先行投資はしない。

閲覧コンソール（需要と仮の印の確認）は Web の `/admin` にある。公開マスタの承認は
今どおり PR。画面から `visibility='published'` にはしない。`seed:drinks:merge` も
Web からは呼ばない。

## AI 下書きの制限（重要）

`draft.ts` は **name / nameEn / category / slug / aliases のみ** を生成する。
`abv`（度数）・`manufacturer`（蔵元・製造元）・`originCountry`（産地）・`description` は
LLM が自信満々に誤った値を生成しやすい事実系フィールドのため、**常に null / 空文字のまま**
出力する。人が一次ソース（公式サイト・ラベル等）を確認して埋めてから `data/drinks/` へ移動すること。

## 粒度ルール

1レコード = 商品（SKU / expression）レベル。年数・特定名称・ABV が異なれば別レコード、
限定ラベル・ロット違いは同一レコードに寄せる（詳細は [AGENTS.md](../../AGENTS.md)）。
迷ったら `data/drinks/dassai-23.json` や `data/drinks/yamazaki-12.json` を基準にする。

## コマンド（リポジトリルート）

```bash
DATABASE_URL=... pnpm seed:drinks:demand [limit]   # search_misses Top N → data/pending.txt
OPENAI_API_KEY=... pnpm seed:drinks:draft           # data/drafts/*.json（identity のみ）
pnpm seed:drinks:validate                           # DB CHECK と同等の検証
pnpm seed:drinks:build                              # supabase/seeds/drinks.sql を再生成
pnpm seed:drinks:merge                              # published 投入後、仮の印を正規化名の完全一致で付け替える
```

`seed:drinks:merge` は demand / draft / build からは呼ばない。公開カタログを DB に入れたあと、明示実行する。入力は仮の印（`drinks` provisional）であり、`search_misses` ではない。

`supabase db reset` 時は `config.toml` の `[db.seed]` が
`official_cocktails.sql` → `drinks.sql` → `local_demo.sql` → `local_zero_hit.sql` → `local_admin.sql` の順で流す。

## 重複検知

`export-demand.ts` は2段階でチェックする:

1. **ローカル**: `data/drinks/*.json` の name/nameEn/aliases を（Go の `pkg/normalize.Query` と同じ
   かな畳み込みロジックで）正規化し、完全一致すればスキップ。
2. **DB**: `pg_trgm` の `similarity()` で `drinks.name` **および `aliases` の各要素**との
   類似度（`GREATEST`）が閾値を超えるものを「要確認」として `data/pending.txt` に
   コメントアウトで残す（自動では除外しない。最終判断は人が行う）。demand 行が複数
   あっても DB ラウンドトリップは `unnest(...) WITH ORDINALITY` + `LATERAL` で 1 回に
   まとめている。`pg_trgm` 拡張は `migrations/20260806110000_enable_pg_trgm.sql` で
   有効化済みが前提（`export-demand.ts` 自体は DDL を発行しない）。

いずれも新規登録前に「本当に未登録か」を確認するためのヒントであり、確定判定ではない。

## 品質保証（テスト / 契約）

- `pnpm seed:drinks:validate` — DB CHECK 制約と同等の検証（aliases の空文字・重複・
  上限、ファイル名と `slug` の一致など）。
- `pnpm check:normalize-sync`（`pnpm --filter @sakehub/drink-seed test`）—
  `normalizeJa`（TS）が `pkg/normalize.Query`（Go）と
  同じ結果を返すかを、共有フィクスチャ `testdata/normalize-cases.json`
  （リポジトリルート）に対して検証する契約テスト。ケースを追加・変更したら
  Go 側（`cd apps/api && go test ./pkg/normalize`）も忘れずに実行する。

## 解決済み・現在の設計

過去のレビューで指摘された以下は対応済み:

- **`quoteLiteral` 系 / `assertAliases` / `slugifyAsciiOrFallback` の共通化**:
  `packages/seed-utils` に集約し、`packages/drink-seed` / `packages/cocktail-seed`
  の両方から利用する（バイト一致の二重管理を解消）。
- **`DRINK_CATEGORIES` の single source化**: 実体は `packages/seed-utils` の
  `DRINK_CATEGORIES`。`@sakehub/types`（`['all', ...DRINK_CATEGORIES]`）と
  `packages/drink-seed/src/schema.ts` はここから re-export する。
  `apps/web/src/config/drinks.ts` の `MAIN_FILTER_CATEGORIES` も
  `@sakehub/types` の `DRINK_CATEGORIES` から値を導出し、ラベルだけを
  `Record<DrinkCategory, string>` で管理する（カテゴリ追加時にラベル未設定なら
  コンパイルエラーになる）。
- **Go/TS normalize の契約テスト**: 上記「品質保証」参照。
- **`export-demand.ts` の N+1**: 上記「重複検知」参照（LATERAL で 1 クエリ化済み）。
- **`/api/search-misses` のレート制限**: `apps/api/pkg/ratelimit` で IP 単位の
  トークンバケット（1 req/3s, バースト10）を実装し、`/api/search-misses` に適用済み。
  単一インスタンス前提のインメモリ実装なので、複数インスタンスへスケールする際は
  共有ストア（Redis 等）への切り替えが必要になる。
- **`slugify` の弱い slug**: `slugifyAsciiOrFallback`（`packages/seed-utils`）が
  空文字だけでなく「英字を含まない」「3文字未満」の弱い slug（例:
  `slugify('山崎12年') === '12'`）も検出し、決定的フォールバックに切り替える。
- **ファイル名と `slug` の不一致検知**: `validate.ts` が
  `${slug}.json !== ファイル名` を検出する（drink/cocktail 両方）。
- **モバイルのカテゴリチップ折り返し**: `apps/web/src/components/drinks/category-filter.tsx`
  は `flex flex-wrap gap-2` 済みで、13チップでも折り返し表示される（コードレビューで確認）。
- **pg_trgm GIN インデックス**: `migrations/20260806120000_add_trgm_indexes_for_name_aliases.sql`
  で `drinks.name` / `cocktails.name` / aliases（`array_to_string_immutable` 経由）に
  追加済み。ただし下記「未着手」の通り、List クエリ自体はまだこのインデックスを
  使う形に書き換えていない（`export-demand.ts` の `similarity()` は既に高速化される）。

## TODO（低優先度・未着手）

- **List クエリの `strpos` → `pg_trgm` 移行**: `apps/api/internal/drink/repository.go` /
  `apps/api/internal/cocktail/repository.go` の `unnest(aliases) + strpos` は
  上記の GIN インデックスがあっても現状使われない（`strpos` はインデックスを
  使わないため）。まず `search_vector`（FTS）だけでヒット率が足りるか本番トラフィックで
  計測し、かな部分一致が本当に必要なら `similarity() > 閾値` や `ILIKE` ベースの
  クエリへ書き換えてインデックスを効かせる。クエリの挙動（部分一致 → 類似度ベースの
  ファジーマッチ）が変わるため、切り替えは計測とセットで行うこと。
