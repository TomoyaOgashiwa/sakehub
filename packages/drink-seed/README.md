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

`build-seed.ts` は外部通信なし・決定的。同じ JSON から常に同じ SQL を出す。

## なぜ管理画面ではなくこの形なのか

- 承認 = PR マージ、差分レビュー = `git diff`、却下 = ファイル削除、ロールバック = revert。
- 現状 `public.users` に role カラムがなく、Go API の `CtxRole` もどこからも読まれていない
  （RBAC 基盤ゼロ）。非エンジニア運営メンバーが承認に入る、または週次の処理件数が
  数十件を超えて PR 運用が回らなくなるまでは、管理画面 + RBAC への先行投資はしない。

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
```

`supabase db reset` 時は `config.toml` の `[db.seed]` が
`official_cocktails.sql` → `drinks.sql` → `local_demo.sql` の順で流す。

## 重複検知

`export-demand.ts` は2段階でチェックする:

1. **ローカル**: `data/drinks/*.json` の name/nameEn/aliases を（Go の `NormalizeQuery` と同じ
   かな畳み込みロジックで）正規化し、完全一致すればスキップ。
2. **DB**: `pg_trgm` の `similarity()` で `drinks.name` **および `aliases` の各要素**との
   類似度（`GREATEST`）が閾値を超えるものを「要確認」として `data/pending.txt` に
   コメントアウトで残す（自動では除外しない。最終判断は人が行う）。`pg_trgm` 拡張は
   `migrations/20260806110000_enable_pg_trgm.sql` で有効化済みが前提
   （`export-demand.ts` 自体は DDL を発行しない）。

いずれも新規登録前に「本当に未登録か」を確認するためのヒントであり、確定判定ではない。

## TODO（低優先度・follow-up）

現時点の規模（drinks 30件前後）では投資対効果が低いため未着手。カタログや
トラフィックが増えたタイミングで着手を検討する。

- **検索のスケーラビリティ**: `apps/api/internal/drink/repository.go` /
  `apps/api/internal/cocktail/repository.go` の `unnest(aliases) + strpos` は
  インデックスが効きにくく、カタログ増加でフルスキャン寄りになる。
  まず `search_vector`（FTS）だけでヒット率が足りるか計測し、かな部分一致が
  必要なら `pg_trgm` GIN（`name` / `array_to_string(aliases, ' ')`）へ寄せる。
- **export-demand.ts の N+1**: demand 行ごとに `similarity()` クエリを発行している。
  週次の処理件数が増えたら `LATERAL` で 1 クエリにまとめる。
- **`/api/search-misses` のレート制限**: 現状 IP / `client_hash` 単位の
  レート制限がない。公開後のトラフィックを見て導入を検討する
  （`client_hash` は UUID 形式のみ受理するようになった。詳細は
  `apps/api/internal/searchmiss/model.go` の `clientHashPattern`）。
- **共通化リファクタ**:
  - `packages/drink-seed/src/sql.ts` と `packages/cocktail-seed/src/sql.ts`
    がバイト一致で二重管理。`quoteLiteral` / `quoteTextArrayLiteral` /
    `assertAliases()` を共通パッケージ（例: `packages/seed-utils`）へ集約する。
  - `DRINK_CATEGORIES` が `packages/types/src/drink.ts` /
    `packages/drink-seed/src/schema.ts` / `apps/web/src/config/drinks.ts` の
    3箇所に分かれている。`@sakehub/types` を single source にし、Web は
    表示ラベルのマップだけ持つようにする。
  - `apps/api/internal/searchmiss/normalize.go`（Go）と
    `packages/drink-seed/src/normalize.ts`（TS）は意図的な二重実装。
    テストケースを JSON で共有する軽量な契約テストを追加し、同期ずれを防ぐ。
- **UI 確認**: `apps/web/src/config/drinks.ts` のカテゴリチップが13個に
  増えたため、モバイル幅での折り返し / 横スクロール体験を確認する。
