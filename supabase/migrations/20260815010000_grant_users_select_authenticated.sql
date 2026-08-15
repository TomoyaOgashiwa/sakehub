-- Phase 1 の users_select_authenticated は RLS だけ。
-- 新しいローカル CLI では postgres 所有テーブルの default ACL に
-- authenticated の SELECT が無い。Web ゲートの app_role 読み取りに必要。
-- UPDATE は 20260814220000 どおり display_name / avatar_url のみ。

GRANT SELECT ON TABLE public.users TO authenticated;
