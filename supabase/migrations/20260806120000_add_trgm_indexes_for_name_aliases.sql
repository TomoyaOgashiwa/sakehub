-- =============================================================================
-- Migration: add_trgm_indexes_for_name_aliases
-- Description: drinks / cocktails の name と aliases に GIN(gin_trgm_ops)
--              インデックスを追加する。
--
--              背景: List クエリの `unnest(aliases) + strpos` 部分一致は
--              インデックスが効かず、カタログ増加でフルスキャン寄りになる
--              （apps/api/internal/{drink,cocktail}/repository.go）。
--              まず search_vector（FTS）だけでヒット率が足りるか計測してから
--              クエリ戦略を切り替える方針のため、このマイグレーションでは
--              クエリ側は変更せず、将来 `%` / `similarity()` ベースの
--              クエリへ移行する際に使えるインデックスだけを先に用意する
--              （packages/drink-seed/README.md の TODO 参照）。
--
--              aliases（text[]）は array_to_string_immutable（
--              migrations/20260806100000_add_drink_cocktail_aliases.sql）で
--              text に結合してから gin_trgm_ops を張る。これは
--              export-demand.ts の similarity() 呼び出し（DB 側重複候補
--              チェック）の高速化にも直接効く。
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_drinks_name_trgm ON drinks USING GIN (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_drinks_aliases_trgm
  ON drinks USING GIN (array_to_string_immutable(aliases, ' ') gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_cocktails_name_trgm ON cocktails USING GIN (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_cocktails_aliases_trgm
  ON cocktails USING GIN (array_to_string_immutable(aliases, ' ') gin_trgm_ops);
