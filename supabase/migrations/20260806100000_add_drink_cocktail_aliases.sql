-- =============================================================================
-- Migration: add_drink_cocktail_aliases
-- Description: drinks / cocktails に aliases（別名候補: かな表記・ローマ字表記など）
--              を追加し、全文検索 search_vector に合流させる。
--
--              背景: 「獺祭」で登録されていても「だっさい」で検索するとヒットしない
--              ケースが多く、search_misses に記録されるゼロヒットの一部は
--              「未登録」ではなく「登録済みだが引けない」ことが原因になっている。
--              新規レコードを追加する前に、まず既存マスタを引けるようにする。
--
--              search_vector は GENERATED ALWAYS カラムのため生成式を直接
--              ALTER できない。GIN インデックス → カラムの順に一度 DROP し、
--              aliases を合流させた生成式で再作成する。
--
--              array_to_string は STABLE のため GENERATED 式では使えない。
--              text[] → text の結合は入力だけで決まるので IMMUTABLE ラッパーを置く。
--              GENERATED 列から呼ばれる関数のため SET search_path で
--              search_path ハイジャックの余地を塞ぐ（array_to_string 自体は
--              pg_catalog 組み込みだが、明示しておくことで将来の変更にも安全）。
-- =============================================================================

CREATE OR REPLACE FUNCTION array_to_string_immutable(arg text[], separator text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path = pg_catalog
AS $$
  SELECT array_to_string(arg, separator);
$$;

-- ---------------------------------------------------------------------------
-- 1. drinks.aliases
-- ---------------------------------------------------------------------------
ALTER TABLE drinks ADD COLUMN aliases TEXT[] NOT NULL DEFAULT '{}';

-- 想定用途は Phase 3 の drink-seed パイプライン（運営レビュー経由）での付与。
-- ユーザー入力を直接受け付ける経路は現状ないため、上限のみで簡易に守る。
ALTER TABLE drinks ADD CONSTRAINT chk_drinks_aliases_length
  CHECK (array_length(aliases, 1) IS NULL OR array_length(aliases, 1) <= 20);

DROP INDEX idx_drinks_search;
ALTER TABLE drinks DROP COLUMN search_vector;

-- Weight: A (名前 + 別名) > B (製造者) > C (説明文)。既存の重み付けは維持し、
-- aliases を名前と同格（Weight A）で合流させる。
ALTER TABLE drinks ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('simple', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(name_en, '')), 'A') ||
    setweight(to_tsvector('simple', array_to_string_immutable(aliases, ' ')), 'A') ||
    setweight(to_tsvector('simple', coalesce(manufacturer, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(description, '')), 'C')
  ) STORED;

CREATE INDEX idx_drinks_search ON drinks USING GIN (search_vector);

-- ---------------------------------------------------------------------------
-- 2. cocktails.aliases（同パターン）
-- ---------------------------------------------------------------------------
ALTER TABLE cocktails ADD COLUMN aliases TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE cocktails ADD CONSTRAINT chk_cocktails_aliases_length
  CHECK (array_length(aliases, 1) IS NULL OR array_length(aliases, 1) <= 20);

DROP INDEX idx_cocktails_search;
ALTER TABLE cocktails DROP COLUMN search_vector;

ALTER TABLE cocktails ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('simple', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(name_en, '')), 'A') ||
    setweight(to_tsvector('simple', array_to_string_immutable(aliases, ' ')), 'A') ||
    setweight(to_tsvector('simple', coalesce(base_spirit, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(description, '')), 'C')
  ) STORED;

CREATE INDEX idx_cocktails_search ON cocktails USING GIN (search_vector);
