-- =============================================================================
-- Migration: users_survive_auth_delete
-- Description: 退会は auth.users を消すが public.users は残す。
--              GoTrue（supabase_auth_admin）経路でリスト CASCADE が
--              ratings を見つけられず deleteUser が落ちるのを直す。
-- =============================================================================

-- Auth 削除時にプロフィール行を消さない。id は元の Auth UUID のまま残る。
-- email UNIQUE が残るので、同じメールでの再 signup は handle_new_user が失敗する。
ALTER TABLE public.users
  DROP CONSTRAINT users_id_fkey;

-- SECURITY DEFINER: supabase_auth_admin は public.ratings への GRANT が無い。
-- search_path: Auth ロールは public を見ないため、無修飾 ratings は relation does not exist になる。
CREATE OR REPLACE FUNCTION public.delete_rating_when_unsave()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.ratings
  WHERE user_id = OLD.user_id AND drink_id = OLD.drink_id;
  RETURN OLD;
END;
$$;
