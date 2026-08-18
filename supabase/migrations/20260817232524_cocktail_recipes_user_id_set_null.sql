-- =============================================================================
-- Migration: cocktail_recipes_user_id_set_null
-- Description: 退会時に公開レシピを残す。user_id を NULL 可にし ON DELETE SET NULL。
--              公式の孤児化と draft AND user_id IS NULL は CHECK で禁止する。
-- =============================================================================

ALTER TABLE public.cocktail_recipes
  DROP CONSTRAINT cocktail_recipes_user_id_fkey;

ALTER TABLE public.cocktail_recipes
  ALTER COLUMN user_id DROP NOT NULL;

ALTER TABLE public.cocktail_recipes
  ADD CONSTRAINT cocktail_recipes_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.cocktail_recipes
  ADD CONSTRAINT chk_cocktail_recipes_official_has_user
  CHECK (NOT is_official OR user_id IS NOT NULL);

ALTER TABLE public.cocktail_recipes
  ADD CONSTRAINT chk_cocktail_recipes_draft_has_user
  CHECK (status = 'published' OR user_id IS NOT NULL);
