-- =============================================================================
-- Seed: ローカル専用の運営アカウント
-- 本番 / pnpm supabase:seed:prod / seed:shared / official_cocktails / drinks には入れない。
-- 配線: config.toml [db.seed] と pnpm supabase:seed のみ（local_demo / local_zero_hit の後）。
--
-- ログイン: admin@sakehub.local / password123
-- UUID: a2000000-0000-4000-8000-000000000001
-- public.users は on_auth_user_created で member 作成 → このファイル末尾で admin にする。
-- official@sakehub.app は触らない。rater* は member のまま。
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
)
SELECT
  '00000000-0000-0000-0000-000000000000',
  'a2000000-0000-4000-8000-000000000001'::uuid,
  'authenticated',
  'authenticated',
  'admin@sakehub.local',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('display_name', 'ローカル運営'),
  now(),
  now(),
  '',
  '',
  '',
  ''
WHERE NOT EXISTS (
  SELECT 1 FROM auth.users WHERE email = 'admin@sakehub.local'
);

INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
)
SELECT
  u.id,
  u.id,
  jsonb_build_object('sub', u.id::text, 'email', u.email),
  'email',
  u.email,
  now(),
  now(),
  now()
FROM auth.users u
WHERE u.email = 'admin@sakehub.local'
  AND NOT EXISTS (
    SELECT 1 FROM auth.identities i
    WHERE i.user_id = u.id AND i.provider = 'email'
  );

UPDATE public.users
SET
  app_role = 'admin',
  display_name = 'ローカル運営'
WHERE email = 'admin@sakehub.local';
