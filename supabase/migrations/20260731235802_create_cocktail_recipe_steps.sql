-- =============================================================================
-- Migration: create_cocktail_recipe_steps
-- Description: カクテルレシピの作り方手順を構造化する。
--              UNIQUE(recipe_id, sort_order) と image_url は意図的に入れない。
--              RLS は cocktail_recipe_ingredients と同型（SELECT は anon 開放済み）。
-- =============================================================================

CREATE TABLE cocktail_recipe_steps (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id  UUID NOT NULL REFERENCES cocktail_recipes(id) ON DELETE CASCADE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  body       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE cocktail_recipe_steps ADD CONSTRAINT chk_step_body_length
  CHECK (char_length(body) >= 1 AND char_length(body) <= 500);

CREATE INDEX idx_cocktail_recipe_steps_recipe_id
  ON cocktail_recipe_steps (recipe_id, sort_order);

ALTER TABLE cocktail_recipe_steps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cocktail_recipe_steps_select" ON cocktail_recipe_steps
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM cocktail_recipes r
      WHERE r.id = recipe_id
        AND (r.status = 'published' OR r.user_id = auth.uid())
    )
  );

CREATE POLICY "cocktail_recipe_steps_insert" ON cocktail_recipe_steps
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM cocktail_recipes r
      WHERE r.id = recipe_id AND r.user_id = auth.uid()
    )
  );

CREATE POLICY "cocktail_recipe_steps_delete" ON cocktail_recipe_steps
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM cocktail_recipes r
      WHERE r.id = recipe_id AND r.user_id = auth.uid()
    )
  );
