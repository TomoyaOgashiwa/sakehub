-- =============================================================================
-- Migration: add_users_app_role
-- Description: アプリ権限列（member|admin）と自己昇格防止、search_miss_ranking の露出止め
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. public.users.app_role
--    handle_new_user() は id / email / login_type だけ INSERT する。
--    raw_user_meta_data からは読まない。signup で admin を名乗れない。
--    既存行は DEFAULT で member（official@ / rater も member）。
-- ---------------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN app_role TEXT NOT NULL DEFAULT 'member';

ALTER TABLE public.users
  ADD CONSTRAINT chk_users_app_role
  CHECK (app_role IN ('member', 'admin'));

COMMENT ON COLUMN public.users.app_role IS
  'App RBAC. Distinct from GoTrue JWT role / auth.users.role. member|admin.';

-- ---------------------------------------------------------------------------
-- 2. 列 GRANT（PostgREST の第一層）
--    Supabase の default GRANT ALL は table-level UPDATE なので、
--    REVOKE UPDATE (app_role) だけでは全列更新が残る。
--    table-level UPDATE を外し、プロフィール列だけ戻す。
--    service_role / postgres の GRANT は触らない。
-- ---------------------------------------------------------------------------
REVOKE UPDATE ON TABLE public.users FROM anon, authenticated;
GRANT UPDATE (display_name, avatar_url) ON TABLE public.users TO authenticated;
REVOKE UPDATE (app_role) ON TABLE public.users FROM anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. トリガー（拒否が既定。SQL / 将来の RPC 用）
--    users_update_own は display_name 等のために残す（ポリシーは書き換えない）。
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_client_app_role_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NEW.app_role IS DISTINCT FROM OLD.app_role THEN
    IF current_user NOT IN ('postgres', 'supabase_admin')
       AND COALESCE(auth.role(), '') IS DISTINCT FROM 'service_role' THEN
      RAISE EXCEPTION 'app_role cannot be changed by clients';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER users_app_role_immutable_for_clients
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_client_app_role_change();

-- ---------------------------------------------------------------------------
-- 4. search_miss_ranking のクライアント露出
--    REVOKE が本体。security_invoker は GRANT し直されたときの第二層。
-- ---------------------------------------------------------------------------
REVOKE ALL ON TABLE public.search_miss_ranking FROM anon, authenticated;
ALTER VIEW public.search_miss_ranking SET (security_invoker = true);
