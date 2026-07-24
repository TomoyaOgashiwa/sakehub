-- =============================================================================
-- Migration: create_cocktails
-- Description: カクテル種別マスタ（cocktails）の新設と、
--              cocktail_recipes への cocktail_id FK 追加、
--              レシピ専用評価テーブル（cocktail_recipe_ratings）の作成。
--              カクテルは drinks から撤去し、cocktails マスタへ移行する。
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. cocktails マスタテーブル
-- ---------------------------------------------------------------------------
-- レモンサワー・マンハッタンなどの「カクテル種別」を保持する親テーブル。
-- ユーザーが作成するレシピ（cocktail_recipes）はこのマスタに紐づく。
-- 書き込みは service_role のみ（RLS ポリシーは SELECT のみ定義）。
-- ---------------------------------------------------------------------------
CREATE TABLE cocktails (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug           TEXT UNIQUE NOT NULL,
  name           TEXT NOT NULL,
  name_en        TEXT,
  description    TEXT NOT NULL DEFAULT '',
  image_url      TEXT,
  base_spirit    TEXT,
  abv            NUMERIC(4,1),
  origin_country TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE cocktails ADD CONSTRAINT chk_cocktails_name_length
  CHECK (char_length(name) >= 1 AND char_length(name) <= 100);

-- update_updated_at() 関数は create_drinks migration で定義済み
CREATE TRIGGER cocktails_updated_at
  BEFORE UPDATE ON cocktails
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE cocktails ENABLE ROW LEVEL SECURITY;

-- 公開マスタデータ: 認証・未認証ともに閲覧可能
CREATE POLICY "cocktails_select_public" ON cocktails
  FOR SELECT USING (true);

-- ---------------------------------------------------------------------------
-- 2. cocktail_recipes に cocktail_id を追加
-- ---------------------------------------------------------------------------
-- ローカル開発のみのため supabase db reset 前提で NOT NULL を付与する。
-- 本番 / 共有 DB に既存 cocktail_recipes 行がある場合、この ALTER は失敗する。
-- その場合は別 migration で:
--   1) nullable で ADD COLUMN
--   2) バックフィル
--   3) SET NOT NULL
-- の段階適用が必要（本 migration をそのまま本番適用しないこと）。
-- マスタ行の削除はレシピが残っている限り禁止（ON DELETE RESTRICT）。
-- ---------------------------------------------------------------------------
ALTER TABLE cocktail_recipes
  ADD COLUMN cocktail_id UUID NOT NULL REFERENCES cocktails(id) ON DELETE RESTRICT;

-- ジャンル別のレシピ一覧（published のみ）取得を1インデックスでカバーする複合インデックス
CREATE INDEX idx_cocktail_recipes_cocktail_id
  ON cocktail_recipes (cocktail_id, status);

-- ---------------------------------------------------------------------------
-- 3. cocktail_recipe_ratings テーブル（レシピ専用評価）
-- ---------------------------------------------------------------------------
-- 既存 ratings（drinks 用）と同じ設計:
--   rating 1-5 / comment 最大1000文字 / 1ユーザー1レシピにつき1評価（UPSERT 前提）
-- ---------------------------------------------------------------------------
CREATE TABLE cocktail_recipe_ratings (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipe_id  UUID NOT NULL REFERENCES cocktail_recipes(id) ON DELETE CASCADE,
  rating     SMALLINT NOT NULL,
  comment    TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (recipe_id, user_id)
);

ALTER TABLE cocktail_recipe_ratings ADD CONSTRAINT chk_recipe_ratings_rating
  CHECK (rating >= 1 AND rating <= 5);

ALTER TABLE cocktail_recipe_ratings ADD CONSTRAINT chk_recipe_ratings_comment_length
  CHECK (char_length(comment) <= 1000);

-- 評価一覧・平均評価の集計をカバーするインデックス
CREATE INDEX idx_cocktail_recipe_ratings_recipe_id ON cocktail_recipe_ratings (recipe_id);
CREATE INDEX idx_cocktail_recipe_ratings_user_id ON cocktail_recipe_ratings (user_id);

CREATE TRIGGER cocktail_recipe_ratings_updated_at
  BEFORE UPDATE ON cocktail_recipe_ratings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE cocktail_recipe_ratings ENABLE ROW LEVEL SECURITY;

-- Go API の公開境界と揃え、published レシピの評価のみ公開閲覧可。
-- （unpublished / draft レシピの評価を Supabase 直読みで漏らさない）
CREATE POLICY "cocktail_recipe_ratings_select_public" ON cocktail_recipe_ratings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM cocktail_recipes r
      WHERE r.id = recipe_id AND r.status = 'published'
    )
  );

-- Go API の PublishedRecipeExists と揃え、published レシピのみ評価可能にする。
-- （Supabase クライアント直書き込みで draft 評価を付けられないようにする）
CREATE POLICY "cocktail_recipe_ratings_insert_own" ON cocktail_recipe_ratings
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM cocktail_recipes r
      WHERE r.id = recipe_id AND r.status = 'published'
    )
  );

CREATE POLICY "cocktail_recipe_ratings_update_own" ON cocktail_recipe_ratings
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM cocktail_recipes r
      WHERE r.id = recipe_id AND r.status = 'published'
    )
  );

CREATE POLICY "cocktail_recipe_ratings_delete_own" ON cocktail_recipe_ratings
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 4. drinks からカクテルを撤去
-- ---------------------------------------------------------------------------
-- カクテルは cocktails マスタで管理するため、drinks の category から
-- 'cocktail' を除去する。既存カクテル行と関連 ratings（FK CASCADE）は削除。
-- ---------------------------------------------------------------------------
DELETE FROM drinks WHERE category = 'cocktail';

ALTER TABLE drinks DROP CONSTRAINT chk_drinks_category;
ALTER TABLE drinks ADD CONSTRAINT chk_drinks_category
  CHECK (category IN (
    'beer', 'wine', 'whisky', 'sake', 'shochu',
    'vodka', 'gin', 'rum', 'tequila', 'brandy',
    'liqueur', 'other'
  ));
