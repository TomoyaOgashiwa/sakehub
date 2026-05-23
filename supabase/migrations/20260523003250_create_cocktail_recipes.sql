-- =============================================================================
-- Migration: create_cocktail_recipes
-- Description: cocktail_recipes + cocktail_recipe_ingredients テーブルの作成
--              ユーザーが登録するオリジナルカクテルレシピ管理用
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. cocktail_recipes テーブル
-- ---------------------------------------------------------------------------
-- user_id: auth.users(id) を FK として使用。ユーザーの退会時にカスケード削除。
-- status: ENUM ではなく TEXT + CHECK 制約。将来のステータス追加が容易。
-- image_url: Supabase Storage の公開 URL（任意）。
-- name: 最大 100 文字で CHECK 制約。DB レベルでも保証する。
-- memo: 最大 1000 文字（任意フィールド）。
-- ---------------------------------------------------------------------------
CREATE TABLE cocktail_recipes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  memo       TEXT,
  image_url  TEXT,
  status     TEXT NOT NULL DEFAULT 'draft',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE cocktail_recipes ADD CONSTRAINT chk_cocktail_recipes_name_length
  CHECK (char_length(name) <= 100 AND char_length(name) >= 1);

ALTER TABLE cocktail_recipes ADD CONSTRAINT chk_cocktail_recipes_memo_length
  CHECK (memo IS NULL OR char_length(memo) <= 1000);

ALTER TABLE cocktail_recipes ADD CONSTRAINT chk_cocktail_recipes_status
  CHECK (status IN ('draft', 'published'));

-- ---------------------------------------------------------------------------
-- 2. cocktail_recipe_ingredients テーブル
-- ---------------------------------------------------------------------------
-- recipe_id: 親レシピの削除時にカスケード削除。
-- amount: NUMERIC で丸め誤差を防ぐ。NULL 許容（例: 「適量」の場合）。
-- unit: NULL 許容（amount が NULL の場合など）。
-- sort_order: フロントエンドで指定した並び順を保持。
-- ---------------------------------------------------------------------------
CREATE TABLE cocktail_recipe_ingredients (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id  UUID NOT NULL REFERENCES cocktail_recipes(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  amount     NUMERIC(10, 2),
  unit       TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE cocktail_recipe_ingredients ADD CONSTRAINT chk_ingredient_name_length
  CHECK (char_length(name) >= 1 AND char_length(name) <= 100);

ALTER TABLE cocktail_recipe_ingredients ADD CONSTRAINT chk_ingredient_unit
  CHECK (unit IS NULL OR unit IN ('ml', 'g', 'piece', 'tsp', 'tbsp', 'dash', 'drop', 'oz', 'cl'));

ALTER TABLE cocktail_recipe_ingredients ADD CONSTRAINT chk_ingredient_amount_positive
  CHECK (amount IS NULL OR amount > 0);

-- ---------------------------------------------------------------------------
-- 3. インデックス
-- ---------------------------------------------------------------------------
CREATE INDEX idx_cocktail_recipes_user_id ON cocktail_recipes (user_id);
CREATE INDEX idx_cocktail_recipes_status  ON cocktail_recipes (status);
CREATE INDEX idx_cocktail_recipe_ingredients_recipe_id
  ON cocktail_recipe_ingredients (recipe_id, sort_order);

-- ---------------------------------------------------------------------------
-- 4. RLS (Row Level Security)
-- ---------------------------------------------------------------------------
ALTER TABLE cocktail_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE cocktail_recipe_ingredients ENABLE ROW LEVEL SECURITY;

-- published レシピは認証済みユーザー全員が閲覧可能
-- draft は自分のレシピのみ閲覧可能
CREATE POLICY "cocktail_recipes_select" ON cocktail_recipes
  FOR SELECT TO authenticated
  USING (status = 'published' OR auth.uid() = user_id);

-- 認証済みユーザーのみ自分のレシピを作成
CREATE POLICY "cocktail_recipes_insert" ON cocktail_recipes
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 自分のレシピのみ更新
CREATE POLICY "cocktail_recipes_update" ON cocktail_recipes
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 自分のレシピのみ削除
CREATE POLICY "cocktail_recipes_delete" ON cocktail_recipes
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- 食材はレシピの RLS に準拠（レシピが見えるなら食材も見える）
CREATE POLICY "cocktail_recipe_ingredients_select" ON cocktail_recipe_ingredients
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM cocktail_recipes r
      WHERE r.id = recipe_id
        AND (r.status = 'published' OR r.user_id = auth.uid())
    )
  );

CREATE POLICY "cocktail_recipe_ingredients_insert" ON cocktail_recipe_ingredients
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM cocktail_recipes r
      WHERE r.id = recipe_id AND r.user_id = auth.uid()
    )
  );

CREATE POLICY "cocktail_recipe_ingredients_delete" ON cocktail_recipe_ingredients
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM cocktail_recipes r
      WHERE r.id = recipe_id AND r.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- 5. updated_at 自動更新トリガー
-- ---------------------------------------------------------------------------
-- update_updated_at() 関数は create_drinks migration で定義済み
CREATE TRIGGER cocktail_recipes_updated_at
  BEFORE UPDATE ON cocktail_recipes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- 6. Supabase Storage バケット（cocktail-images）
-- ---------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('cocktail-images', 'cocktail-images', true)
ON CONFLICT (id) DO NOTHING;

-- 認証済みユーザーが自分のフォルダへ画像をアップロード可能
CREATE POLICY "cocktail_images_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'cocktail-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- 公開バケットなので全員閲覧可能
CREATE POLICY "cocktail_images_select" ON storage.objects
  FOR SELECT USING (bucket_id = 'cocktail-images');

-- 自分がアップロードした画像のみ削除可能
CREATE POLICY "cocktail_images_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'cocktail-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
