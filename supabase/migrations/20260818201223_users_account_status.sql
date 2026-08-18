-- =============================================================================
-- Migration: users_account_status
-- Description: アカウント状態（active/inactive/withdrawal/force_withdrawal）。
--              自主退会後は同じメールで新規登録できる。強制退会メールは別テーブルで拒否する。
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. public.users の状態列
--    inactive: 停止（Auth は残す想定。この PR では値だけ用意）
--    withdrawal: 自主退会。Auth は消す。同じメールで新しい UUID の再登録は可。
--    force_withdrawal: 運営強制。Auth は消す。本人は復帰も再登録も不可。
-- ---------------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN status TEXT NOT NULL DEFAULT 'active',
  ADD COLUMN withdrawal_at TIMESTAMPTZ,
  ADD COLUMN force_withdrawal_at TIMESTAMPTZ;

ALTER TABLE public.users
  ADD CONSTRAINT chk_users_status
    CHECK (status IN ('active', 'inactive', 'withdrawal', 'force_withdrawal'));

ALTER TABLE public.users
  ADD CONSTRAINT chk_users_status_timestamps
    CHECK (
      (
        status IN ('active', 'inactive')
        AND withdrawal_at IS NULL
        AND force_withdrawal_at IS NULL
      )
      OR (
        status = 'withdrawal'
        AND withdrawal_at IS NOT NULL
        AND force_withdrawal_at IS NULL
      )
      OR (
        status = 'force_withdrawal'
        AND force_withdrawal_at IS NOT NULL
        AND withdrawal_at IS NULL
      )
    );

COMMENT ON COLUMN public.users.status IS
  'active|inactive|withdrawal|force_withdrawal. inactive is reserved for suspension with Auth kept.';
COMMENT ON COLUMN public.users.withdrawal_at IS
  'Set when status = withdrawal (self-service).';
COMMENT ON COLUMN public.users.force_withdrawal_at IS
  'Set when status = force_withdrawal (ops). Clients cannot write this column.';

-- 在籍中（active/inactive）だけメールを一意にする。退会済み行は履歴として同じメールを残せる。
ALTER TABLE public.users
  DROP CONSTRAINT users_email_key;

CREATE UNIQUE INDEX uq_users_email_in_use
  ON public.users (lower(email))
  WHERE status IN ('active', 'inactive');

-- ---------------------------------------------------------------------------
-- 2. 強制退会メールの拒否リスト（users と分離）
--    プロフィール履歴は users に残し、再登録可否はこの表が正。
-- ---------------------------------------------------------------------------
CREATE TABLE public.force_withdrawal_emails (
  email_normalized TEXT PRIMARY KEY,
  user_id          UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_force_withdrawal_email_normalized
    CHECK (email_normalized = lower(btrim(email_normalized)) AND email_normalized <> '')
);

COMMENT ON TABLE public.force_withdrawal_emails IS
  'Emails blocked from signup after ops force-withdrawal. Independent of public.users rows.';

ALTER TABLE public.force_withdrawal_emails ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.force_withdrawal_emails FROM anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. クライアントは status を withdrawal 以外へ変えられない。force_* は書けない。
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_client_account_status_abuse()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF current_user IN ('postgres', 'supabase_admin')
     OR COALESCE(auth.role(), '') = 'service_role' THEN
    RETURN NEW;
  END IF;

  IF NEW.force_withdrawal_at IS DISTINCT FROM OLD.force_withdrawal_at
     OR NEW.status = 'force_withdrawal' THEN
    RAISE EXCEPTION 'force_withdrawal cannot be set by clients';
  END IF;

  IF OLD.status IN ('withdrawal', 'force_withdrawal')
     AND NEW.status IS DISTINCT FROM OLD.status THEN
    RAISE EXCEPTION 'withdrawn accounts cannot change status';
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status
     AND NOT (
       OLD.status IN ('active', 'inactive')
       AND NEW.status = 'withdrawal'
     ) THEN
    RAISE EXCEPTION 'invalid account status transition';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER users_account_status_immutable_for_clients
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_client_account_status_abuse();

