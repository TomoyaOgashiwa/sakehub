-- =============================================================================
-- Migration: cocktail_recipes_is_official
-- Description: 公式（基本）レシピを cocktail_recipes.is_official で表現する。
--              公式は published 必須・1カクテル1件。一覧インデックスは投稿のみ。
--              公式は評価不可。recipes / ingredients の SELECT を anon に開放。
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. is_official 列 + 制約
-- ---------------------------------------------------------------------------
ALTER TABLE cocktail_recipes
  ADD COLUMN is_official BOOLEAN NOT NULL DEFAULT false;

-- 公式が draft になると詳細ページから基本レシピが消えるため DB で禁止
ALTER TABLE cocktail_recipes ADD CONSTRAINT chk_official_is_published
  CHECK (NOT is_official OR status = 'published');

-- 1 カクテル 1 公式。cocktails.official_recipe_id による循環 FK を避ける
CREATE UNIQUE INDEX uq_cocktail_recipes_official
  ON cocktail_recipes (cocktail_id) WHERE is_official;

-- 一覧クエリは公式を除外するので部分インデックスに差し替え
DROP INDEX idx_cocktail_recipes_cocktail_id;
CREATE INDEX idx_cocktail_recipes_cocktail_id
  ON cocktail_recipes (cocktail_id, created_at DESC)
  WHERE status = 'published' AND NOT is_official;

-- ---------------------------------------------------------------------------
-- 2. 公式レシピは評価不可（insert / update を作り直し）
-- ---------------------------------------------------------------------------
DROP POLICY "cocktail_recipe_ratings_insert_own" ON cocktail_recipe_ratings;
DROP POLICY "cocktail_recipe_ratings_update_own" ON cocktail_recipe_ratings;

CREATE POLICY "cocktail_recipe_ratings_insert_own" ON cocktail_recipe_ratings
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM cocktail_recipes r
      WHERE r.id = recipe_id
        AND r.status = 'published'
        AND NOT r.is_official
    )
  );

CREATE POLICY "cocktail_recipe_ratings_update_own" ON cocktail_recipe_ratings
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM cocktail_recipes r
      WHERE r.id = recipe_id
        AND r.status = 'published'
        AND NOT r.is_official
    )
  );

-- ---------------------------------------------------------------------------
-- 3. RLS 不整合の解消: SELECT を anon 含め開放
--    drinks_select_public と同じ「読み取りは anon 含め開放」。
--    anon では auth.uid() が NULL 評価になるため draft は漏れない。
-- ---------------------------------------------------------------------------
DROP POLICY "cocktail_recipes_select" ON cocktail_recipes;
CREATE POLICY "cocktail_recipes_select" ON cocktail_recipes
  FOR SELECT
  USING (status = 'published' OR auth.uid() = user_id);

DROP POLICY "cocktail_recipe_ingredients_select" ON cocktail_recipe_ingredients;
CREATE POLICY "cocktail_recipe_ingredients_select" ON cocktail_recipe_ingredients
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM cocktail_recipes r
      WHERE r.id = recipe_id
        AND (r.status = 'published' OR r.user_id = auth.uid())
    )
  );