-- status / withdrawal_at は RPC 経由だけ。列 GRANT は増やさない。
REVOKE UPDATE (status, withdrawal_at, force_withdrawal_at) ON TABLE public.users
  FROM anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. handle_new_user: 強制退会メールを拒否。自主退会済みメールは新規行を許可。
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  normalized TEXT;
BEGIN
  IF NEW.email IS NULL OR btrim(NEW.email) = '' THEN
    RAISE EXCEPTION 'email is required';
  END IF;

  normalized := lower(btrim(NEW.email));

  IF EXISTS (
    SELECT 1
    FROM public.force_withdrawal_emails e
    WHERE e.email_normalized = normalized
  ) THEN
    RAISE EXCEPTION 'EMAIL_FORCE_WITHDRAWN'
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.users (id, email, login_type, status)
  VALUES (
    NEW.id,
    btrim(NEW.email),
    COALESCE(NEW.raw_app_meta_data->>'provider', 'email'),
    'active'
  );

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 5. 自主退会（本人セッション）。Auth 削除はアプリが deleteUser する。
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.withdraw_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_status TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  SELECT status INTO current_status
  FROM public.users
  WHERE id = auth.uid();

  IF current_status IS NULL THEN
    RAISE EXCEPTION 'user profile not found';
  END IF;

  IF current_status = 'withdrawal' THEN
    RETURN;
  END IF;

  IF current_status <> 'active' AND current_status <> 'inactive' THEN
    RAISE EXCEPTION 'cannot withdraw';
  END IF;

  UPDATE public.users
  SET status = 'withdrawal',
      withdrawal_at = now()
  WHERE id = auth.uid()
    AND status IN ('active', 'inactive');
END;
$$;

REVOKE ALL ON FUNCTION public.withdraw_own_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.withdraw_own_account() TO authenticated;

-- ---------------------------------------------------------------------------
-- 6. 強制退会の DB 側（Auth 削除はアプリ）。運営 UI は後続。
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.force_withdraw_account(target_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_role TEXT;
  target_email TEXT;
  target_role TEXT;
  target_status TEXT;
  normalized TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  SELECT app_role INTO caller_role
  FROM public.users
  WHERE id = auth.uid();

  IF caller_role IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'not allowed';
  END IF;

  SELECT email, app_role, status
    INTO target_email, target_role, target_status
  FROM public.users
  WHERE id = target_id;

  IF target_email IS NULL THEN
    RAISE EXCEPTION 'user profile not found';
  END IF;

  IF target_role = 'admin' THEN
    RAISE EXCEPTION 'cannot force-withdraw this account';
  END IF;

  IF lower(target_email) = 'official@sakehub.app' THEN
    RAISE EXCEPTION 'cannot force-withdraw this account';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.cocktail_recipes r
    WHERE r.user_id = target_id AND r.is_official
  ) THEN
    RAISE EXCEPTION 'cannot force-withdraw this account';
  END IF;

  IF target_status = 'force_withdrawal' THEN
    RETURN;
  END IF;

  DELETE FROM public.cocktail_recipes
  WHERE user_id = target_id AND status = 'draft';

  UPDATE public.users
  SET status = 'force_withdrawal',
      force_withdrawal_at = now(),
      withdrawal_at = NULL
  WHERE id = target_id;

  normalized := lower(btrim(target_email));
  INSERT INTO public.force_withdrawal_emails (email_normalized, user_id)
  VALUES (normalized, target_id)
  ON CONFLICT (email_normalized) DO UPDATE
    SET user_id = EXCLUDED.user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.force_withdraw_account(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.force_withdraw_account(UUID) TO authenticated;

-- ---------------------------------------------------------------------------
-- 7. signup 前の拒否判定（中身は出さない。true なら登録不可）
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.email_registration_blocked(p_email TEXT)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(p_email, '') <> ''
    AND EXISTS (
      SELECT 1
      FROM public.force_withdrawal_emails e
      WHERE e.email_normalized = lower(btrim(p_email))
    );
$$;

REVOKE ALL ON FUNCTION public.email_registration_blocked(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.email_registration_blocked(TEXT) TO anon, authenticated;
