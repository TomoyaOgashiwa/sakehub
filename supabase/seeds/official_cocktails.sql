-- =============================================================================
-- packages/cocktail-seed（src/build-seed.ts）が自動生成。
-- 手編集しないこと。再生成: pnpm seed:cocktails:build
-- 生成日時: 2026-08-11T21:22:23.977Z
-- 件数: 164
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------
-- Official operator user (email-keyed; environment-independent)
-- ---------------------------------------------------------------------------
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
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'official@sakehub.app',
  crypt('official-seed-only', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('display_name', 'SakeHub公式'),
  now(),
  now(),
  '',
  '',
  '',
  ''
WHERE NOT EXISTS (
  SELECT 1 FROM auth.users WHERE email = 'official@sakehub.app'
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
WHERE u.email = 'official@sakehub.app'
  AND NOT EXISTS (
    SELECT 1 FROM auth.identities i
    WHERE i.user_id = u.id AND i.provider = 'email'
  );

UPDATE public.users
SET display_name = 'SakeHub公式'
WHERE email = 'official@sakehub.app';

-- ---------------------------------------------------------------------------
-- cocktails master + official recipes
-- ---------------------------------------------------------------------------

-- alaska
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '8b7257f6-f113-539c-bee3-b12da4635c97',
  'alaska',
  'アラスカ',
  'Alaska',
  'ジンとイエローシャルトリューズをステアする、ハーブ香が際立つクラシック。',
  'Gin',
  35,
  'United States',
  NULL,
  'none',
  ARRAY['アラスカカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '5041cde0-a722-59e7-82e3-b9b409c7703e',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '8b7257f6-f113-539c-bee3-b12da4635c97',
  'アラスカ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '5041cde0-a722-59e7-82e3-b9b409c7703e';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '5041cde0-a722-59e7-82e3-b9b409c7703e';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('5041cde0-a722-59e7-82e3-b9b409c7703e', 'ドライジン', 45, 'ml', 0),
  ('5041cde0-a722-59e7-82e3-b9b409c7703e', 'イエローシャルトリューズ', 15, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('5041cde0-a722-59e7-82e3-b9b409c7703e', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('5041cde0-a722-59e7-82e3-b9b409c7703e', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('5041cde0-a722-59e7-82e3-b9b409c7703e', '冷やしたグラスに注ぐ。', 2);

-- amaretto-sour
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '109705d3-dc9f-5a92-8774-364eb02020da',
  'amaretto-sour',
  'アマレットサワー',
  'Amaretto Sour',
  'アマレットの杏仁香をレモンと卵白でやわらげる、人気のリキュールサワー。',
  'Liqueur',
  14,
  'United States',
  NULL,
  'none',
  ARRAY['アマレット・サワー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '1f3ea09c-4703-5a52-94ed-d28849cfb97e',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '109705d3-dc9f-5a92-8774-364eb02020da',
  'アマレットサワー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '1f3ea09c-4703-5a52-94ed-d28849cfb97e';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '1f3ea09c-4703-5a52-94ed-d28849cfb97e';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('1f3ea09c-4703-5a52-94ed-d28849cfb97e', 'アマレット', 45, 'ml', 0),
  ('1f3ea09c-4703-5a52-94ed-d28849cfb97e', 'レモンジュース', 25, 'ml', 1),
  ('1f3ea09c-4703-5a52-94ed-d28849cfb97e', 'シュガーシロップ', 10, 'ml', 2),
  ('1f3ea09c-4703-5a52-94ed-d28849cfb97e', '卵白', 1, 'piece', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('1f3ea09c-4703-5a52-94ed-d28849cfb97e', 'シェーカーに材料と氷を入れる。', 0),
  ('1f3ea09c-4703-5a52-94ed-d28849cfb97e', 'しっかりシェイクして冷やす。', 1),
  ('1f3ea09c-4703-5a52-94ed-d28849cfb97e', '冷やしたグラスに注ぐ。', 2);

-- americano
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b9580f66-864a-530a-8ff3-56fe351eaa7b',
  'americano',
  'アメリカーノ',
  'Americano',
  'カンパリ、スイートベルモット、ソーダで作る、ネグローニの源流となった食前酒。',
  'Liqueur',
  9,
  'Italy',
  NULL,
  'none',
  ARRAY['アメリカーノカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '02bac2f2-176e-5530-90ec-5b8a36266c7a',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b9580f66-864a-530a-8ff3-56fe351eaa7b',
  'アメリカーノ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '02bac2f2-176e-5530-90ec-5b8a36266c7a';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '02bac2f2-176e-5530-90ec-5b8a36266c7a';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('02bac2f2-176e-5530-90ec-5b8a36266c7a', 'カンパリ', 30, 'ml', 0),
  ('02bac2f2-176e-5530-90ec-5b8a36266c7a', 'スイートベルモット', 30, 'ml', 1),
  ('02bac2f2-176e-5530-90ec-5b8a36266c7a', 'ソーダ', 90, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('02bac2f2-176e-5530-90ec-5b8a36266c7a', 'グラスに氷を入れる。', 0),
  ('02bac2f2-176e-5530-90ec-5b8a36266c7a', '材料を順に注ぐ。', 1),
  ('02bac2f2-176e-5530-90ec-5b8a36266c7a', '軽く混ぜて仕上げる。', 2);

-- aperol-spritz
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'e4662b66-6d38-5874-9541-268d547487a3',
  'aperol-spritz',
  'アペロールスプリッツ',
  'Aperol Spritz',
  'アペロール、プロセッコ、ソーダで作るイタリアの軽快なアペリティーボ。',
  'Liqueur',
  8,
  'Italy',
  NULL,
  'none',
  ARRAY['スプマンテ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '1a9eb1d8-f81e-5fd7-892c-4ca51e9f6d24',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'e4662b66-6d38-5874-9541-268d547487a3',
  'アペロールスプリッツ（基本レシピ）',
  '比率は 3:2:1（プロセッコ:アペロール:ソーダ）も定番。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '1a9eb1d8-f81e-5fd7-892c-4ca51e9f6d24';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '1a9eb1d8-f81e-5fd7-892c-4ca51e9f6d24';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('1a9eb1d8-f81e-5fd7-892c-4ca51e9f6d24', 'アペロール', 60, 'ml', 0),
  ('1a9eb1d8-f81e-5fd7-892c-4ca51e9f6d24', 'プロセッコ', 90, 'ml', 1),
  ('1a9eb1d8-f81e-5fd7-892c-4ca51e9f6d24', '炭酸水', 30, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('1a9eb1d8-f81e-5fd7-892c-4ca51e9f6d24', 'ワイングラスに氷をたっぷり入れる。', 0),
  ('1a9eb1d8-f81e-5fd7-892c-4ca51e9f6d24', 'アペロール、プロセッコ、ソーダを注ぐ。', 1),
  ('1a9eb1d8-f81e-5fd7-892c-4ca51e9f6d24', '軽く混ぜ、オレンジスライスを飾る。', 2);

-- appletini
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'f5c59c52-226b-5c3c-9e33-2a5f400be72b',
  'appletini',
  'アップルティーニ',
  'Appletini',
  'ウォッカにアップルリキュールを合わせる、鮮やかなリンゴ風味のモダンカクテル。',
  'Vodka',
  24,
  'United States',
  NULL,
  'none',
  ARRAY['アップルマティーニ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '049eeb94-6486-5a00-af43-6adaa90eefec',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'f5c59c52-226b-5c3c-9e33-2a5f400be72b',
  'アップルティーニ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '049eeb94-6486-5a00-af43-6adaa90eefec';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '049eeb94-6486-5a00-af43-6adaa90eefec';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('049eeb94-6486-5a00-af43-6adaa90eefec', 'ウォッカ', 45, 'ml', 0),
  ('049eeb94-6486-5a00-af43-6adaa90eefec', 'アップルリキュール', 30, 'ml', 1),
  ('049eeb94-6486-5a00-af43-6adaa90eefec', 'レモンジュース', 10, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('049eeb94-6486-5a00-af43-6adaa90eefec', 'シェーカーに材料と氷を入れる。', 0),
  ('049eeb94-6486-5a00-af43-6adaa90eefec', 'しっかりシェイクして冷やす。', 1),
  ('049eeb94-6486-5a00-af43-6adaa90eefec', '冷やしたグラスに注ぐ。', 2);

-- aviation
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'e8ef61f4-4461-5b69-8cd8-9b3ae92eb8f1',
  'aviation',
  'アビエーション',
  'Aviation',
  'ジンにマラスキーノとバイオレットの香りを重ねる、淡い紫色のクラシック。',
  'Gin',
  27,
  'United States',
  NULL,
  'none',
  ARRAY['アヴィエーション']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'e8e8ad31-0a32-5d3a-b6f8-7e92faec5ba8',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'e8ef61f4-4461-5b69-8cd8-9b3ae92eb8f1',
  'アビエーション（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'e8e8ad31-0a32-5d3a-b6f8-7e92faec5ba8';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'e8e8ad31-0a32-5d3a-b6f8-7e92faec5ba8';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('e8e8ad31-0a32-5d3a-b6f8-7e92faec5ba8', 'ドライジン', 45, 'ml', 0),
  ('e8e8ad31-0a32-5d3a-b6f8-7e92faec5ba8', 'マラスキーノリキュール', 15, 'ml', 1),
  ('e8e8ad31-0a32-5d3a-b6f8-7e92faec5ba8', 'レモンジュース', 15, 'ml', 2),
  ('e8e8ad31-0a32-5d3a-b6f8-7e92faec5ba8', 'クレーム・ド・バイオレット', 5, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('e8e8ad31-0a32-5d3a-b6f8-7e92faec5ba8', 'シェーカーに材料と氷を入れる。', 0),
  ('e8e8ad31-0a32-5d3a-b6f8-7e92faec5ba8', 'しっかりシェイクして冷やす。', 1),
  ('e8e8ad31-0a32-5d3a-b6f8-7e92faec5ba8', '冷やしたグラスに注ぐ。', 2);

-- b-52
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '7c00a9b9-0f28-597c-b1f8-c86c4abcc8cd',
  'b-52',
  'B-52',
  'B-52',
  'コーヒー、アイリッシュクリーム、オレンジのリキュールを層にするショットカクテル。',
  'Liqueur',
  24,
  'Canada',
  NULL,
  'none',
  ARRAY['ビー・フィフティツー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'cf250944-abbf-5617-b3d8-96a9c33d10af',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '7c00a9b9-0f28-597c-b1f8-c86c4abcc8cd',
  'B-52（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'cf250944-abbf-5617-b3d8-96a9c33d10af';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'cf250944-abbf-5617-b3d8-96a9c33d10af';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('cf250944-abbf-5617-b3d8-96a9c33d10af', 'コーヒーリキュール', 20, 'ml', 0),
  ('cf250944-abbf-5617-b3d8-96a9c33d10af', 'アイリッシュクリーム', 20, 'ml', 1),
  ('cf250944-abbf-5617-b3d8-96a9c33d10af', 'グランマルニエ', 20, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('cf250944-abbf-5617-b3d8-96a9c33d10af', 'グラスに氷を入れる。', 0),
  ('cf250944-abbf-5617-b3d8-96a9c33d10af', '材料を順に注ぐ。', 1),
  ('cf250944-abbf-5617-b3d8-96a9c33d10af', '軽く混ぜて仕上げる。', 2);

-- bacardi-cocktail
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c7812347-2052-5308-90b7-aa16f0cf2213',
  'bacardi-cocktail',
  'バカルディカクテル',
  'Bacardi Cocktail',
  'ライトラムにライムとグレナデンを合わせる、ブランド名で広まったクラシック。',
  'Rum',
  24,
  'Cuba',
  NULL,
  'none',
  ARRAY['バカルディ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '740baaaa-c340-5ab0-99e3-3b6484daf5cf',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c7812347-2052-5308-90b7-aa16f0cf2213',
  'バカルディカクテル（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '740baaaa-c340-5ab0-99e3-3b6484daf5cf';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '740baaaa-c340-5ab0-99e3-3b6484daf5cf';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('740baaaa-c340-5ab0-99e3-3b6484daf5cf', 'ライトラム', 45, 'ml', 0),
  ('740baaaa-c340-5ab0-99e3-3b6484daf5cf', 'ライムジュース', 20, 'ml', 1),
  ('740baaaa-c340-5ab0-99e3-3b6484daf5cf', 'グレナデンシロップ', 10, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('740baaaa-c340-5ab0-99e3-3b6484daf5cf', 'シェーカーに材料と氷を入れる。', 0),
  ('740baaaa-c340-5ab0-99e3-3b6484daf5cf', 'しっかりシェイクして冷やす。', 1),
  ('740baaaa-c340-5ab0-99e3-3b6484daf5cf', '冷やしたグラスに注ぐ。', 2);

-- batanga
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'fccba1b6-40f4-5550-a154-0928ee57ee39',
  'batanga',
  'バタンガ',
  'Batanga',
  'テキーラ、ライム、コーラを塩で引き締める、メキシコのバー定番。',
  'Tequila',
  10,
  'Mexico',
  NULL,
  'none',
  ARRAY['バタンガカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '452fea9a-1811-515c-b5a0-e54db96f88a7',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'fccba1b6-40f4-5550-a154-0928ee57ee39',
  'バタンガ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '452fea9a-1811-515c-b5a0-e54db96f88a7';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '452fea9a-1811-515c-b5a0-e54db96f88a7';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('452fea9a-1811-515c-b5a0-e54db96f88a7', 'テキーラブランコ', 45, 'ml', 0),
  ('452fea9a-1811-515c-b5a0-e54db96f88a7', 'ライムジュース', 15, 'ml', 1),
  ('452fea9a-1811-515c-b5a0-e54db96f88a7', 'コーラ', 120, 'ml', 2),
  ('452fea9a-1811-515c-b5a0-e54db96f88a7', '塩', 1, 'dash', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('452fea9a-1811-515c-b5a0-e54db96f88a7', 'グラスに氷を入れる。', 0),
  ('452fea9a-1811-515c-b5a0-e54db96f88a7', '材料を順に注ぐ。', 1),
  ('452fea9a-1811-515c-b5a0-e54db96f88a7', '軽く混ぜて仕上げる。', 2);

-- batida-de-coco
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '1c82a35b-601f-54c9-a038-3d64c4d30332',
  'batida-de-coco',
  'バチーダデココ',
  'Batida de Coco',
  'カシャッサ、ココナッツ、コンデンスミルクを合わせる、ブラジルの濃厚な定番。',
  'Cachaca',
  14,
  'Brazil',
  NULL,
  'none',
  ARRAY['バチーダ・デ・ココ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'd3a1c9a9-3010-506e-b0b5-9bfcf806e640',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '1c82a35b-601f-54c9-a038-3d64c4d30332',
  'バチーダデココ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'd3a1c9a9-3010-506e-b0b5-9bfcf806e640';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'd3a1c9a9-3010-506e-b0b5-9bfcf806e640';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('d3a1c9a9-3010-506e-b0b5-9bfcf806e640', 'カシャッサ', 50, 'ml', 0),
  ('d3a1c9a9-3010-506e-b0b5-9bfcf806e640', 'ココナッツミルク', 60, 'ml', 1),
  ('d3a1c9a9-3010-506e-b0b5-9bfcf806e640', 'コンデンスミルク', 20, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('d3a1c9a9-3010-506e-b0b5-9bfcf806e640', 'ブレンダーに材料とクラッシュドアイスを入れる。', 0),
  ('d3a1c9a9-3010-506e-b0b5-9bfcf806e640', 'なめらかになるまで攪拌する。', 1),
  ('d3a1c9a9-3010-506e-b0b5-9bfcf806e640', '冷やしたグラスに注ぐ。', 2);

-- bay-breeze
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '8e7ba2ae-0825-5965-b895-0f3c50e6a1ca',
  'bay-breeze',
  'ベイブリーズ',
  'Bay Breeze',
  'ウォッカにクランベリーとパイナップルを合わせる、トロピカルな定番。',
  'Vodka',
  9,
  'United States',
  NULL,
  'none',
  ARRAY['ハワイアンシーブリーズ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'a7211dc1-ee20-51e5-9a7f-727d097ed2c6',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '8e7ba2ae-0825-5965-b895-0f3c50e6a1ca',
  'ベイブリーズ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'a7211dc1-ee20-51e5-9a7f-727d097ed2c6';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'a7211dc1-ee20-51e5-9a7f-727d097ed2c6';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('a7211dc1-ee20-51e5-9a7f-727d097ed2c6', 'ウォッカ', 45, 'ml', 0),
  ('a7211dc1-ee20-51e5-9a7f-727d097ed2c6', 'クランベリージュース', 90, 'ml', 1),
  ('a7211dc1-ee20-51e5-9a7f-727d097ed2c6', 'パイナップルジュース', 45, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('a7211dc1-ee20-51e5-9a7f-727d097ed2c6', 'グラスに氷を入れる。', 0),
  ('a7211dc1-ee20-51e5-9a7f-727d097ed2c6', '材料を順に注ぐ。', 1),
  ('a7211dc1-ee20-51e5-9a7f-727d097ed2c6', '軽く混ぜて仕上げる。', 2);

-- bees-knees
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '6045b947-0e96-5b41-b44a-c95621944ae6',
  'bees-knees',
  'ビーズニーズ',
  'Bee''s Knees',
  'ジン、レモン、はちみつシロップの禁酒法時代生まれのクラシック。はちみつのまろやかさが特徴。',
  'Gin',
  20,
  'United States',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '941089fe-a490-5744-af3c-082a759b5ca4',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '6045b947-0e96-5b41-b44a-c95621944ae6',
  'ビーズニーズ（基本レシピ）',
  'はちみつシロップははちみつと同量の湯で溶いて冷まして使う。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '941089fe-a490-5744-af3c-082a759b5ca4';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '941089fe-a490-5744-af3c-082a759b5ca4';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('941089fe-a490-5744-af3c-082a759b5ca4', 'ドライジン', 50, 'ml', 0),
  ('941089fe-a490-5744-af3c-082a759b5ca4', 'レモン果汁', 22.5, 'ml', 1),
  ('941089fe-a490-5744-af3c-082a759b5ca4', 'はちみつシロップ', 22.5, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('941089fe-a490-5744-af3c-082a759b5ca4', 'シェイカーに材料と氷を入れる。', 0),
  ('941089fe-a490-5744-af3c-082a759b5ca4', 'よくシェイクする。', 1),
  ('941089fe-a490-5744-af3c-082a759b5ca4', 'クーペグラスに注ぐ。', 2);

-- between-the-sheets
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'a30a5619-0d64-5519-ba1b-e1658f1aad15',
  'between-the-sheets',
  'ビトウィーンザシーツ',
  'Between the Sheets',
  'ラム、コニャック、ホワイトキュラソー、レモンを合わせるサイドカー系の古典。',
  'Rum',
  29,
  'France',
  NULL,
  'none',
  ARRAY['ビトウィーン・ザ・シーツ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '1ef1dfa7-e593-550f-ae8e-d8505553ebcf',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'a30a5619-0d64-5519-ba1b-e1658f1aad15',
  'ビトウィーンザシーツ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '1ef1dfa7-e593-550f-ae8e-d8505553ebcf';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '1ef1dfa7-e593-550f-ae8e-d8505553ebcf';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('1ef1dfa7-e593-550f-ae8e-d8505553ebcf', 'ライトラム', 30, 'ml', 0),
  ('1ef1dfa7-e593-550f-ae8e-d8505553ebcf', 'コニャック', 30, 'ml', 1),
  ('1ef1dfa7-e593-550f-ae8e-d8505553ebcf', 'ホワイトキュラソー', 30, 'ml', 2),
  ('1ef1dfa7-e593-550f-ae8e-d8505553ebcf', 'レモンジュース', 20, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('1ef1dfa7-e593-550f-ae8e-d8505553ebcf', 'シェーカーに材料と氷を入れる。', 0),
  ('1ef1dfa7-e593-550f-ae8e-d8505553ebcf', 'しっかりシェイクして冷やす。', 1),
  ('1ef1dfa7-e593-550f-ae8e-d8505553ebcf', '冷やしたグラスに注ぐ。', 2);

-- bijou
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '0eddff1d-654a-5f82-a257-fd353347f42f',
  'bijou',
  'ビジュー',
  'Bijou',
  'ジン、ベルモット、シャルトリューズを宝石になぞらえた芳醇なクラシック。',
  'Gin',
  31,
  'United States',
  NULL,
  'none',
  ARRAY['ビジューカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'e539b642-95da-5830-bac8-8f6ee5b117f9',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '0eddff1d-654a-5f82-a257-fd353347f42f',
  'ビジュー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'e539b642-95da-5830-bac8-8f6ee5b117f9';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'e539b642-95da-5830-bac8-8f6ee5b117f9';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('e539b642-95da-5830-bac8-8f6ee5b117f9', 'ドライジン', 30, 'ml', 0),
  ('e539b642-95da-5830-bac8-8f6ee5b117f9', 'スイートベルモット', 30, 'ml', 1),
  ('e539b642-95da-5830-bac8-8f6ee5b117f9', 'グリーンシャルトリューズ', 30, 'ml', 2),
  ('e539b642-95da-5830-bac8-8f6ee5b117f9', 'オレンジビターズ', 1, 'dash', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('e539b642-95da-5830-bac8-8f6ee5b117f9', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('e539b642-95da-5830-bac8-8f6ee5b117f9', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('e539b642-95da-5830-bac8-8f6ee5b117f9', '冷やしたグラスに注ぐ。', 2);

-- black-russian
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '2f70b240-173b-5799-ae0c-46e955aa7a78',
  'black-russian',
  'ブラックルシアン',
  'Black Russian',
  'ウォッカとコーヒーリキュールだけで作る、濃厚で甘い食後の一杯。',
  'Vodka',
  27,
  'Belgium',
  NULL,
  'none',
  ARRAY['ブラック・ルシアン']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '97a9f74f-b878-5033-bd99-0b943502b3d2',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '2f70b240-173b-5799-ae0c-46e955aa7a78',
  'ブラックルシアン（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '97a9f74f-b878-5033-bd99-0b943502b3d2';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '97a9f74f-b878-5033-bd99-0b943502b3d2';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('97a9f74f-b878-5033-bd99-0b943502b3d2', 'ウォッカ', 45, 'ml', 0),
  ('97a9f74f-b878-5033-bd99-0b943502b3d2', 'コーヒーリキュール', 25, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('97a9f74f-b878-5033-bd99-0b943502b3d2', 'グラスに氷を入れる。', 0),
  ('97a9f74f-b878-5033-bd99-0b943502b3d2', '材料を順に注ぐ。', 1),
  ('97a9f74f-b878-5033-bd99-0b943502b3d2', '軽く混ぜて仕上げる。', 2);

-- blood-and-sand
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '3f804884-c3ed-51e6-a022-7a77282648d1',
  'blood-and-sand',
  'ブラッドアンドサンド',
  'Blood and Sand',
  'スコッチ、チェリーブランデー、ベルモット、オレンジが均衡する映画由来の古典。',
  'Whisky',
  20,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['ブラッド＆サンド']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '883d8d28-2672-5036-a6d9-98ddc08f4406',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '3f804884-c3ed-51e6-a022-7a77282648d1',
  'ブラッドアンドサンド（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '883d8d28-2672-5036-a6d9-98ddc08f4406';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '883d8d28-2672-5036-a6d9-98ddc08f4406';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('883d8d28-2672-5036-a6d9-98ddc08f4406', 'スコッチウイスキー', 25, 'ml', 0),
  ('883d8d28-2672-5036-a6d9-98ddc08f4406', 'チェリーブランデー', 25, 'ml', 1),
  ('883d8d28-2672-5036-a6d9-98ddc08f4406', 'スイートベルモット', 25, 'ml', 2),
  ('883d8d28-2672-5036-a6d9-98ddc08f4406', 'オレンジジュース', 25, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('883d8d28-2672-5036-a6d9-98ddc08f4406', 'シェーカーに材料と氷を入れる。', 0),
  ('883d8d28-2672-5036-a6d9-98ddc08f4406', 'しっかりシェイクして冷やす。', 1),
  ('883d8d28-2672-5036-a6d9-98ddc08f4406', '冷やしたグラスに注ぐ。', 2);

-- bloody-mary
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'd7085ca7-9276-52bb-b9fb-fe6420b48c32',
  'bloody-mary',
  'ブラッディメアリー',
  'Bloody Mary',
  'ウォッカとトマトジュースをベースにしたスパイシーなロングドリンク。朝食カクテルの定番。',
  'Vodka',
  12,
  'France',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '8c0e59e2-d526-5b88-be45-c3f0b2326084',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'd7085ca7-9276-52bb-b9fb-fe6420b48c32',
  'ブラッディメアリー（基本レシピ）',
  'スパイスは好みで調整する。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '8c0e59e2-d526-5b88-be45-c3f0b2326084';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '8c0e59e2-d526-5b88-be45-c3f0b2326084';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('8c0e59e2-d526-5b88-be45-c3f0b2326084', 'ウォッカ', 45, 'ml', 0),
  ('8c0e59e2-d526-5b88-be45-c3f0b2326084', 'トマトジュース', 90, 'ml', 1),
  ('8c0e59e2-d526-5b88-be45-c3f0b2326084', 'レモン果汁', 15, 'ml', 2),
  ('8c0e59e2-d526-5b88-be45-c3f0b2326084', 'ウスターソース', 2, 'dash', 3),
  ('8c0e59e2-d526-5b88-be45-c3f0b2326084', 'タバスコ', 2, 'dash', 4),
  ('8c0e59e2-d526-5b88-be45-c3f0b2326084', '塩・こしょう', NULL, NULL, 5);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('8c0e59e2-d526-5b88-be45-c3f0b2326084', 'ハイボールグラスに氷を入れる。', 0),
  ('8c0e59e2-d526-5b88-be45-c3f0b2326084', '材料をすべて注ぎ、軽く混ぜる。', 1),
  ('8c0e59e2-d526-5b88-be45-c3f0b2326084', 'セロリやレモンスライスを飾る。', 2);

-- blue-lagoon
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'd1d05336-3a48-5478-94c6-ddd9a6a44bc9',
  'blue-lagoon',
  'ブルーラグーン',
  'Blue Lagoon',
  'ウォッカ、ブルーキュラソー、レモネードで作る鮮やかな青のロングカクテル。',
  'Vodka',
  10,
  'France',
  NULL,
  'none',
  ARRAY['ブルー・ラグーン']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '9747afa6-db05-5ec3-8799-2a3a25efa9be',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'd1d05336-3a48-5478-94c6-ddd9a6a44bc9',
  'ブルーラグーン（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '9747afa6-db05-5ec3-8799-2a3a25efa9be';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '9747afa6-db05-5ec3-8799-2a3a25efa9be';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('9747afa6-db05-5ec3-8799-2a3a25efa9be', 'ウォッカ', 40, 'ml', 0),
  ('9747afa6-db05-5ec3-8799-2a3a25efa9be', 'ブルーキュラソー', 20, 'ml', 1),
  ('9747afa6-db05-5ec3-8799-2a3a25efa9be', 'レモネード', 120, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('9747afa6-db05-5ec3-8799-2a3a25efa9be', 'グラスに氷を入れる。', 0),
  ('9747afa6-db05-5ec3-8799-2a3a25efa9be', '材料を順に注ぐ。', 1),
  ('9747afa6-db05-5ec3-8799-2a3a25efa9be', '軽く混ぜて仕上げる。', 2);

-- boulevardier
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'a31f75ce-222f-53f4-a62d-c7557087640f',
  'boulevardier',
  'ブールヴァルディエ',
  'Boulevardier',
  'バーボン、カンパリ、ベルモットで作る、ネグローニのウイスキー版。',
  'Whisky',
  27,
  'France',
  NULL,
  'none',
  ARRAY['ブルヴァルディエ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '6d20de9f-54a5-59e4-9866-6e060f6f157b',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'a31f75ce-222f-53f4-a62d-c7557087640f',
  'ブールヴァルディエ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '6d20de9f-54a5-59e4-9866-6e060f6f157b';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '6d20de9f-54a5-59e4-9866-6e060f6f157b';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('6d20de9f-54a5-59e4-9866-6e060f6f157b', 'バーボンウイスキー', 45, 'ml', 0),
  ('6d20de9f-54a5-59e4-9866-6e060f6f157b', 'カンパリ', 30, 'ml', 1),
  ('6d20de9f-54a5-59e4-9866-6e060f6f157b', 'スイートベルモット', 30, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('6d20de9f-54a5-59e4-9866-6e060f6f157b', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('6d20de9f-54a5-59e4-9866-6e060f6f157b', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('6d20de9f-54a5-59e4-9866-6e060f6f157b', '冷やしたグラスに注ぐ。', 2);

-- bramble
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'f62ce1c4-e13a-5d9c-b449-3b25c9407d8c',
  'bramble',
  'ブランブル',
  'Bramble',
  'ジンの酸味にブラックベリーリキュールを流す、ロンドン発のモダンクラシック。',
  'Gin',
  18,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['ブランブルカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '3ff112d6-1869-594f-9a1a-29693a86c0ca',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'f62ce1c4-e13a-5d9c-b449-3b25c9407d8c',
  'ブランブル（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '3ff112d6-1869-594f-9a1a-29693a86c0ca';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '3ff112d6-1869-594f-9a1a-29693a86c0ca';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('3ff112d6-1869-594f-9a1a-29693a86c0ca', 'ドライジン', 45, 'ml', 0),
  ('3ff112d6-1869-594f-9a1a-29693a86c0ca', 'レモンジュース', 20, 'ml', 1),
  ('3ff112d6-1869-594f-9a1a-29693a86c0ca', 'シュガーシロップ', 10, 'ml', 2),
  ('3ff112d6-1869-594f-9a1a-29693a86c0ca', 'クレーム・ド・ミュール', 15, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('3ff112d6-1869-594f-9a1a-29693a86c0ca', 'シェーカーに材料と氷を入れる。', 0),
  ('3ff112d6-1869-594f-9a1a-29693a86c0ca', 'しっかりシェイクして冷やす。', 1),
  ('3ff112d6-1869-594f-9a1a-29693a86c0ca', '冷やしたグラスに注ぐ。', 2);

-- brandy-alexander
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '282a20e9-dc9b-59da-8240-734729d52275',
  'brandy-alexander',
  'ブランデーアレキサンダー',
  'Brandy Alexander',
  'ブランデー、カカオ、クリームで作る、なめらかなデザートカクテル。',
  'Brandy',
  18,
  'United States',
  NULL,
  'none',
  ARRAY['ブランデーアレクサンダー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '4d4fa6ee-16d9-5647-a39c-d630c97acf8b',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '282a20e9-dc9b-59da-8240-734729d52275',
  'ブランデーアレキサンダー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '4d4fa6ee-16d9-5647-a39c-d630c97acf8b';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '4d4fa6ee-16d9-5647-a39c-d630c97acf8b';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('4d4fa6ee-16d9-5647-a39c-d630c97acf8b', 'ブランデー', 30, 'ml', 0),
  ('4d4fa6ee-16d9-5647-a39c-d630c97acf8b', 'クレーム・ド・カカオ', 30, 'ml', 1),
  ('4d4fa6ee-16d9-5647-a39c-d630c97acf8b', '生クリーム', 30, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('4d4fa6ee-16d9-5647-a39c-d630c97acf8b', 'シェーカーに材料と氷を入れる。', 0),
  ('4d4fa6ee-16d9-5647-a39c-d630c97acf8b', 'しっかりシェイクして冷やす。', 1),
  ('4d4fa6ee-16d9-5647-a39c-d630c97acf8b', '冷やしたグラスに注ぐ。', 2);

-- brandy-crusta
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '71ad5d98-739f-5c39-a223-6c634abb19a3',
  'brandy-crusta',
  'ブランデークラスタ',
  'Brandy Crusta',
  'ブランデー、キュラソー、レモン、ビターズを砂糖の縁で飾る19世紀の古典。',
  'Brandy',
  26,
  'United States',
  NULL,
  'none',
  ARRAY['ブランデー・クラスタ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '43c550a5-ba2f-5ac8-ade9-67749e1a9ffe',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '71ad5d98-739f-5c39-a223-6c634abb19a3',
  'ブランデークラスタ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '43c550a5-ba2f-5ac8-ade9-67749e1a9ffe';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '43c550a5-ba2f-5ac8-ade9-67749e1a9ffe';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('43c550a5-ba2f-5ac8-ade9-67749e1a9ffe', 'ブランデー', 50, 'ml', 0),
  ('43c550a5-ba2f-5ac8-ade9-67749e1a9ffe', 'オレンジキュラソー', 10, 'ml', 1),
  ('43c550a5-ba2f-5ac8-ade9-67749e1a9ffe', 'マラスキーノリキュール', 5, 'ml', 2),
  ('43c550a5-ba2f-5ac8-ade9-67749e1a9ffe', 'レモンジュース', 15, 'ml', 3),
  ('43c550a5-ba2f-5ac8-ade9-67749e1a9ffe', 'アンゴスチュラビターズ', 2, 'dash', 4),
  ('43c550a5-ba2f-5ac8-ade9-67749e1a9ffe', '砂糖', 1, 'tsp', 5);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('43c550a5-ba2f-5ac8-ade9-67749e1a9ffe', 'シェーカーに材料と氷を入れる。', 0),
  ('43c550a5-ba2f-5ac8-ade9-67749e1a9ffe', 'しっかりシェイクして冷やす。', 1),
  ('43c550a5-ba2f-5ac8-ade9-67749e1a9ffe', '冷やしたグラスに注ぐ。', 2);

-- brave-bull
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '717be5f3-a922-5783-9520-73d147e877ea',
  'brave-bull',
  'ブレイブブル',
  'Brave Bull',
  'テキーラとコーヒーリキュールを合わせる、ブラックルシアンのテキーラ版。',
  'Tequila',
  28,
  'Mexico',
  NULL,
  'none',
  ARRAY['ブレイブ・ブル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '25b55fcd-259c-521a-bada-2dc7764401db',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '717be5f3-a922-5783-9520-73d147e877ea',
  'ブレイブブル（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '25b55fcd-259c-521a-bada-2dc7764401db';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '25b55fcd-259c-521a-bada-2dc7764401db';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('25b55fcd-259c-521a-bada-2dc7764401db', 'テキーラレポサド', 45, 'ml', 0),
  ('25b55fcd-259c-521a-bada-2dc7764401db', 'コーヒーリキュール', 25, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('25b55fcd-259c-521a-bada-2dc7764401db', 'グラスに氷を入れる。', 0),
  ('25b55fcd-259c-521a-bada-2dc7764401db', '材料を順に注ぐ。', 1),
  ('25b55fcd-259c-521a-bada-2dc7764401db', '軽く混ぜて仕上げる。', 2);

-- brown-derby
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '98f0be90-3d9f-5644-83a5-812a710caf32',
  'brown-derby',
  'ブラウンダービー',
  'Brown Derby',
  'バーボンにグレープフルーツと蜂蜜を合わせる、ハリウッド黄金期のカクテル。',
  'Whisky',
  22,
  'United States',
  NULL,
  'none',
  ARRAY['ブラウン・ダービー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '968efd4a-f318-5501-99f0-262531ae6d01',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '98f0be90-3d9f-5644-83a5-812a710caf32',
  'ブラウンダービー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '968efd4a-f318-5501-99f0-262531ae6d01';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '968efd4a-f318-5501-99f0-262531ae6d01';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('968efd4a-f318-5501-99f0-262531ae6d01', 'バーボンウイスキー', 45, 'ml', 0),
  ('968efd4a-f318-5501-99f0-262531ae6d01', 'グレープフルーツジュース', 30, 'ml', 1),
  ('968efd4a-f318-5501-99f0-262531ae6d01', '蜂蜜シロップ', 15, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('968efd4a-f318-5501-99f0-262531ae6d01', 'シェーカーに材料と氷を入れる。', 0),
  ('968efd4a-f318-5501-99f0-262531ae6d01', 'しっかりシェイクして冷やす。', 1),
  ('968efd4a-f318-5501-99f0-262531ae6d01', '冷やしたグラスに注ぐ。', 2);

-- cable-car
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'a63f5b0f-c4a6-54b3-adb2-af969ecc6688',
  'cable-car',
  'ケーブルカー',
  'Cable Car',
  'スパイスドラム、オレンジキュラソー、レモンを合わせるサンフランシスコ生まれのモダンカクテル。',
  'Rum',
  23,
  'United States',
  NULL,
  'none',
  ARRAY['ケーブル・カー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '5e480865-189d-5185-8c1c-893400affb2c',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'a63f5b0f-c4a6-54b3-adb2-af969ecc6688',
  'ケーブルカー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '5e480865-189d-5185-8c1c-893400affb2c';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '5e480865-189d-5185-8c1c-893400affb2c';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('5e480865-189d-5185-8c1c-893400affb2c', 'スパイスドラム', 45, 'ml', 0),
  ('5e480865-189d-5185-8c1c-893400affb2c', 'オレンジキュラソー', 20, 'ml', 1),
  ('5e480865-189d-5185-8c1c-893400affb2c', 'レモンジュース', 20, 'ml', 2),
  ('5e480865-189d-5185-8c1c-893400affb2c', 'シュガーシロップ', 10, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('5e480865-189d-5185-8c1c-893400affb2c', 'シェーカーに材料と氷を入れる。', 0),
  ('5e480865-189d-5185-8c1c-893400affb2c', 'しっかりシェイクして冷やす。', 1),
  ('5e480865-189d-5185-8c1c-893400affb2c', '冷やしたグラスに注ぐ。', 2);

-- caipirinha
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'a94eb749-8783-537a-9949-6142cb6336de',
  'caipirinha',
  'カイピリーニャ',
  'Caipirinha',
  'カシャッサ、ライム、砂糖で作るブラジルの国民的カクテル。果皮の香りが決め手。',
  'Cachaca',
  20,
  'Brazil',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'd299819a-fca3-5b51-9cf7-6989a4511d4d',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'a94eb749-8783-537a-9949-6142cb6336de',
  'カイピリーニャ（基本レシピ）',
  '白い部分の苦味が強いときは種と白い皮を取り除く。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'd299819a-fca3-5b51-9cf7-6989a4511d4d';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'd299819a-fca3-5b51-9cf7-6989a4511d4d';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('d299819a-fca3-5b51-9cf7-6989a4511d4d', 'カシャッサ', 60, 'ml', 0),
  ('d299819a-fca3-5b51-9cf7-6989a4511d4d', 'ライム', 1, 'piece', 1),
  ('d299819a-fca3-5b51-9cf7-6989a4511d4d', '砂糖', 2, 'tsp', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('d299819a-fca3-5b51-9cf7-6989a4511d4d', 'ライムをくし切りにし、グラスで砂糖と軽く潰す。', 0),
  ('d299819a-fca3-5b51-9cf7-6989a4511d4d', '砕氷を入れる。', 1),
  ('d299819a-fca3-5b51-9cf7-6989a4511d4d', 'カシャッサを注ぎ、軽く混ぜる。', 2);

-- caipiroska
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'fca7f57d-a2bb-57b0-88a1-761ad4f8a234',
  'caipiroska',
  'カイピロスカ',
  'Caipiroska',
  'カイピリーニャをウォッカで作る、ライムの香りが主役のクラッシュドアイスカクテル。',
  'Vodka',
  18,
  'Brazil',
  NULL,
  'none',
  ARRAY['カイピロシュカ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '9f2b10f3-da9b-5437-ab89-5d6939ca1e2d',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'fca7f57d-a2bb-57b0-88a1-761ad4f8a234',
  'カイピロスカ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '9f2b10f3-da9b-5437-ab89-5d6939ca1e2d';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '9f2b10f3-da9b-5437-ab89-5d6939ca1e2d';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('9f2b10f3-da9b-5437-ab89-5d6939ca1e2d', 'ウォッカ', 60, 'ml', 0),
  ('9f2b10f3-da9b-5437-ab89-5d6939ca1e2d', 'ライム', 0.5, 'piece', 1),
  ('9f2b10f3-da9b-5437-ab89-5d6939ca1e2d', '砂糖', 2, 'tsp', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('9f2b10f3-da9b-5437-ab89-5d6939ca1e2d', 'グラスの中でフルーツやハーブを軽くつぶす。', 0),
  ('9f2b10f3-da9b-5437-ab89-5d6939ca1e2d', '残りの材料と氷を加える。', 1),
  ('9f2b10f3-da9b-5437-ab89-5d6939ca1e2d', 'よく混ぜて仕上げる。', 2);

-- calpis-sour
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'dbda4db0-8b7e-584d-aed6-d4b788204afa',
  'calpis-sour',
  'カルピスサワー',
  'Calpis Sour',
  '焼酎にカルピスと炭酸を合わせる、やさしい甘酸っぱさの定番サワー。',
  'Shochu',
  6,
  'Japan',
  NULL,
  'none',
  ARRAY['カルピスチューハイ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '362219cf-46f1-595f-b163-1521d1148327',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'dbda4db0-8b7e-584d-aed6-d4b788204afa',
  'カルピスサワー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '362219cf-46f1-595f-b163-1521d1148327';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '362219cf-46f1-595f-b163-1521d1148327';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('362219cf-46f1-595f-b163-1521d1148327', '焼酎', 45, 'ml', 0),
  ('362219cf-46f1-595f-b163-1521d1148327', 'カルピス', 45, 'ml', 1),
  ('362219cf-46f1-595f-b163-1521d1148327', 'ソーダ', 120, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('362219cf-46f1-595f-b163-1521d1148327', 'グラスに氷を入れる。', 0),
  ('362219cf-46f1-595f-b163-1521d1148327', '材料を順に注ぐ。', 1),
  ('362219cf-46f1-595f-b163-1521d1148327', '軽く混ぜて仕上げる。', 2);

-- campari-soda
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '198e5bf1-7570-5aac-bb8a-04688ed67ffb',
  'campari-soda',
  'カンパリソーダ',
  'Campari Soda',
  'カンパリをソーダで割る、ビターで軽いイタリアの定番アペリティーボ。',
  'Liqueur',
  7,
  'Italy',
  NULL,
  'none',
  ARRAY['カンパリ・ソーダ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'bbcdb181-0984-5a58-836c-7a3a6f5f92ce',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '198e5bf1-7570-5aac-bb8a-04688ed67ffb',
  'カンパリソーダ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'bbcdb181-0984-5a58-836c-7a3a6f5f92ce';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'bbcdb181-0984-5a58-836c-7a3a6f5f92ce';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('bbcdb181-0984-5a58-836c-7a3a6f5f92ce', 'カンパリ', 45, 'ml', 0),
  ('bbcdb181-0984-5a58-836c-7a3a6f5f92ce', 'ソーダ', 135, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('bbcdb181-0984-5a58-836c-7a3a6f5f92ce', 'グラスに氷を入れる。', 0),
  ('bbcdb181-0984-5a58-836c-7a3a6f5f92ce', '材料を順に注ぐ。', 1),
  ('bbcdb181-0984-5a58-836c-7a3a6f5f92ce', '軽く混ぜて仕上げる。', 2);

-- cantarito
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '26f32a33-6f0e-58b8-8adc-37148bf49abc',
  'cantarito',
  'カンタリート',
  'Cantarito',
  'テキーラに複数の柑橘とグレープフルーツソーダを合わせる、ハリスコ州の定番。',
  'Tequila',
  9,
  'Mexico',
  NULL,
  'none',
  ARRAY['カンタリートス']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'd2595b42-15c8-53eb-8d46-22855b138fd5',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '26f32a33-6f0e-58b8-8adc-37148bf49abc',
  'カンタリート（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'd2595b42-15c8-53eb-8d46-22855b138fd5';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'd2595b42-15c8-53eb-8d46-22855b138fd5';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('d2595b42-15c8-53eb-8d46-22855b138fd5', 'テキーラブランコ', 45, 'ml', 0),
  ('d2595b42-15c8-53eb-8d46-22855b138fd5', 'オレンジジュース', 30, 'ml', 1),
  ('d2595b42-15c8-53eb-8d46-22855b138fd5', 'グレープフルーツジュース', 30, 'ml', 2),
  ('d2595b42-15c8-53eb-8d46-22855b138fd5', 'ライムジュース', 15, 'ml', 3),
  ('d2595b42-15c8-53eb-8d46-22855b138fd5', 'グレープフルーツソーダ', 90, 'ml', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('d2595b42-15c8-53eb-8d46-22855b138fd5', 'グラスに氷を入れる。', 0),
  ('d2595b42-15c8-53eb-8d46-22855b138fd5', '材料を順に注ぐ。', 1),
  ('d2595b42-15c8-53eb-8d46-22855b138fd5', '軽く混ぜて仕上げる。', 2);

-- cape-codder
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'da773240-6f83-5814-b86c-50bfad260b30',
  'cape-codder',
  'ケープコッダー',
  'Cape Codder',
  'ウォッカとクランベリージュースで作る、シンプルなアメリカ定番ロングカクテル。',
  'Vodka',
  9,
  'United States',
  NULL,
  'none',
  ARRAY['ウォッカクランベリー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'bc8c7b11-620a-5231-8f54-ce27332536ba',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'da773240-6f83-5814-b86c-50bfad260b30',
  'ケープコッダー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'bc8c7b11-620a-5231-8f54-ce27332536ba';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'bc8c7b11-620a-5231-8f54-ce27332536ba';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('bc8c7b11-620a-5231-8f54-ce27332536ba', 'ウォッカ', 45, 'ml', 0),
  ('bc8c7b11-620a-5231-8f54-ce27332536ba', 'クランベリージュース', 135, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('bc8c7b11-620a-5231-8f54-ce27332536ba', 'グラスに氷を入れる。', 0),
  ('bc8c7b11-620a-5231-8f54-ce27332536ba', '材料を順に注ぐ。', 1),
  ('bc8c7b11-620a-5231-8f54-ce27332536ba', '軽く混ぜて仕上げる。', 2);

-- cassis-orange
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '34ae35a1-4222-543d-9b11-aca30ca3133f',
  'cassis-orange',
  'カシスオレンジ',
  'Cassis Orange',
  'カシスリキュールをオレンジジュースで割る、日本のバーでも定番の甘酸っぱい一杯。',
  'Liqueur',
  6,
  'Japan',
  NULL,
  'none',
  ARRAY['カシオレ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'c6040c10-edcd-5417-bbbb-bf79e7c5e5b1',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '34ae35a1-4222-543d-9b11-aca30ca3133f',
  'カシスオレンジ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'c6040c10-edcd-5417-bbbb-bf79e7c5e5b1';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'c6040c10-edcd-5417-bbbb-bf79e7c5e5b1';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('c6040c10-edcd-5417-bbbb-bf79e7c5e5b1', 'クレーム・ド・カシス', 45, 'ml', 0),
  ('c6040c10-edcd-5417-bbbb-bf79e7c5e5b1', 'オレンジジュース', 135, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('c6040c10-edcd-5417-bbbb-bf79e7c5e5b1', 'グラスに氷を入れる。', 0),
  ('c6040c10-edcd-5417-bbbb-bf79e7c5e5b1', '材料を順に注ぐ。', 1),
  ('c6040c10-edcd-5417-bbbb-bf79e7c5e5b1', '軽く混ぜて仕上げる。', 2);

-- champagne-cocktail
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '61a2c7d3-766f-5c9b-956d-2f31a87f381a',
  'champagne-cocktail',
  'シャンパンカクテル',
  'Champagne Cocktail',
  '角砂糖、ビターズ、ブランデー、シャンパンで作る祝祭感のあるクラシック。',
  'Brandy',
  14,
  'United States',
  NULL,
  'none',
  ARRAY['シャンペンカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'd754aec4-4efa-5efe-a0de-a1158103278d',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '61a2c7d3-766f-5c9b-956d-2f31a87f381a',
  'シャンパンカクテル（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'd754aec4-4efa-5efe-a0de-a1158103278d';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'd754aec4-4efa-5efe-a0de-a1158103278d';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('d754aec4-4efa-5efe-a0de-a1158103278d', '角砂糖', 1, 'piece', 0),
  ('d754aec4-4efa-5efe-a0de-a1158103278d', 'アンゴスチュラビターズ', 2, 'dash', 1),
  ('d754aec4-4efa-5efe-a0de-a1158103278d', 'ブランデー', 15, 'ml', 2),
  ('d754aec4-4efa-5efe-a0de-a1158103278d', 'シャンパン', 120, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('d754aec4-4efa-5efe-a0de-a1158103278d', 'グラスに氷を入れる。', 0),
  ('d754aec4-4efa-5efe-a0de-a1158103278d', '材料を順に注ぐ。', 1),
  ('d754aec4-4efa-5efe-a0de-a1158103278d', '軽く混ぜて仕上げる。', 2);

-- chi-chi
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '55c5cbf0-35d6-58f5-b36c-9e2ae7d98082',
  'chi-chi',
  'チチ',
  'Chi-Chi',
  'ピニャコラーダをウォッカで作る、ココナッツとパイナップルのトロピカルカクテル。',
  'Vodka',
  11,
  'United States',
  NULL,
  'none',
  ARRAY['チチカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'ffcba75f-c218-5c00-b26a-83057075c240',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '55c5cbf0-35d6-58f5-b36c-9e2ae7d98082',
  'チチ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'ffcba75f-c218-5c00-b26a-83057075c240';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'ffcba75f-c218-5c00-b26a-83057075c240';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('ffcba75f-c218-5c00-b26a-83057075c240', 'ウォッカ', 45, 'ml', 0),
  ('ffcba75f-c218-5c00-b26a-83057075c240', 'パイナップルジュース', 90, 'ml', 1),
  ('ffcba75f-c218-5c00-b26a-83057075c240', 'ココナッツクリーム', 30, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('ffcba75f-c218-5c00-b26a-83057075c240', 'ブレンダーに材料とクラッシュドアイスを入れる。', 0),
  ('ffcba75f-c218-5c00-b26a-83057075c240', 'なめらかになるまで攪拌する。', 1),
  ('ffcba75f-c218-5c00-b26a-83057075c240', '冷やしたグラスに注ぐ。', 2);

-- chuhai
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '76b32382-a52d-562a-9775-2a18b06b0701',
  'chuhai',
  '酎ハイ',
  'Chuhai',
  '焼酎を炭酸で割る、各種サワーのベースにもなる日本のロングドリンク。',
  'Shochu',
  7,
  'Japan',
  NULL,
  'none',
  ARRAY['チューハイ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '5b288517-87b0-5805-8875-422e19d452ed',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '76b32382-a52d-562a-9775-2a18b06b0701',
  '酎ハイ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '5b288517-87b0-5805-8875-422e19d452ed';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '5b288517-87b0-5805-8875-422e19d452ed';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('5b288517-87b0-5805-8875-422e19d452ed', '焼酎', 45, 'ml', 0),
  ('5b288517-87b0-5805-8875-422e19d452ed', 'ソーダ', 135, 'ml', 1),
  ('5b288517-87b0-5805-8875-422e19d452ed', 'レモン', 0.125, 'piece', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('5b288517-87b0-5805-8875-422e19d452ed', 'グラスに氷を入れる。', 0),
  ('5b288517-87b0-5805-8875-422e19d452ed', '材料を順に注ぐ。', 1),
  ('5b288517-87b0-5805-8875-422e19d452ed', '軽く混ぜて仕上げる。', 2);

-- clover-club
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b505afa3-bdb5-5ec2-a4ba-f0888e2eddb2',
  'clover-club',
  'クローバークラブ',
  'Clover Club',
  'ラズベリーと卵白のなめらかな泡で仕上げる、フィラデルフィア発祥の名作。',
  'Gin',
  20,
  'United States',
  NULL,
  'none',
  ARRAY['クローバー・クラブ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '78bf2141-173e-5d36-aafc-3d625903d480',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b505afa3-bdb5-5ec2-a4ba-f0888e2eddb2',
  'クローバークラブ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '78bf2141-173e-5d36-aafc-3d625903d480';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '78bf2141-173e-5d36-aafc-3d625903d480';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('78bf2141-173e-5d36-aafc-3d625903d480', 'ドライジン', 45, 'ml', 0),
  ('78bf2141-173e-5d36-aafc-3d625903d480', 'レモンジュース', 20, 'ml', 1),
  ('78bf2141-173e-5d36-aafc-3d625903d480', 'ラズベリーシロップ', 15, 'ml', 2),
  ('78bf2141-173e-5d36-aafc-3d625903d480', '卵白', 1, 'piece', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('78bf2141-173e-5d36-aafc-3d625903d480', 'シェーカーに材料と氷を入れる。', 0),
  ('78bf2141-173e-5d36-aafc-3d625903d480', 'しっかりシェイクして冷やす。', 1),
  ('78bf2141-173e-5d36-aafc-3d625903d480', '冷やしたグラスに注ぐ。', 2);

-- coffee-shochu
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '483a4013-be33-5f2b-b357-b949e44f32c3',
  'coffee-shochu',
  'コーヒー焼酎',
  'Coffee Shochu',
  '焼酎をコーヒーで割る、香ばしさと苦味が楽しめる日本のバー定番。',
  'Shochu',
  8,
  'Japan',
  NULL,
  'none',
  ARRAY['焼酎コーヒー割り']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'd2c99869-d9a6-54fa-8ef1-9276bb24bca2',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '483a4013-be33-5f2b-b357-b949e44f32c3',
  'コーヒー焼酎（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'd2c99869-d9a6-54fa-8ef1-9276bb24bca2';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'd2c99869-d9a6-54fa-8ef1-9276bb24bca2';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('d2c99869-d9a6-54fa-8ef1-9276bb24bca2', '焼酎', 45, 'ml', 0),
  ('d2c99869-d9a6-54fa-8ef1-9276bb24bca2', 'アイスコーヒー', 120, 'ml', 1),
  ('d2c99869-d9a6-54fa-8ef1-9276bb24bca2', 'シュガーシロップ', 5, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('d2c99869-d9a6-54fa-8ef1-9276bb24bca2', 'グラスに氷を入れる。', 0),
  ('d2c99869-d9a6-54fa-8ef1-9276bb24bca2', '材料を順に注ぐ。', 1),
  ('d2c99869-d9a6-54fa-8ef1-9276bb24bca2', '軽く混ぜて仕上げる。', 2);

-- corpse-reviver-no-2
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '8e12b843-2f1c-537e-8365-8bd86437bea4',
  'corpse-reviver-no-2',
  'コープスリバイバーNo.2',
  'Corpse Reviver No. 2',
  'ジンとキナリキュール、オレンジ、レモンが均衡するブランチの古典。',
  'Gin',
  24,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['コープス・リバイバー2']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '32d86d80-6cda-52e0-b893-de1c0ec40b30',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '8e12b843-2f1c-537e-8365-8bd86437bea4',
  'コープスリバイバーNo.2（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '32d86d80-6cda-52e0-b893-de1c0ec40b30';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '32d86d80-6cda-52e0-b893-de1c0ec40b30';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('32d86d80-6cda-52e0-b893-de1c0ec40b30', 'ドライジン', 22.5, 'ml', 0),
  ('32d86d80-6cda-52e0-b893-de1c0ec40b30', 'コアントロー', 22.5, 'ml', 1),
  ('32d86d80-6cda-52e0-b893-de1c0ec40b30', 'リレ・ブラン', 22.5, 'ml', 2),
  ('32d86d80-6cda-52e0-b893-de1c0ec40b30', 'レモンジュース', 22.5, 'ml', 3),
  ('32d86d80-6cda-52e0-b893-de1c0ec40b30', 'アブサン', 1, 'dash', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('32d86d80-6cda-52e0-b893-de1c0ec40b30', 'シェーカーに材料と氷を入れる。', 0),
  ('32d86d80-6cda-52e0-b893-de1c0ec40b30', 'しっかりシェイクして冷やす。', 1),
  ('32d86d80-6cda-52e0-b893-de1c0ec40b30', '冷やしたグラスに注ぐ。', 2);

-- cosmopolitan
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '778eb6aa-6c16-57b6-b322-c84e61fc00f6',
  'cosmopolitan',
  'コスモポリタン',
  'Cosmopolitan',
  'ウォッカ、コアントロー、クランベリー、ライムをシェイクした鮮やかなピンクのモダンクラシック。',
  'Vodka',
  20,
  'United States',
  NULL,
  'none',
  ARRAY['コスモ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '102cd2c2-16b9-5091-8992-f106e3220db2',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '778eb6aa-6c16-57b6-b322-c84e61fc00f6',
  'コスモポリタン（基本レシピ）',
  NULL,
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '102cd2c2-16b9-5091-8992-f106e3220db2';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '102cd2c2-16b9-5091-8992-f106e3220db2';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('102cd2c2-16b9-5091-8992-f106e3220db2', 'シトラスウォッカ', 40, 'ml', 0),
  ('102cd2c2-16b9-5091-8992-f106e3220db2', 'コアントロー', 15, 'ml', 1),
  ('102cd2c2-16b9-5091-8992-f106e3220db2', 'クランベリージュース', 30, 'ml', 2),
  ('102cd2c2-16b9-5091-8992-f106e3220db2', 'ライム果汁', 10, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('102cd2c2-16b9-5091-8992-f106e3220db2', 'シェイカーに材料と氷を入れる。', 0),
  ('102cd2c2-16b9-5091-8992-f106e3220db2', 'よくシェイクする。', 1),
  ('102cd2c2-16b9-5091-8992-f106e3220db2', 'クーペグラスに注ぎ、オレンジピールを飾る。', 2);

-- cuba-libre
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '1c106b40-ba86-5394-870f-8b0dd7cd0c0a',
  'cuba-libre',
  'キューバリブレ',
  'Cuba Libre',
  'ラムとコーラ、ライムで作るシンプルなロングドリンク。自由を願う名を持つキューバの定番。',
  'Rum',
  10,
  'Cuba',
  NULL,
  'none',
  ARRAY['ラムコーラ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '604f887f-374d-5685-8fe3-ee69758faa78',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '1c106b40-ba86-5394-870f-8b0dd7cd0c0a',
  'キューバリブレ（基本レシピ）',
  NULL,
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '604f887f-374d-5685-8fe3-ee69758faa78';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '604f887f-374d-5685-8fe3-ee69758faa78';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('604f887f-374d-5685-8fe3-ee69758faa78', 'ホワイトラム', 45, 'ml', 0),
  ('604f887f-374d-5685-8fe3-ee69758faa78', 'コーラ', 120, 'ml', 1),
  ('604f887f-374d-5685-8fe3-ee69758faa78', 'ライム果汁', 10, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('604f887f-374d-5685-8fe3-ee69758faa78', 'グラスに氷を入れる。', 0),
  ('604f887f-374d-5685-8fe3-ee69758faa78', 'ラムとライム果汁を注ぐ。', 1),
  ('604f887f-374d-5685-8fe3-ee69758faa78', 'コーラを注ぎ、軽く混ぜる。', 2);

-- daiquiri
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '9da36ee6-d5cc-55e2-9c17-badb0e8d24d0',
  'daiquiri',
  'ダイキリ',
  'Daiquiri',
  'ホワイトラム、ライム、砂糖の三素材で構成されるキューバの名作。シンプルゆえにバランスが命。',
  'Rum',
  22,
  'Cuba',
  NULL,
  'none',
  ARRAY['ダイキリ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'd03f7b55-7490-5369-96b1-39260a3175e5',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '9da36ee6-d5cc-55e2-9c17-badb0e8d24d0',
  'ダイキリ（基本レシピ）',
  '甘酸っぱさのバランスを好みで微調整する。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'd03f7b55-7490-5369-96b1-39260a3175e5';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'd03f7b55-7490-5369-96b1-39260a3175e5';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('d03f7b55-7490-5369-96b1-39260a3175e5', 'ホワイトラム', 45, 'ml', 0),
  ('d03f7b55-7490-5369-96b1-39260a3175e5', 'ライム果汁', 22.5, 'ml', 1),
  ('d03f7b55-7490-5369-96b1-39260a3175e5', 'シュガーシロップ', 15, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('d03f7b55-7490-5369-96b1-39260a3175e5', 'シェイカーに材料と氷を入れる。', 0),
  ('d03f7b55-7490-5369-96b1-39260a3175e5', 'しっかりシェイクする。', 1),
  ('d03f7b55-7490-5369-96b1-39260a3175e5', 'クーペグラスに注ぐ。', 2);

-- dark-and-stormy
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '03144710-ee0a-5810-9421-060e36db0a20',
  'dark-and-stormy',
  'ダークアンドストーミー',
  'Dark and Stormy',
  'ダークラムとジンジャービアで作る、バミューダを代表するスパイシーなハイボール。',
  'Rum',
  11,
  'Bermuda',
  NULL,
  'none',
  ARRAY['ダーク＆ストーミー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'e4451837-5183-54a0-9ee3-666d147e9044',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '03144710-ee0a-5810-9421-060e36db0a20',
  'ダークアンドストーミー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'e4451837-5183-54a0-9ee3-666d147e9044';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'e4451837-5183-54a0-9ee3-666d147e9044';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('e4451837-5183-54a0-9ee3-666d147e9044', 'ダークラム', 60, 'ml', 0),
  ('e4451837-5183-54a0-9ee3-666d147e9044', 'ジンジャービア', 120, 'ml', 1),
  ('e4451837-5183-54a0-9ee3-666d147e9044', 'ライムジュース', 10, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('e4451837-5183-54a0-9ee3-666d147e9044', 'グラスに氷を入れる。', 0),
  ('e4451837-5183-54a0-9ee3-666d147e9044', '材料を順に注ぐ。', 1),
  ('e4451837-5183-54a0-9ee3-666d147e9044', '軽く混ぜて仕上げる。', 2);

-- dry-martini
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'e23aa9eb-7fac-5b55-a09c-3983c6c8d948',
  'dry-martini',
  'ドライマティーニ',
  'Dry Martini',
  'ジンとドライベルモットをステアしたカクテルの王様。比率とステアの加減で個性が出る。',
  'Gin',
  30,
  'United States',
  NULL,
  'none',
  ARRAY['マティーニ', 'Martini']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '38dd5c32-8f8f-52c3-aa65-2a6c39f66abf',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'e23aa9eb-7fac-5b55-a09c-3983c6c8d948',
  'ドライマティーニ（基本レシピ）',
  'グラスはあらかじめ冷やしておく。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '38dd5c32-8f8f-52c3-aa65-2a6c39f66abf';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '38dd5c32-8f8f-52c3-aa65-2a6c39f66abf';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('38dd5c32-8f8f-52c3-aa65-2a6c39f66abf', 'ドライジン', 60, 'ml', 0),
  ('38dd5c32-8f8f-52c3-aa65-2a6c39f66abf', 'ドライベルモット', 10, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('38dd5c32-8f8f-52c3-aa65-2a6c39f66abf', 'ミキシンググラスに氷と材料を入れる。', 0),
  ('38dd5c32-8f8f-52c3-aa65-2a6c39f66abf', '静かにステアして冷やす。', 1),
  ('38dd5c32-8f8f-52c3-aa65-2a6c39f66abf', '冷やしたカクテルグラスに注ぎ、オリーブまたはレモンピールを飾る。', 2);

-- el-diablo
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b5135fca-5784-5a6f-aaa7-06fae096d6a7',
  'el-diablo',
  'エルディアブロ',
  'El Diablo',
  'テキーラ、カシス、ライム、ジンジャーエールで作るスパイシーなロングカクテル。',
  'Tequila',
  12,
  'United States',
  NULL,
  'none',
  ARRAY['エル・ディアブロ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '10acdae8-d6cd-559f-bbf1-e373dea5b480',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b5135fca-5784-5a6f-aaa7-06fae096d6a7',
  'エルディアブロ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '10acdae8-d6cd-559f-bbf1-e373dea5b480';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '10acdae8-d6cd-559f-bbf1-e373dea5b480';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('10acdae8-d6cd-559f-bbf1-e373dea5b480', 'テキーラブランコ', 45, 'ml', 0),
  ('10acdae8-d6cd-559f-bbf1-e373dea5b480', 'クレーム・ド・カシス', 15, 'ml', 1),
  ('10acdae8-d6cd-559f-bbf1-e373dea5b480', 'ライムジュース', 15, 'ml', 2),
  ('10acdae8-d6cd-559f-bbf1-e373dea5b480', 'ジンジャーエール', 90, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('10acdae8-d6cd-559f-bbf1-e373dea5b480', 'グラスに氷を入れる。', 0),
  ('10acdae8-d6cd-559f-bbf1-e373dea5b480', '材料を順に注ぐ。', 1),
  ('10acdae8-d6cd-559f-bbf1-e373dea5b480', '軽く混ぜて仕上げる。', 2);

-- el-presidente
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '9a08c33e-8227-5550-aee9-9d8085147f60',
  'el-presidente',
  'エルプレジデンテ',
  'El Presidente',
  'ラム、ドライベルモット、オレンジキュラソーを合わせるキューバのエレガントな古典。',
  'Rum',
  25,
  'Cuba',
  NULL,
  'none',
  ARRAY['エル・プレジデンテ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'df267222-be43-51cf-b907-17d8f500ace4',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '9a08c33e-8227-5550-aee9-9d8085147f60',
  'エルプレジデンテ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'df267222-be43-51cf-b907-17d8f500ace4';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'df267222-be43-51cf-b907-17d8f500ace4';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('df267222-be43-51cf-b907-17d8f500ace4', 'ライトラム', 45, 'ml', 0),
  ('df267222-be43-51cf-b907-17d8f500ace4', 'ドライベルモット', 20, 'ml', 1),
  ('df267222-be43-51cf-b907-17d8f500ace4', 'オレンジキュラソー', 15, 'ml', 2),
  ('df267222-be43-51cf-b907-17d8f500ace4', 'グレナデンシロップ', 5, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('df267222-be43-51cf-b907-17d8f500ace4', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('df267222-be43-51cf-b907-17d8f500ace4', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('df267222-be43-51cf-b907-17d8f500ace4', '冷やしたグラスに注ぐ。', 2);

-- espresso-martini
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c153ab11-335f-5956-8a51-28efcc35b7a5',
  'espresso-martini',
  'エスプレッソマティーニ',
  'Espresso Martini',
  'ウォッカ、コーヒーリキュール、エスプレッソをシェイクしたモダンクラシック。クレマが魅力。',
  'Vodka',
  18,
  'United Kingdom',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '591ce14e-0187-5ea6-b949-be47d7d29ffc',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c153ab11-335f-5956-8a51-28efcc35b7a5',
  'エスプレッソマティーニ（基本レシピ）',
  'エスプレッソは抽出したてを少し冷まして使う。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '591ce14e-0187-5ea6-b949-be47d7d29ffc';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '591ce14e-0187-5ea6-b949-be47d7d29ffc';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('591ce14e-0187-5ea6-b949-be47d7d29ffc', 'ウォッカ', 45, 'ml', 0),
  ('591ce14e-0187-5ea6-b949-be47d7d29ffc', 'コーヒーリキュール', 20, 'ml', 1),
  ('591ce14e-0187-5ea6-b949-be47d7d29ffc', 'エスプレッソ', 30, 'ml', 2),
  ('591ce14e-0187-5ea6-b949-be47d7d29ffc', 'シュガーシロップ', 10, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('591ce14e-0187-5ea6-b949-be47d7d29ffc', 'シェイカーに材料と氷を入れる。', 0),
  ('591ce14e-0187-5ea6-b949-be47d7d29ffc', '強くシェイクしてクレマを立てる。', 1),
  ('591ce14e-0187-5ea6-b949-be47d7d29ffc', 'クーペに注ぎ、コーヒー豆を飾る。', 2);

-- french-75
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '9f644106-3400-5e46-92d4-09df7a190907',
  'french-75',
  'フレンチ75',
  'French 75',
  'ジン、レモン、シロップにシャンパンを注ぐ華やかな発泡系クラシック。',
  'Gin',
  15,
  'France',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'dce5cd96-64fd-577b-b285-9d7a867f7a83',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '9f644106-3400-5e46-92d4-09df7a190907',
  'フレンチ75（基本レシピ）',
  'シャンパンは最後に注ぎ、泡を潰さない。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'dce5cd96-64fd-577b-b285-9d7a867f7a83';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'dce5cd96-64fd-577b-b285-9d7a867f7a83';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('dce5cd96-64fd-577b-b285-9d7a867f7a83', 'ドライジン', 30, 'ml', 0),
  ('dce5cd96-64fd-577b-b285-9d7a867f7a83', 'レモン果汁', 15, 'ml', 1),
  ('dce5cd96-64fd-577b-b285-9d7a867f7a83', 'シュガーシロップ', 10, 'ml', 2),
  ('dce5cd96-64fd-577b-b285-9d7a867f7a83', 'シャンパン', 60, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('dce5cd96-64fd-577b-b285-9d7a867f7a83', 'シェイカーでジン、レモン、シロップをシェイクする。', 0),
  ('dce5cd96-64fd-577b-b285-9d7a867f7a83', 'フルートグラスに注ぐ。', 1),
  ('dce5cd96-64fd-577b-b285-9d7a867f7a83', 'シャンパンを静かに加えて飾る。', 2);

-- french-connection
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '54cc4c69-dd9c-5c35-8050-404563f73a93',
  'french-connection',
  'フレンチコネクション',
  'French Connection',
  'コニャックとアマレットを合わせる、香ばしく甘いシンプルな食後カクテル。',
  'Brandy',
  32,
  'United States',
  NULL,
  'none',
  ARRAY['フレンチ・コネクション']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '49c451fe-b4ab-5b9f-90df-f3cf7fd136e8',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '54cc4c69-dd9c-5c35-8050-404563f73a93',
  'フレンチコネクション（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '49c451fe-b4ab-5b9f-90df-f3cf7fd136e8';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '49c451fe-b4ab-5b9f-90df-f3cf7fd136e8';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('49c451fe-b4ab-5b9f-90df-f3cf7fd136e8', 'コニャック', 45, 'ml', 0),
  ('49c451fe-b4ab-5b9f-90df-f3cf7fd136e8', 'アマレット', 25, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('49c451fe-b4ab-5b9f-90df-f3cf7fd136e8', 'グラスに氷を入れる。', 0),
  ('49c451fe-b4ab-5b9f-90df-f3cf7fd136e8', '材料を順に注ぐ。', 1),
  ('49c451fe-b4ab-5b9f-90df-f3cf7fd136e8', '軽く混ぜて仕上げる。', 2);

-- french-martini
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '8558eb33-f6f9-5295-9728-8e25bbac2a49',
  'french-martini',
  'フレンチマティーニ',
  'French Martini',
  'ウォッカ、ラズベリーリキュール、パイナップルを合わせるフルーティーなモダンクラシック。',
  'Vodka',
  20,
  'United States',
  NULL,
  'none',
  ARRAY['フレンチ・マティーニ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '5089a150-2b7a-52ed-9c96-75639dc0d81e',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '8558eb33-f6f9-5295-9728-8e25bbac2a49',
  'フレンチマティーニ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '5089a150-2b7a-52ed-9c96-75639dc0d81e';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '5089a150-2b7a-52ed-9c96-75639dc0d81e';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('5089a150-2b7a-52ed-9c96-75639dc0d81e', 'ウォッカ', 45, 'ml', 0),
  ('5089a150-2b7a-52ed-9c96-75639dc0d81e', 'ラズベリーリキュール', 15, 'ml', 1),
  ('5089a150-2b7a-52ed-9c96-75639dc0d81e', 'パイナップルジュース', 45, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('5089a150-2b7a-52ed-9c96-75639dc0d81e', 'シェーカーに材料と氷を入れる。', 0),
  ('5089a150-2b7a-52ed-9c96-75639dc0d81e', 'しっかりシェイクして冷やす。', 1),
  ('5089a150-2b7a-52ed-9c96-75639dc0d81e', '冷やしたグラスに注ぐ。', 2);

-- gimlet
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b16a935c-14eb-5827-93a8-9ae173516b6b',
  'gimlet',
  'ギムレット',
  'Gimlet',
  'ジンとライムの鋭い酸味が冴える、英国海軍由来とされるショートカクテル。',
  'Gin',
  29,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['ジンギムレット']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'bbe4eb88-bd2e-514a-b4bc-e9eab9d06ce6',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b16a935c-14eb-5827-93a8-9ae173516b6b',
  'ギムレット（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'bbe4eb88-bd2e-514a-b4bc-e9eab9d06ce6';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'bbe4eb88-bd2e-514a-b4bc-e9eab9d06ce6';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('bbe4eb88-bd2e-514a-b4bc-e9eab9d06ce6', 'ドライジン', 45, 'ml', 0),
  ('bbe4eb88-bd2e-514a-b4bc-e9eab9d06ce6', 'ライムジュース', 15, 'ml', 1),
  ('bbe4eb88-bd2e-514a-b4bc-e9eab9d06ce6', 'シュガーシロップ', 5, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('bbe4eb88-bd2e-514a-b4bc-e9eab9d06ce6', 'シェーカーに材料と氷を入れる。', 0),
  ('bbe4eb88-bd2e-514a-b4bc-e9eab9d06ce6', 'しっかりシェイクして冷やす。', 1),
  ('bbe4eb88-bd2e-514a-b4bc-e9eab9d06ce6', '冷やしたグラスに注ぐ。', 2);

-- gin-fizz
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'e39d2383-33fd-567b-be97-4a2db48c7672',
  'gin-fizz',
  'ジンフィズ',
  'Gin Fizz',
  'ジンサワーをソーダで伸ばした、軽快で飲みやすいロングカクテル。',
  'Gin',
  12,
  'United States',
  NULL,
  'none',
  ARRAY['ジン・フィズ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '2782e383-d8f3-572f-a77e-76721557fca2',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'e39d2383-33fd-567b-be97-4a2db48c7672',
  'ジンフィズ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '2782e383-d8f3-572f-a77e-76721557fca2';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '2782e383-d8f3-572f-a77e-76721557fca2';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('2782e383-d8f3-572f-a77e-76721557fca2', 'ドライジン', 45, 'ml', 0),
  ('2782e383-d8f3-572f-a77e-76721557fca2', 'レモンジュース', 20, 'ml', 1),
  ('2782e383-d8f3-572f-a77e-76721557fca2', 'シュガーシロップ', 15, 'ml', 2),
  ('2782e383-d8f3-572f-a77e-76721557fca2', 'ソーダ', 80, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('2782e383-d8f3-572f-a77e-76721557fca2', 'シェーカーに材料と氷を入れる。', 0),
  ('2782e383-d8f3-572f-a77e-76721557fca2', 'しっかりシェイクして冷やす。', 1),
  ('2782e383-d8f3-572f-a77e-76721557fca2', '冷やしたグラスに注ぐ。', 2);

-- gin-rickey
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'df713bb3-cc46-5043-9e7f-84199e19ed19',
  'gin-rickey',
  'ジンリッキー',
  'Gin Rickey',
  'ジン、ライム、ソーダだけで作る、辛口で爽快なハイボールスタイル。',
  'Gin',
  10,
  'United States',
  NULL,
  'none',
  ARRAY['ジン・リッキー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '6ac8c9fa-5089-51cd-827f-a3b8a9506b61',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'df713bb3-cc46-5043-9e7f-84199e19ed19',
  'ジンリッキー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '6ac8c9fa-5089-51cd-827f-a3b8a9506b61';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '6ac8c9fa-5089-51cd-827f-a3b8a9506b61';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('6ac8c9fa-5089-51cd-827f-a3b8a9506b61', 'ドライジン', 45, 'ml', 0),
  ('6ac8c9fa-5089-51cd-827f-a3b8a9506b61', 'ライムジュース', 15, 'ml', 1),
  ('6ac8c9fa-5089-51cd-827f-a3b8a9506b61', 'ソーダ', 120, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('6ac8c9fa-5089-51cd-827f-a3b8a9506b61', 'グラスに氷を入れる。', 0),
  ('6ac8c9fa-5089-51cd-827f-a3b8a9506b61', '材料を順に注ぐ。', 1),
  ('6ac8c9fa-5089-51cd-827f-a3b8a9506b61', '軽く混ぜて仕上げる。', 2);

-- gin-tonic
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c0c00000-0000-4000-8000-000000000004',
  'gin-tonic',
  'ジントニック',
  'Gin and Tonic',
  'ジンをトニックウォーターで割るだけのシンプルカクテル。ジンのボタニカルとトニックの苦味が織りなす永遠の定番。',
  'Gin',
  8,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['ジン・トニック', 'G&T']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'f8ce6b98-5ab5-5700-b16d-fe619c87be11',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c0c00000-0000-4000-8000-000000000004',
  'ジントニック（基本レシピ）',
  '氷はたっぷり、炭酸は最後に静かに注ぐ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'f8ce6b98-5ab5-5700-b16d-fe619c87be11';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'f8ce6b98-5ab5-5700-b16d-fe619c87be11';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('f8ce6b98-5ab5-5700-b16d-fe619c87be11', 'ドライジン', 45, 'ml', 0),
  ('f8ce6b98-5ab5-5700-b16d-fe619c87be11', 'トニックウォーター', 135, 'ml', 1),
  ('f8ce6b98-5ab5-5700-b16d-fe619c87be11', 'ライム', 0.25, 'piece', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('f8ce6b98-5ab5-5700-b16d-fe619c87be11', 'ハイボールグラスに氷をたっぷり入れる。', 0),
  ('f8ce6b98-5ab5-5700-b16d-fe619c87be11', 'ジンを注ぐ。', 1),
  ('f8ce6b98-5ab5-5700-b16d-fe619c87be11', 'トニックウォーターを静かに注ぎ、ライムを絞って落とす。', 2);

-- godfather
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '93504396-a187-5289-99e3-66ae1965c89d',
  'godfather',
  'ゴッドファーザー',
  'Godfather',
  'ウイスキーにアマレットを合わせる、映画名で知られるシンプルなクラシック。',
  'Whisky',
  32,
  'United States',
  NULL,
  'none',
  ARRAY['ゴッドファーザー・カクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '8f7a582b-ec85-5e6e-bae4-ac18f4f1b9b8',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '93504396-a187-5289-99e3-66ae1965c89d',
  'ゴッドファーザー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '8f7a582b-ec85-5e6e-bae4-ac18f4f1b9b8';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '8f7a582b-ec85-5e6e-bae4-ac18f4f1b9b8';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('8f7a582b-ec85-5e6e-bae4-ac18f4f1b9b8', 'スコッチウイスキー', 45, 'ml', 0),
  ('8f7a582b-ec85-5e6e-bae4-ac18f4f1b9b8', 'アマレット', 25, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('8f7a582b-ec85-5e6e-bae4-ac18f4f1b9b8', 'グラスに氷を入れる。', 0),
  ('8f7a582b-ec85-5e6e-bae4-ac18f4f1b9b8', '材料を順に注ぐ。', 1),
  ('8f7a582b-ec85-5e6e-bae4-ac18f4f1b9b8', '軽く混ぜて仕上げる。', 2);

-- gold-rush
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'ca0372b6-e0bd-5e0c-af81-332a806b215a',
  'gold-rush',
  'ゴールドラッシュ',
  'Gold Rush',
  'バーボン、蜂蜜、レモンで作る、シンプルで完成度の高いモダンサワー。',
  'Whisky',
  23,
  'United States',
  NULL,
  'none',
  ARRAY['ゴールド・ラッシュ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'c649afcc-7604-5854-bafa-fe6d5072c897',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'ca0372b6-e0bd-5e0c-af81-332a806b215a',
  'ゴールドラッシュ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'c649afcc-7604-5854-bafa-fe6d5072c897';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'c649afcc-7604-5854-bafa-fe6d5072c897';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('c649afcc-7604-5854-bafa-fe6d5072c897', 'バーボンウイスキー', 60, 'ml', 0),
  ('c649afcc-7604-5854-bafa-fe6d5072c897', 'レモンジュース', 20, 'ml', 1),
  ('c649afcc-7604-5854-bafa-fe6d5072c897', '蜂蜜シロップ', 20, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('c649afcc-7604-5854-bafa-fe6d5072c897', 'シェーカーに材料と氷を入れる。', 0),
  ('c649afcc-7604-5854-bafa-fe6d5072c897', 'しっかりシェイクして冷やす。', 1),
  ('c649afcc-7604-5854-bafa-fe6d5072c897', '冷やしたグラスに注ぐ。', 2);

-- golden-cadillac
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '93070ec2-fbb7-5e39-a362-fb9fa8f534a2',
  'golden-cadillac',
  'ゴールデンキャデラック',
  'Golden Cadillac',
  'ガリアーノ、カカオ、クリームで作る、甘くリッチなデザートカクテル。',
  'Liqueur',
  13,
  'United States',
  NULL,
  'none',
  ARRAY['ゴールデン・キャデラック']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'e3a94bab-fdff-5810-b02d-8c6b12387f29',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '93070ec2-fbb7-5e39-a362-fb9fa8f534a2',
  'ゴールデンキャデラック（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'e3a94bab-fdff-5810-b02d-8c6b12387f29';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'e3a94bab-fdff-5810-b02d-8c6b12387f29';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('e3a94bab-fdff-5810-b02d-8c6b12387f29', 'ガリアーノ', 30, 'ml', 0),
  ('e3a94bab-fdff-5810-b02d-8c6b12387f29', 'ホワイトカカオリキュール', 30, 'ml', 1),
  ('e3a94bab-fdff-5810-b02d-8c6b12387f29', '生クリーム', 30, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('e3a94bab-fdff-5810-b02d-8c6b12387f29', 'シェーカーに材料と氷を入れる。', 0),
  ('e3a94bab-fdff-5810-b02d-8c6b12387f29', 'しっかりシェイクして冷やす。', 1),
  ('e3a94bab-fdff-5810-b02d-8c6b12387f29', '冷やしたグラスに注ぐ。', 2);

-- grapefruit-sour
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '0aec9877-36a5-58f9-b99e-276c440af1d0',
  'grapefruit-sour',
  'グレープフルーツサワー',
  'Grapefruit Sour',
  '焼酎にグレープフルーツと炭酸を合わせる、居酒屋定番のフルーツサワー。',
  'Shochu',
  7,
  'Japan',
  NULL,
  'none',
  ARRAY['グレフルサワー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'c0188474-7d32-5bb0-ad8c-4b52f13e49de',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '0aec9877-36a5-58f9-b99e-276c440af1d0',
  'グレープフルーツサワー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'c0188474-7d32-5bb0-ad8c-4b52f13e49de';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'c0188474-7d32-5bb0-ad8c-4b52f13e49de';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('c0188474-7d32-5bb0-ad8c-4b52f13e49de', '焼酎', 45, 'ml', 0),
  ('c0188474-7d32-5bb0-ad8c-4b52f13e49de', 'グレープフルーツジュース', 60, 'ml', 1),
  ('c0188474-7d32-5bb0-ad8c-4b52f13e49de', 'ソーダ', 90, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('c0188474-7d32-5bb0-ad8c-4b52f13e49de', 'グラスに氷を入れる。', 0),
  ('c0188474-7d32-5bb0-ad8c-4b52f13e49de', '材料を順に注ぐ。', 1),
  ('c0188474-7d32-5bb0-ad8c-4b52f13e49de', '軽く混ぜて仕上げる。', 2);

-- grasshopper
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '601adb78-5381-5ff8-beea-eb101d1ec3dc',
  'grasshopper',
  'グラスホッパー',
  'Grasshopper',
  'ミントとカカオ、クリームで作る、緑色が印象的なデザートカクテル。',
  'Liqueur',
  12,
  'United States',
  NULL,
  'none',
  ARRAY['グラスホッパーカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'bd51c2fc-e122-5aa1-bfc6-26e348a1d394',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '601adb78-5381-5ff8-beea-eb101d1ec3dc',
  'グラスホッパー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'bd51c2fc-e122-5aa1-bfc6-26e348a1d394';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'bd51c2fc-e122-5aa1-bfc6-26e348a1d394';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('bd51c2fc-e122-5aa1-bfc6-26e348a1d394', 'グリーンミントリキュール', 30, 'ml', 0),
  ('bd51c2fc-e122-5aa1-bfc6-26e348a1d394', 'ホワイトカカオリキュール', 30, 'ml', 1),
  ('bd51c2fc-e122-5aa1-bfc6-26e348a1d394', '生クリーム', 30, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('bd51c2fc-e122-5aa1-bfc6-26e348a1d394', 'シェーカーに材料と氷を入れる。', 0),
  ('bd51c2fc-e122-5aa1-bfc6-26e348a1d394', 'しっかりシェイクして冷やす。', 1),
  ('bd51c2fc-e122-5aa1-bfc6-26e348a1d394', '冷やしたグラスに注ぐ。', 2);

-- greyhound
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '67cef8ca-8681-50f4-8f6e-1326d29a590a',
  'greyhound',
  'グレイハウンド',
  'Greyhound',
  'ウォッカとグレープフルーツだけで作る、軽やかな酸味のロングカクテル。',
  'Vodka',
  10,
  'United States',
  NULL,
  'none',
  ARRAY['グレーハウンド']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '2d79b6d4-760d-58ef-a5f3-03fe86c2e3e6',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '67cef8ca-8681-50f4-8f6e-1326d29a590a',
  'グレイハウンド（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '2d79b6d4-760d-58ef-a5f3-03fe86c2e3e6';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '2d79b6d4-760d-58ef-a5f3-03fe86c2e3e6';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('2d79b6d4-760d-58ef-a5f3-03fe86c2e3e6', 'ウォッカ', 45, 'ml', 0),
  ('2d79b6d4-760d-58ef-a5f3-03fe86c2e3e6', 'グレープフルーツジュース', 135, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('2d79b6d4-760d-58ef-a5f3-03fe86c2e3e6', 'グラスに氷を入れる。', 0),
  ('2d79b6d4-760d-58ef-a5f3-03fe86c2e3e6', '材料を順に注ぐ。', 1),
  ('2d79b6d4-760d-58ef-a5f3-03fe86c2e3e6', '軽く混ぜて仕上げる。', 2);

-- grog
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'bca26721-8b89-592f-93da-33890a6fecd6',
  'grog',
  'グロッグ',
  'Grog',
  'ラムを水やライムで割る、英国海軍に由来する素朴なロングドリンク。',
  'Rum',
  12,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['ラムグロッグ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'b0a25cd9-02c7-53c0-bb95-1d0cc0e51fa5',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'bca26721-8b89-592f-93da-33890a6fecd6',
  'グロッグ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'b0a25cd9-02c7-53c0-bb95-1d0cc0e51fa5';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'b0a25cd9-02c7-53c0-bb95-1d0cc0e51fa5';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('b0a25cd9-02c7-53c0-bb95-1d0cc0e51fa5', 'ダークラム', 60, 'ml', 0),
  ('b0a25cd9-02c7-53c0-bb95-1d0cc0e51fa5', '水', 120, 'ml', 1),
  ('b0a25cd9-02c7-53c0-bb95-1d0cc0e51fa5', 'ライムジュース', 15, 'ml', 2),
  ('b0a25cd9-02c7-53c0-bb95-1d0cc0e51fa5', '砂糖', 2, 'tsp', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('b0a25cd9-02c7-53c0-bb95-1d0cc0e51fa5', 'グラスに氷を入れる。', 0),
  ('b0a25cd9-02c7-53c0-bb95-1d0cc0e51fa5', '材料を順に注ぐ。', 1),
  ('b0a25cd9-02c7-53c0-bb95-1d0cc0e51fa5', '軽く混ぜて仕上げる。', 2);

-- hanky-panky
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'd9869011-f36a-540f-bf3b-741b862612ab',
  'hanky-panky',
  'ハンキーパンキー',
  'Hanky Panky',
  'ジンとスイートベルモットにフェルネットを効かせた、サヴォイ由来のビターな一杯。',
  'Gin',
  27,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['ハンキー・パンキー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'bc65aecc-df38-5e6a-aa67-b53d6fc621a6',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'd9869011-f36a-540f-bf3b-741b862612ab',
  'ハンキーパンキー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'bc65aecc-df38-5e6a-aa67-b53d6fc621a6';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'bc65aecc-df38-5e6a-aa67-b53d6fc621a6';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('bc65aecc-df38-5e6a-aa67-b53d6fc621a6', 'ドライジン', 45, 'ml', 0),
  ('bc65aecc-df38-5e6a-aa67-b53d6fc621a6', 'スイートベルモット', 45, 'ml', 1),
  ('bc65aecc-df38-5e6a-aa67-b53d6fc621a6', 'フェルネットブランカ', 5, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('bc65aecc-df38-5e6a-aa67-b53d6fc621a6', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('bc65aecc-df38-5e6a-aa67-b53d6fc621a6', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('bc65aecc-df38-5e6a-aa67-b53d6fc621a6', '冷やしたグラスに注ぐ。', 2);

-- harvey-wallbanger
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b9785370-400f-5f6f-8ddc-cb4da9b99dd7',
  'harvey-wallbanger',
  'ハーベイウォールバンガー',
  'Harvey Wallbanger',
  'スクリュードライバーにガリアーノを浮かべる、1970年代に流行した定番。',
  'Vodka',
  11,
  'United States',
  NULL,
  'none',
  ARRAY['ハーヴェイ・ウォールバンガー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'eec050bf-f397-5dc7-a751-65e0def284c6',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b9785370-400f-5f6f-8ddc-cb4da9b99dd7',
  'ハーベイウォールバンガー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'eec050bf-f397-5dc7-a751-65e0def284c6';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'eec050bf-f397-5dc7-a751-65e0def284c6';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('eec050bf-f397-5dc7-a751-65e0def284c6', 'ウォッカ', 45, 'ml', 0),
  ('eec050bf-f397-5dc7-a751-65e0def284c6', 'オレンジジュース', 120, 'ml', 1),
  ('eec050bf-f397-5dc7-a751-65e0def284c6', 'ガリアーノ', 15, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('eec050bf-f397-5dc7-a751-65e0def284c6', 'グラスに氷を入れる。', 0),
  ('eec050bf-f397-5dc7-a751-65e0def284c6', '材料を順に注ぐ。', 1),
  ('eec050bf-f397-5dc7-a751-65e0def284c6', '軽く混ぜて仕上げる。', 2);

-- hemingway-daiquiri
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '103b958a-957a-5e05-9e82-707607a83d55',
  'hemingway-daiquiri',
  'ヘミングウェイダイキリ',
  'Hemingway Daiquiri',
  'ラム、グレープフルーツ、マラスキーノ、ライムで作る、作家ゆかりのダイキリ変奏。',
  'Rum',
  20,
  'Cuba',
  NULL,
  'none',
  ARRAY['パパドブレ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '2ded592b-e021-50f1-a341-501f5d1e0880',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '103b958a-957a-5e05-9e82-707607a83d55',
  'ヘミングウェイダイキリ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '2ded592b-e021-50f1-a341-501f5d1e0880';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '2ded592b-e021-50f1-a341-501f5d1e0880';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('2ded592b-e021-50f1-a341-501f5d1e0880', 'ライトラム', 60, 'ml', 0),
  ('2ded592b-e021-50f1-a341-501f5d1e0880', 'グレープフルーツジュース', 30, 'ml', 1),
  ('2ded592b-e021-50f1-a341-501f5d1e0880', 'ライムジュース', 20, 'ml', 2),
  ('2ded592b-e021-50f1-a341-501f5d1e0880', 'マラスキーノリキュール', 15, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('2ded592b-e021-50f1-a341-501f5d1e0880', 'シェーカーに材料と氷を入れる。', 0),
  ('2ded592b-e021-50f1-a341-501f5d1e0880', 'しっかりシェイクして冷やす。', 1),
  ('2ded592b-e021-50f1-a341-501f5d1e0880', '冷やしたグラスに注ぐ。', 2);

-- highball
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c0c00000-0000-4000-8000-000000000008',
  'highball',
  'ハイボール',
  'Highball',
  'ウイスキーをソーダで割った軽快なロングドリンク。食中酒の定番として日本で絶大な人気を誇る。',
  'Whisky',
  7,
  'Japan',
  NULL,
  'none',
  ARRAY['ウィスキーハイボール']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '4ec3974e-0815-5a4c-b192-38702d42d061',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c0c00000-0000-4000-8000-000000000008',
  'ハイボール（基本レシピ）',
  '混ぜるのは縦に1回だけ。炭酸を潰さない。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '4ec3974e-0815-5a4c-b192-38702d42d061';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '4ec3974e-0815-5a4c-b192-38702d42d061';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('4ec3974e-0815-5a4c-b192-38702d42d061', 'ウイスキー', 30, 'ml', 0),
  ('4ec3974e-0815-5a4c-b192-38702d42d061', '炭酸水', 120, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('4ec3974e-0815-5a4c-b192-38702d42d061', 'ハイボールグラスに氷をたっぷり入れる。', 0),
  ('4ec3974e-0815-5a4c-b192-38702d42d061', 'ウイスキーを注ぐ。', 1),
  ('4ec3974e-0815-5a4c-b192-38702d42d061', '炭酸水を注ぎ、マドラーで縦に一度だけステアする。', 2);

-- hoppy-set
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'eaa952b4-2cce-50bb-b9ea-6a0cedaf0fd9',
  'hoppy-set',
  'ホッピーセット',
  'Hoppy Set',
  '焼酎をホッピーで割る、東京の大衆酒場文化を代表する一杯。',
  'Shochu',
  6,
  'Japan',
  NULL,
  'none',
  ARRAY['ホッピー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '69ab9617-0e37-5e2c-b646-ac60f09a88b8',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'eaa952b4-2cce-50bb-b9ea-6a0cedaf0fd9',
  'ホッピーセット（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '69ab9617-0e37-5e2c-b646-ac60f09a88b8';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '69ab9617-0e37-5e2c-b646-ac60f09a88b8';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('69ab9617-0e37-5e2c-b646-ac60f09a88b8', '焼酎', 45, 'ml', 0),
  ('69ab9617-0e37-5e2c-b646-ac60f09a88b8', 'ホッピー', 180, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('69ab9617-0e37-5e2c-b646-ac60f09a88b8', 'グラスに氷を入れる。', 0),
  ('69ab9617-0e37-5e2c-b646-ac60f09a88b8', '材料を順に注ぐ。', 1),
  ('69ab9617-0e37-5e2c-b646-ac60f09a88b8', '軽く混ぜて仕上げる。', 2);

-- horses-neck
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'ece37a8a-8ac0-5bc4-a4ba-26b868128d40',
  'horses-neck',
  'ホーセズネック',
  'Horse''s Neck',
  'ブランデーとジンジャーエールに長いレモンピールを添える、見た目も特徴的な一杯。',
  'Brandy',
  11,
  'United States',
  NULL,
  'none',
  ARRAY['ホースズネック']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '122cbbf2-e565-5a47-9c7b-d53f313ae15e',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'ece37a8a-8ac0-5bc4-a4ba-26b868128d40',
  'ホーセズネック（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '122cbbf2-e565-5a47-9c7b-d53f313ae15e';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '122cbbf2-e565-5a47-9c7b-d53f313ae15e';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('122cbbf2-e565-5a47-9c7b-d53f313ae15e', 'ブランデー', 45, 'ml', 0),
  ('122cbbf2-e565-5a47-9c7b-d53f313ae15e', 'ジンジャーエール', 120, 'ml', 1),
  ('122cbbf2-e565-5a47-9c7b-d53f313ae15e', 'アンゴスチュラビターズ', 1, 'dash', 2),
  ('122cbbf2-e565-5a47-9c7b-d53f313ae15e', 'レモンピール', 1, 'piece', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('122cbbf2-e565-5a47-9c7b-d53f313ae15e', 'グラスに氷を入れる。', 0),
  ('122cbbf2-e565-5a47-9c7b-d53f313ae15e', '材料を順に注ぐ。', 1),
  ('122cbbf2-e565-5a47-9c7b-d53f313ae15e', '軽く混ぜて仕上げる。', 2);

-- hot-buttered-rum
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '3269a870-f33c-52d3-a29a-670478b8b60a',
  'hot-buttered-rum',
  'ホットバタードラム',
  'Hot Buttered Rum',
  'ラム、バター、砂糖、スパイスを湯で溶く、冬の温かいクラシック。',
  'Rum',
  12,
  'United States',
  NULL,
  'none',
  ARRAY['ホット・バタード・ラム']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'ef5faa91-9b52-5ee7-bcd5-aa574ce75cdb',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '3269a870-f33c-52d3-a29a-670478b8b60a',
  'ホットバタードラム（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'ef5faa91-9b52-5ee7-bcd5-aa574ce75cdb';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'ef5faa91-9b52-5ee7-bcd5-aa574ce75cdb';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('ef5faa91-9b52-5ee7-bcd5-aa574ce75cdb', 'ダークラム', 45, 'ml', 0),
  ('ef5faa91-9b52-5ee7-bcd5-aa574ce75cdb', '熱湯', 120, 'ml', 1),
  ('ef5faa91-9b52-5ee7-bcd5-aa574ce75cdb', '無塩バター', 10, 'g', 2),
  ('ef5faa91-9b52-5ee7-bcd5-aa574ce75cdb', 'ブラウンシュガー', 2, 'tsp', 3),
  ('ef5faa91-9b52-5ee7-bcd5-aa574ce75cdb', 'シナモン', 1, 'dash', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('ef5faa91-9b52-5ee7-bcd5-aa574ce75cdb', '耐熱グラスに甘味やスパイスを入れる。', 0),
  ('ef5faa91-9b52-5ee7-bcd5-aa574ce75cdb', '温めた材料を注ぐ。', 1),
  ('ef5faa91-9b52-5ee7-bcd5-aa574ce75cdb', '軽く混ぜて温かいうちに提供する。', 2);

-- hot-toddy
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '9bd1eb2a-3ffe-5a22-82b7-609ff6b3ac0c',
  'hot-toddy',
  'ホットトディ',
  'Hot Toddy',
  'ウイスキーを湯、蜂蜜、レモンで割る、寒い季節に定番の温かいカクテル。',
  'Whisky',
  10,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['ホット・トディ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'c4bb0796-87ac-5220-8c08-0ad137a47941',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '9bd1eb2a-3ffe-5a22-82b7-609ff6b3ac0c',
  'ホットトディ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'c4bb0796-87ac-5220-8c08-0ad137a47941';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'c4bb0796-87ac-5220-8c08-0ad137a47941';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('c4bb0796-87ac-5220-8c08-0ad137a47941', 'ウイスキー', 45, 'ml', 0),
  ('c4bb0796-87ac-5220-8c08-0ad137a47941', '熱湯', 120, 'ml', 1),
  ('c4bb0796-87ac-5220-8c08-0ad137a47941', '蜂蜜', 2, 'tsp', 2),
  ('c4bb0796-87ac-5220-8c08-0ad137a47941', 'レモンジュース', 10, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('c4bb0796-87ac-5220-8c08-0ad137a47941', '耐熱グラスに甘味やスパイスを入れる。', 0),
  ('c4bb0796-87ac-5220-8c08-0ad137a47941', '温めた材料を注ぐ。', 1),
  ('c4bb0796-87ac-5220-8c08-0ad137a47941', '軽く混ぜて温かいうちに提供する。', 2);

-- hurricane
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'aaf143fd-7ede-551d-a721-bdec150bab62',
  'hurricane',
  'ハリケーン',
  'Hurricane',
  'ラムとパッションフルーツをたっぷり使う、ニューオーリンズ名物のトロピカルカクテル。',
  'Rum',
  17,
  'United States',
  NULL,
  'none',
  ARRAY['ハリケーンカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'f7c53cc2-9d4b-5f40-bcf1-9f2d82b0ec47',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'aaf143fd-7ede-551d-a721-bdec150bab62',
  'ハリケーン（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'f7c53cc2-9d4b-5f40-bcf1-9f2d82b0ec47';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'f7c53cc2-9d4b-5f40-bcf1-9f2d82b0ec47';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('f7c53cc2-9d4b-5f40-bcf1-9f2d82b0ec47', 'ライトラム', 45, 'ml', 0),
  ('f7c53cc2-9d4b-5f40-bcf1-9f2d82b0ec47', 'ダークラム', 45, 'ml', 1),
  ('f7c53cc2-9d4b-5f40-bcf1-9f2d82b0ec47', 'パッションフルーツシロップ', 30, 'ml', 2),
  ('f7c53cc2-9d4b-5f40-bcf1-9f2d82b0ec47', 'レモンジュース', 25, 'ml', 3),
  ('f7c53cc2-9d4b-5f40-bcf1-9f2d82b0ec47', 'グレナデンシロップ', 10, 'ml', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('f7c53cc2-9d4b-5f40-bcf1-9f2d82b0ec47', 'シェーカーに材料と氷を入れる。', 0),
  ('f7c53cc2-9d4b-5f40-bcf1-9f2d82b0ec47', 'しっかりシェイクして冷やす。', 1),
  ('f7c53cc2-9d4b-5f40-bcf1-9f2d82b0ec47', '冷やしたグラスに注ぐ。', 2);

-- irish-coffee
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '6ab0c407-2842-5dc3-850b-43cb4369f22c',
  'irish-coffee',
  'アイリッシュコーヒー',
  'Irish Coffee',
  'アイリッシュウイスキー、ホットコーヒー、クリームで作る温かい定番。',
  'Whisky',
  9,
  'Ireland',
  NULL,
  'none',
  ARRAY['アイリッシュ・コーヒー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '289e9362-c1ea-5e63-b180-d3f07269f00d',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '6ab0c407-2842-5dc3-850b-43cb4369f22c',
  'アイリッシュコーヒー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '289e9362-c1ea-5e63-b180-d3f07269f00d';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '289e9362-c1ea-5e63-b180-d3f07269f00d';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('289e9362-c1ea-5e63-b180-d3f07269f00d', 'アイリッシュウイスキー', 40, 'ml', 0),
  ('289e9362-c1ea-5e63-b180-d3f07269f00d', 'ホットコーヒー', 100, 'ml', 1),
  ('289e9362-c1ea-5e63-b180-d3f07269f00d', 'ブラウンシュガー', 2, 'tsp', 2),
  ('289e9362-c1ea-5e63-b180-d3f07269f00d', '生クリーム', 30, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('289e9362-c1ea-5e63-b180-d3f07269f00d', '耐熱グラスに甘味やスパイスを入れる。', 0),
  ('289e9362-c1ea-5e63-b180-d3f07269f00d', '温めた材料を注ぐ。', 1),
  ('289e9362-c1ea-5e63-b180-d3f07269f00d', '軽く混ぜて温かいうちに提供する。', 2);

-- jack-rose
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '8c7e3f1f-1a15-5a56-892c-10afbec3b80a',
  'jack-rose',
  'ジャックローズ',
  'Jack Rose',
  'アップルブランデー、ライム、グレナデンで作る、鮮やかな色合いのクラシック。',
  'Brandy',
  23,
  'United States',
  NULL,
  'none',
  ARRAY['ジャック・ローズ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '62429341-ad59-5735-abde-59b90943f04d',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '8c7e3f1f-1a15-5a56-892c-10afbec3b80a',
  'ジャックローズ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '62429341-ad59-5735-abde-59b90943f04d';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '62429341-ad59-5735-abde-59b90943f04d';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('62429341-ad59-5735-abde-59b90943f04d', 'アップルブランデー', 50, 'ml', 0),
  ('62429341-ad59-5735-abde-59b90943f04d', 'ライムジュース', 20, 'ml', 1),
  ('62429341-ad59-5735-abde-59b90943f04d', 'グレナデンシロップ', 15, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('62429341-ad59-5735-abde-59b90943f04d', 'シェーカーに材料と氷を入れる。', 0),
  ('62429341-ad59-5735-abde-59b90943f04d', 'しっかりシェイクして冷やす。', 1),
  ('62429341-ad59-5735-abde-59b90943f04d', '冷やしたグラスに注ぐ。', 2);

-- japanese-cocktail
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b7c2b510-eb9a-5ca8-9df5-0e7b0cd2f627',
  'japanese-cocktail',
  'ジャパニーズカクテル',
  'Japanese Cocktail',
  'コニャック、オルジェ、ビターズで作る、19世紀アメリカ発祥の歴史的カクテル。',
  'Brandy',
  31,
  'United States',
  NULL,
  'none',
  ARRAY['ジャパニーズ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'ad8ce6df-8109-54d9-af96-bb92abf0de9a',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b7c2b510-eb9a-5ca8-9df5-0e7b0cd2f627',
  'ジャパニーズカクテル（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'ad8ce6df-8109-54d9-af96-bb92abf0de9a';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'ad8ce6df-8109-54d9-af96-bb92abf0de9a';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('ad8ce6df-8109-54d9-af96-bb92abf0de9a', 'コニャック', 60, 'ml', 0),
  ('ad8ce6df-8109-54d9-af96-bb92abf0de9a', 'オルジェシロップ', 15, 'ml', 1),
  ('ad8ce6df-8109-54d9-af96-bb92abf0de9a', 'アンゴスチュラビターズ', 2, 'dash', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('ad8ce6df-8109-54d9-af96-bb92abf0de9a', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('ad8ce6df-8109-54d9-af96-bb92abf0de9a', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('ad8ce6df-8109-54d9-af96-bb92abf0de9a', '冷やしたグラスに注ぐ。', 2);

-- juan-collins
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'd7f5141d-a234-5226-802d-d2c8962d7a5c',
  'juan-collins',
  'ファンコリンズ',
  'Juan Collins',
  'トムコリンズをテキーラで作る、爽快なロングサワー。',
  'Tequila',
  11,
  'Mexico',
  NULL,
  'none',
  ARRAY['ホアン・コリンズ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '9f52cac8-ac53-5cba-912f-08a3d8743837',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'd7f5141d-a234-5226-802d-d2c8962d7a5c',
  'ファンコリンズ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '9f52cac8-ac53-5cba-912f-08a3d8743837';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '9f52cac8-ac53-5cba-912f-08a3d8743837';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('9f52cac8-ac53-5cba-912f-08a3d8743837', 'テキーラブランコ', 45, 'ml', 0),
  ('9f52cac8-ac53-5cba-912f-08a3d8743837', 'レモンジュース', 20, 'ml', 1),
  ('9f52cac8-ac53-5cba-912f-08a3d8743837', 'シュガーシロップ', 15, 'ml', 2),
  ('9f52cac8-ac53-5cba-912f-08a3d8743837', 'ソーダ', 90, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('9f52cac8-ac53-5cba-912f-08a3d8743837', 'シェーカーに材料と氷を入れる。', 0),
  ('9f52cac8-ac53-5cba-912f-08a3d8743837', 'しっかりシェイクして冷やす。', 1),
  ('9f52cac8-ac53-5cba-912f-08a3d8743837', '冷やしたグラスに注ぐ。', 2);

-- jungle-bird
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '219d2a5c-9dbf-5637-ae64-dd9f43bc0966',
  'jungle-bird',
  'ジャングルバード',
  'Jungle Bird',
  'ダークラム、カンパリ、パイナップルを合わせる、ビターなトロピカルカクテル。',
  'Rum',
  18,
  'Malaysia',
  NULL,
  'none',
  ARRAY['ジャングル・バード']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'b4f4d5d1-7bee-519c-84d8-45e4cfadce77',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '219d2a5c-9dbf-5637-ae64-dd9f43bc0966',
  'ジャングルバード（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'b4f4d5d1-7bee-519c-84d8-45e4cfadce77';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'b4f4d5d1-7bee-519c-84d8-45e4cfadce77';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('b4f4d5d1-7bee-519c-84d8-45e4cfadce77', 'ダークラム', 45, 'ml', 0),
  ('b4f4d5d1-7bee-519c-84d8-45e4cfadce77', 'カンパリ', 20, 'ml', 1),
  ('b4f4d5d1-7bee-519c-84d8-45e4cfadce77', 'パイナップルジュース', 45, 'ml', 2),
  ('b4f4d5d1-7bee-519c-84d8-45e4cfadce77', 'ライムジュース', 15, 'ml', 3),
  ('b4f4d5d1-7bee-519c-84d8-45e4cfadce77', 'シュガーシロップ', 10, 'ml', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('b4f4d5d1-7bee-519c-84d8-45e4cfadce77', 'シェーカーに材料と氷を入れる。', 0),
  ('b4f4d5d1-7bee-519c-84d8-45e4cfadce77', 'しっかりシェイクして冷やす。', 1),
  ('b4f4d5d1-7bee-519c-84d8-45e4cfadce77', '冷やしたグラスに注ぐ。', 2);

-- kalua-milk
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '24aa1d10-f373-5c30-b15d-3f9cddfe7bf9',
  'kalua-milk',
  'カルーアミルク',
  'Kahlua Milk',
  'コーヒーリキュールをミルクで割る、日本でも親しまれるまろやかなロングカクテル。',
  'Liqueur',
  6,
  'Mexico',
  NULL,
  'none',
  ARRAY['カルーア・ミルク', 'カールーアミルク']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '055ac2a3-8032-54cc-b7df-2b9bc9cdd896',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '24aa1d10-f373-5c30-b15d-3f9cddfe7bf9',
  'カルーアミルク（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '055ac2a3-8032-54cc-b7df-2b9bc9cdd896';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '055ac2a3-8032-54cc-b7df-2b9bc9cdd896';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('055ac2a3-8032-54cc-b7df-2b9bc9cdd896', 'コーヒーリキュール', 45, 'ml', 0),
  ('055ac2a3-8032-54cc-b7df-2b9bc9cdd896', '牛乳', 135, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('055ac2a3-8032-54cc-b7df-2b9bc9cdd896', 'グラスに氷を入れる。', 0),
  ('055ac2a3-8032-54cc-b7df-2b9bc9cdd896', '材料を順に注ぐ。', 1),
  ('055ac2a3-8032-54cc-b7df-2b9bc9cdd896', '軽く混ぜて仕上げる。', 2);

-- kamikaze
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '8210bcd2-43a3-5952-82ab-a62557611454',
  'kamikaze',
  'カミカゼ',
  'Kamikaze',
  'ウォッカ、ホワイトキュラソー、ライムを合わせる、切れ味のよいショートカクテル。',
  'Vodka',
  27,
  'United States',
  NULL,
  'none',
  ARRAY['神風']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '375fa4e9-1439-5c8c-ad19-709fc0158bdd',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '8210bcd2-43a3-5952-82ab-a62557611454',
  'カミカゼ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '375fa4e9-1439-5c8c-ad19-709fc0158bdd';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '375fa4e9-1439-5c8c-ad19-709fc0158bdd';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('375fa4e9-1439-5c8c-ad19-709fc0158bdd', 'ウォッカ', 30, 'ml', 0),
  ('375fa4e9-1439-5c8c-ad19-709fc0158bdd', 'ホワイトキュラソー', 30, 'ml', 1),
  ('375fa4e9-1439-5c8c-ad19-709fc0158bdd', 'ライムジュース', 30, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('375fa4e9-1439-5c8c-ad19-709fc0158bdd', 'シェーカーに材料と氷を入れる。', 0),
  ('375fa4e9-1439-5c8c-ad19-709fc0158bdd', 'しっかりシェイクして冷やす。', 1),
  ('375fa4e9-1439-5c8c-ad19-709fc0158bdd', '冷やしたグラスに注ぐ。', 2);

-- kir-royale
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'd5a39982-215a-5a41-9f59-38a3d7c462ad',
  'kir-royale',
  'キールロワイヤル',
  'Kir Royale',
  'カシスリキュールをシャンパンで割る、華やかなキールの上級版。',
  'Liqueur',
  12,
  'France',
  NULL,
  'none',
  ARRAY['キール・ロワイヤル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'e75c3f11-450a-5ba9-b6c5-42d74594e923',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'd5a39982-215a-5a41-9f59-38a3d7c462ad',
  'キールロワイヤル（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'e75c3f11-450a-5ba9-b6c5-42d74594e923';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'e75c3f11-450a-5ba9-b6c5-42d74594e923';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('e75c3f11-450a-5ba9-b6c5-42d74594e923', 'クレーム・ド・カシス', 15, 'ml', 0),
  ('e75c3f11-450a-5ba9-b6c5-42d74594e923', 'シャンパン', 120, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('e75c3f11-450a-5ba9-b6c5-42d74594e923', 'グラスに氷を入れる。', 0),
  ('e75c3f11-450a-5ba9-b6c5-42d74594e923', '材料を順に注ぐ。', 1),
  ('e75c3f11-450a-5ba9-b6c5-42d74594e923', '軽く混ぜて仕上げる。', 2);

-- kir
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '31729125-78fb-5292-903b-303a54bce70f',
  'kir',
  'キール',
  'Kir',
  'カシスリキュールを白ワインで割る、フランスの代表的なアペリティフ。',
  'Liqueur',
  11,
  'France',
  NULL,
  'none',
  ARRAY['キールカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '1bf854a8-594e-53f9-aac0-366d21c6bd4e',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '31729125-78fb-5292-903b-303a54bce70f',
  'キール（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '1bf854a8-594e-53f9-aac0-366d21c6bd4e';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '1bf854a8-594e-53f9-aac0-366d21c6bd4e';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('1bf854a8-594e-53f9-aac0-366d21c6bd4e', 'クレーム・ド・カシス', 15, 'ml', 0),
  ('1bf854a8-594e-53f9-aac0-366d21c6bd4e', '白ワイン', 120, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('1bf854a8-594e-53f9-aac0-366d21c6bd4e', 'グラスに氷を入れる。', 0),
  ('1bf854a8-594e-53f9-aac0-366d21c6bd4e', '材料を順に注ぐ。', 1),
  ('1bf854a8-594e-53f9-aac0-366d21c6bd4e', '軽く混ぜて仕上げる。', 2);

-- knickerbocker
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '6d3a9414-2827-55ec-b366-b27775fce91a',
  'knickerbocker',
  'ニッカーボッカー',
  'Knickerbocker',
  'ラム、ラズベリー、オレンジ、ライムを合わせる19世紀からのフルーティーな古典。',
  'Rum',
  18,
  'United States',
  NULL,
  'none',
  ARRAY['ニッカボッカー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'd74618d9-790c-5ac7-9301-fed1cd079501',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '6d3a9414-2827-55ec-b366-b27775fce91a',
  'ニッカーボッカー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'd74618d9-790c-5ac7-9301-fed1cd079501';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'd74618d9-790c-5ac7-9301-fed1cd079501';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('d74618d9-790c-5ac7-9301-fed1cd079501', 'ライトラム', 50, 'ml', 0),
  ('d74618d9-790c-5ac7-9301-fed1cd079501', 'ラズベリーシロップ', 15, 'ml', 1),
  ('d74618d9-790c-5ac7-9301-fed1cd079501', 'オレンジキュラソー', 10, 'ml', 2),
  ('d74618d9-790c-5ac7-9301-fed1cd079501', 'ライムジュース', 20, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('d74618d9-790c-5ac7-9301-fed1cd079501', 'シェーカーに材料と氷を入れる。', 0),
  ('d74618d9-790c-5ac7-9301-fed1cd079501', 'しっかりシェイクして冷やす。', 1),
  ('d74618d9-790c-5ac7-9301-fed1cd079501', '冷やしたグラスに注ぐ。', 2);

-- last-word
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '870c8ac6-7c07-5d65-990d-ddd6bca07db8',
  'last-word',
  'ラストワード',
  'Last Word',
  'ジン、シャルトリューズ、マラスキーノ、ライムを等量で合わせる強い個性のクラシック。',
  'Gin',
  28,
  'United States',
  NULL,
  'none',
  ARRAY['ザ・ラスト・ワード']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '4e218121-116e-5380-beac-c6eb584e06d4',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '870c8ac6-7c07-5d65-990d-ddd6bca07db8',
  'ラストワード（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '4e218121-116e-5380-beac-c6eb584e06d4';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '4e218121-116e-5380-beac-c6eb584e06d4';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('4e218121-116e-5380-beac-c6eb584e06d4', 'ドライジン', 22.5, 'ml', 0),
  ('4e218121-116e-5380-beac-c6eb584e06d4', 'グリーンシャルトリューズ', 22.5, 'ml', 1),
  ('4e218121-116e-5380-beac-c6eb584e06d4', 'マラスキーノリキュール', 22.5, 'ml', 2),
  ('4e218121-116e-5380-beac-c6eb584e06d4', 'ライムジュース', 22.5, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('4e218121-116e-5380-beac-c6eb584e06d4', 'シェーカーに材料と氷を入れる。', 0),
  ('4e218121-116e-5380-beac-c6eb584e06d4', 'しっかりシェイクして冷やす。', 1),
  ('4e218121-116e-5380-beac-c6eb584e06d4', '冷やしたグラスに注ぐ。', 2);

-- lemon-drop-martini
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '2ca8c8b3-016e-5a04-b26e-f0298c61ea42',
  'lemon-drop-martini',
  'レモンドロップマティーニ',
  'Lemon Drop Martini',
  'ウォッカとレモンの甘酸っぱさをショートで楽しむ、現代的な人気カクテル。',
  'Vodka',
  24,
  'United States',
  NULL,
  'none',
  ARRAY['レモンドロップ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '50693dfe-01c8-563a-91ef-72f08b5d704a',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '2ca8c8b3-016e-5a04-b26e-f0298c61ea42',
  'レモンドロップマティーニ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '50693dfe-01c8-563a-91ef-72f08b5d704a';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '50693dfe-01c8-563a-91ef-72f08b5d704a';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('50693dfe-01c8-563a-91ef-72f08b5d704a', 'ウォッカ', 45, 'ml', 0),
  ('50693dfe-01c8-563a-91ef-72f08b5d704a', 'ホワイトキュラソー', 20, 'ml', 1),
  ('50693dfe-01c8-563a-91ef-72f08b5d704a', 'レモンジュース', 20, 'ml', 2),
  ('50693dfe-01c8-563a-91ef-72f08b5d704a', 'シュガーシロップ', 10, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('50693dfe-01c8-563a-91ef-72f08b5d704a', 'シェーカーに材料と氷を入れる。', 0),
  ('50693dfe-01c8-563a-91ef-72f08b5d704a', 'しっかりシェイクして冷やす。', 1),
  ('50693dfe-01c8-563a-91ef-72f08b5d704a', '冷やしたグラスに注ぐ。', 2);

-- lemon-sour
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c0c00000-0000-4000-8000-000000000001',
  'lemon-sour',
  'レモンサワー',
  'Lemon Sour',
  '焼酎やウォッカをベースにレモン果汁と炭酸で割った日本の居酒屋定番カクテル。すっきり爽快で食事にも合う。',
  'Shochu',
  5,
  'Japan',
  NULL,
  'none',
  ARRAY['レモンサワ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '8c5a9c47-2a33-5d0b-acff-9c44b46185ce',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c0c00000-0000-4000-8000-000000000001',
  'レモンサワー（基本レシピ）',
  '氷はたっぷり入れ、炭酸は最後に静かに注ぐ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '8c5a9c47-2a33-5d0b-acff-9c44b46185ce';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '8c5a9c47-2a33-5d0b-acff-9c44b46185ce';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('8c5a9c47-2a33-5d0b-acff-9c44b46185ce', '甲類焼酎', 45, 'ml', 0),
  ('8c5a9c47-2a33-5d0b-acff-9c44b46185ce', 'レモン果汁', 20, 'ml', 1),
  ('8c5a9c47-2a33-5d0b-acff-9c44b46185ce', '炭酸水', 120, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('8c5a9c47-2a33-5d0b-acff-9c44b46185ce', 'グラスに氷をたっぷり入れる。', 0),
  ('8c5a9c47-2a33-5d0b-acff-9c44b46185ce', '甲類焼酎とレモン果汁を注ぎ、軽く混ぜる。', 1),
  ('8c5a9c47-2a33-5d0b-acff-9c44b46185ce', '炭酸水を静かに注ぎ、縦に一度だけステアする。', 2);

-- long-island-iced-tea
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b52cc965-e893-591b-a1e6-9b1ee3fac577',
  'long-island-iced-tea',
  'ロングアイランドアイスティー',
  'Long Island Iced Tea',
  '複数のスピリッツにレモンとコーラを合わせた強度のあるアメリカンカクテル。見た目はアイスティーに近い。',
  'Vodka',
  22,
  'United States',
  NULL,
  'none',
  ARRAY['LIIT']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '438f1465-c2ee-5e2f-afbd-ab567c0014d1',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b52cc965-e893-591b-a1e6-9b1ee3fac577',
  'ロングアイランドアイスティー（基本レシピ）',
  'スピリッツが多いので飲み過ぎに注意。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '438f1465-c2ee-5e2f-afbd-ab567c0014d1';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '438f1465-c2ee-5e2f-afbd-ab567c0014d1';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('438f1465-c2ee-5e2f-afbd-ab567c0014d1', 'ウォッカ', 15, 'ml', 0),
  ('438f1465-c2ee-5e2f-afbd-ab567c0014d1', 'ドライジン', 15, 'ml', 1),
  ('438f1465-c2ee-5e2f-afbd-ab567c0014d1', 'ホワイトラム', 15, 'ml', 2),
  ('438f1465-c2ee-5e2f-afbd-ab567c0014d1', 'テキーラ', 15, 'ml', 3),
  ('438f1465-c2ee-5e2f-afbd-ab567c0014d1', 'ホワイトキュラソー', 15, 'ml', 4),
  ('438f1465-c2ee-5e2f-afbd-ab567c0014d1', 'レモン果汁', 25, 'ml', 5),
  ('438f1465-c2ee-5e2f-afbd-ab567c0014d1', 'シュガーシロップ', 20, 'ml', 6),
  ('438f1465-c2ee-5e2f-afbd-ab567c0014d1', 'コーラ', 30, 'ml', 7);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('438f1465-c2ee-5e2f-afbd-ab567c0014d1', 'シェイカーにコーラ以外の材料と氷を入れてシェイクする。', 0),
  ('438f1465-c2ee-5e2f-afbd-ab567c0014d1', '氷入りグラスに注ぐ。', 1),
  ('438f1465-c2ee-5e2f-afbd-ab567c0014d1', 'コーラを静かに注いで仕上げる。', 2);

-- macunaima
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '557833db-d645-5d6f-8479-e112025f0538',
  'macunaima',
  'マクナイマ',
  'Macunaima',
  'カシャッサ、フェルネット、ライム、シロップで作る、サンパウロ発の現代クラシック。',
  'Cachaca',
  24,
  'Brazil',
  NULL,
  'none',
  ARRAY['マクナイーマ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '93889860-2b01-5018-8a0c-ff238ad3b89c',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '557833db-d645-5d6f-8479-e112025f0538',
  'マクナイマ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '93889860-2b01-5018-8a0c-ff238ad3b89c';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '93889860-2b01-5018-8a0c-ff238ad3b89c';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('93889860-2b01-5018-8a0c-ff238ad3b89c', 'カシャッサ', 45, 'ml', 0),
  ('93889860-2b01-5018-8a0c-ff238ad3b89c', 'フェルネットブランカ', 15, 'ml', 1),
  ('93889860-2b01-5018-8a0c-ff238ad3b89c', 'ライムジュース', 20, 'ml', 2),
  ('93889860-2b01-5018-8a0c-ff238ad3b89c', 'シュガーシロップ', 20, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('93889860-2b01-5018-8a0c-ff238ad3b89c', 'シェーカーに材料と氷を入れる。', 0),
  ('93889860-2b01-5018-8a0c-ff238ad3b89c', 'しっかりシェイクして冷やす。', 1),
  ('93889860-2b01-5018-8a0c-ff238ad3b89c', '冷やしたグラスに注ぐ。', 2);

-- mai-tai
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '7168f33f-d07f-5edc-a0ab-4dd4b19f72f8',
  'mai-tai',
  'マイタイ',
  'Mai Tai',
  'ラムを主体にオレンジリキュールとライム、オルジェアで仕上げるトロピカルクラシック。',
  'Rum',
  22,
  'United States',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'f89db70a-d952-5400-b7b0-b5bd77a3d839',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '7168f33f-d07f-5edc-a0ab-4dd4b19f72f8',
  'マイタイ（基本レシピ）',
  'フロートでダークラムを浮かせてもよい。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'f89db70a-d952-5400-b7b0-b5bd77a3d839';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'f89db70a-d952-5400-b7b0-b5bd77a3d839';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('f89db70a-d952-5400-b7b0-b5bd77a3d839', 'ホワイトラム', 30, 'ml', 0),
  ('f89db70a-d952-5400-b7b0-b5bd77a3d839', 'ダークラム', 30, 'ml', 1),
  ('f89db70a-d952-5400-b7b0-b5bd77a3d839', 'オレンジキュラソー', 15, 'ml', 2),
  ('f89db70a-d952-5400-b7b0-b5bd77a3d839', 'ライム果汁', 20, 'ml', 3),
  ('f89db70a-d952-5400-b7b0-b5bd77a3d839', 'オルジェアシロップ', 10, 'ml', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('f89db70a-d952-5400-b7b0-b5bd77a3d839', 'シェイカーに氷と材料を入れる。', 0),
  ('f89db70a-d952-5400-b7b0-b5bd77a3d839', 'シェイクしてロックグラスに注ぐ。', 1),
  ('f89db70a-d952-5400-b7b0-b5bd77a3d839', 'ミントとライムを飾る。', 2);

-- mamie-taylor
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '342434fa-3fe4-5693-90ef-e16ba73c0e4b',
  'mamie-taylor',
  'メイミーテイラー',
  'Mamie Taylor',
  'スコッチ、ライム、ジンジャーエールで作る、モスコミュール以前からのハイボール。',
  'Whisky',
  10,
  'United States',
  NULL,
  'none',
  ARRAY['マミー・テイラー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '857dd8cd-8124-5491-a706-d72a14e62f99',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '342434fa-3fe4-5693-90ef-e16ba73c0e4b',
  'メイミーテイラー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '857dd8cd-8124-5491-a706-d72a14e62f99';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '857dd8cd-8124-5491-a706-d72a14e62f99';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('857dd8cd-8124-5491-a706-d72a14e62f99', 'スコッチウイスキー', 45, 'ml', 0),
  ('857dd8cd-8124-5491-a706-d72a14e62f99', 'ライムジュース', 15, 'ml', 1),
  ('857dd8cd-8124-5491-a706-d72a14e62f99', 'ジンジャーエール', 120, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('857dd8cd-8124-5491-a706-d72a14e62f99', 'グラスに氷を入れる。', 0),
  ('857dd8cd-8124-5491-a706-d72a14e62f99', '材料を順に注ぐ。', 1),
  ('857dd8cd-8124-5491-a706-d72a14e62f99', '軽く混ぜて仕上げる。', 2);

-- manhattan
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c0c00000-0000-4000-8000-000000000002',
  'manhattan',
  'マンハッタン',
  'Manhattan',
  'ウイスキーとスイートベルモットをステアした「カクテルの女王」。芳醇で気品ある甘みとビターズの香りが特徴。',
  'Whisky',
  30,
  'United States',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'e887cd2f-356d-5cf0-8ce3-32abdbba5a84',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c0c00000-0000-4000-8000-000000000002',
  'マンハッタン（基本レシピ）',
  'ステアは静かに丁寧に。チェリーはマラスキーノを添える。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'e887cd2f-356d-5cf0-8ce3-32abdbba5a84';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'e887cd2f-356d-5cf0-8ce3-32abdbba5a84';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('e887cd2f-356d-5cf0-8ce3-32abdbba5a84', 'ライウイスキー', 45, 'ml', 0),
  ('e887cd2f-356d-5cf0-8ce3-32abdbba5a84', 'スイートベルモット', 15, 'ml', 1),
  ('e887cd2f-356d-5cf0-8ce3-32abdbba5a84', 'アンゴスチュラビターズ', 1, 'dash', 2),
  ('e887cd2f-356d-5cf0-8ce3-32abdbba5a84', 'マラスキーノチェリー', 1, 'piece', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('e887cd2f-356d-5cf0-8ce3-32abdbba5a84', 'ミキシンググラスに氷を入れ、材料を注ぐ。', 0),
  ('e887cd2f-356d-5cf0-8ce3-32abdbba5a84', '静かにステアして冷やす。', 1),
  ('e887cd2f-356d-5cf0-8ce3-32abdbba5a84', 'カクテルグラスに注ぎ、チェリーを飾る。', 2);

-- margarita
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c0c00000-0000-4000-8000-000000000007',
  'margarita',
  'マルガリータ',
  'Margarita',
  'テキーラ、ホワイトキュラソー、ライムをシェイクし、塩でスノースタイルにしたメキシコ生まれの世界的カクテル。',
  'Tequila',
  25,
  'Mexico',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'ba120aaf-9e98-5fd5-a20b-6e3fd5e62948',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c0c00000-0000-4000-8000-000000000007',
  'マルガリータ（基本レシピ）',
  'グラスの縁に塩を付けるスノースタイルで。シェイクは強めに。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'ba120aaf-9e98-5fd5-a20b-6e3fd5e62948';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'ba120aaf-9e98-5fd5-a20b-6e3fd5e62948';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('ba120aaf-9e98-5fd5-a20b-6e3fd5e62948', 'テキーラ', 45, 'ml', 0),
  ('ba120aaf-9e98-5fd5-a20b-6e3fd5e62948', 'ホワイトキュラソー', 20, 'ml', 1),
  ('ba120aaf-9e98-5fd5-a20b-6e3fd5e62948', 'ライム果汁', 15, 'ml', 2),
  ('ba120aaf-9e98-5fd5-a20b-6e3fd5e62948', '塩', NULL, NULL, 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('ba120aaf-9e98-5fd5-a20b-6e3fd5e62948', 'クーペグラスの縁をライムで湿らせ、塩を付ける。', 0),
  ('ba120aaf-9e98-5fd5-a20b-6e3fd5e62948', 'シェイカーに氷と材料を入れ、強くシェイクする。', 1),
  ('ba120aaf-9e98-5fd5-a20b-6e3fd5e62948', 'グラスに注ぐ。', 2);

-- martinez
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '2bfa885a-ac3e-5f49-98c0-9df17b251426',
  'martinez',
  'マルティネス',
  'Martinez',
  'マティーニの原型ともされる、ジンとスイートベルモットの芳醇な一杯。',
  'Gin',
  29,
  'United States',
  NULL,
  'none',
  ARRAY['マルチネス']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '4fd3515b-e0e0-5f01-ad65-a91c6528cbd7',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '2bfa885a-ac3e-5f49-98c0-9df17b251426',
  'マルティネス（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '4fd3515b-e0e0-5f01-ad65-a91c6528cbd7';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '4fd3515b-e0e0-5f01-ad65-a91c6528cbd7';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('4fd3515b-e0e0-5f01-ad65-a91c6528cbd7', 'オールドトムジン', 45, 'ml', 0),
  ('4fd3515b-e0e0-5f01-ad65-a91c6528cbd7', 'スイートベルモット', 45, 'ml', 1),
  ('4fd3515b-e0e0-5f01-ad65-a91c6528cbd7', 'マラスキーノリキュール', 5, 'ml', 2),
  ('4fd3515b-e0e0-5f01-ad65-a91c6528cbd7', 'オレンジビターズ', 1, 'dash', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('4fd3515b-e0e0-5f01-ad65-a91c6528cbd7', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('4fd3515b-e0e0-5f01-ad65-a91c6528cbd7', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('4fd3515b-e0e0-5f01-ad65-a91c6528cbd7', '冷やしたグラスに注ぐ。', 2);

-- mary-pickford
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c9a4d832-974a-579d-9a09-741a75223d03',
  'mary-pickford',
  'メアリーピックフォード',
  'Mary Pickford',
  'ライトラム、パイナップル、グレナデン、マラスキーノで作るキューバのクラシック。',
  'Rum',
  19,
  'Cuba',
  NULL,
  'none',
  ARRAY['メアリー・ピックフォード']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'a3071cda-d7f6-5c22-aa0a-45f53b5b51b0',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c9a4d832-974a-579d-9a09-741a75223d03',
  'メアリーピックフォード（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'a3071cda-d7f6-5c22-aa0a-45f53b5b51b0';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'a3071cda-d7f6-5c22-aa0a-45f53b5b51b0';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('a3071cda-d7f6-5c22-aa0a-45f53b5b51b0', 'ライトラム', 45, 'ml', 0),
  ('a3071cda-d7f6-5c22-aa0a-45f53b5b51b0', 'パイナップルジュース', 45, 'ml', 1),
  ('a3071cda-d7f6-5c22-aa0a-45f53b5b51b0', 'グレナデンシロップ', 5, 'ml', 2),
  ('a3071cda-d7f6-5c22-aa0a-45f53b5b51b0', 'マラスキーノリキュール', 5, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('a3071cda-d7f6-5c22-aa0a-45f53b5b51b0', 'シェーカーに材料と氷を入れる。', 0),
  ('a3071cda-d7f6-5c22-aa0a-45f53b5b51b0', 'しっかりシェイクして冷やす。', 1),
  ('a3071cda-d7f6-5c22-aa0a-45f53b5b51b0', '冷やしたグラスに注ぐ。', 2);

-- matador
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'd6e46be6-2bc8-5b7d-9489-4f2464d9229f',
  'matador',
  'マタドール',
  'Matador',
  'テキーラにパイナップルとライムを合わせる、トロピカルなクラシック。',
  'Tequila',
  16,
  'Mexico',
  NULL,
  'none',
  ARRAY['マタドールカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '2256ece3-ad2c-56de-8088-b059a5a718f9',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'd6e46be6-2bc8-5b7d-9489-4f2464d9229f',
  'マタドール（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '2256ece3-ad2c-56de-8088-b059a5a718f9';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '2256ece3-ad2c-56de-8088-b059a5a718f9';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('2256ece3-ad2c-56de-8088-b059a5a718f9', 'テキーラブランコ', 45, 'ml', 0),
  ('2256ece3-ad2c-56de-8088-b059a5a718f9', 'パイナップルジュース', 75, 'ml', 1),
  ('2256ece3-ad2c-56de-8088-b059a5a718f9', 'ライムジュース', 15, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('2256ece3-ad2c-56de-8088-b059a5a718f9', 'シェーカーに材料と氷を入れる。', 0),
  ('2256ece3-ad2c-56de-8088-b059a5a718f9', 'しっかりシェイクして冷やす。', 1),
  ('2256ece3-ad2c-56de-8088-b059a5a718f9', '冷やしたグラスに注ぐ。', 2);

-- metropolitan
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '4523fc4f-253a-5c4c-b209-e54872288415',
  'metropolitan',
  'メトロポリタン',
  'Metropolitan',
  'ブランデー、スイートベルモット、シロップ、ビターズで作るマンハッタン系の古典。',
  'Brandy',
  28,
  'United States',
  NULL,
  'none',
  ARRAY['メトロポリタンカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '48047b8a-14e7-5815-abf3-0b7d6f48f3c4',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '4523fc4f-253a-5c4c-b209-e54872288415',
  'メトロポリタン（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '48047b8a-14e7-5815-abf3-0b7d6f48f3c4';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '48047b8a-14e7-5815-abf3-0b7d6f48f3c4';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('48047b8a-14e7-5815-abf3-0b7d6f48f3c4', 'ブランデー', 45, 'ml', 0),
  ('48047b8a-14e7-5815-abf3-0b7d6f48f3c4', 'スイートベルモット', 30, 'ml', 1),
  ('48047b8a-14e7-5815-abf3-0b7d6f48f3c4', 'シュガーシロップ', 5, 'ml', 2),
  ('48047b8a-14e7-5815-abf3-0b7d6f48f3c4', 'アンゴスチュラビターズ', 2, 'dash', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('48047b8a-14e7-5815-abf3-0b7d6f48f3c4', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('48047b8a-14e7-5815-abf3-0b7d6f48f3c4', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('48047b8a-14e7-5815-abf3-0b7d6f48f3c4', '冷やしたグラスに注ぐ。', 2);

-- mexican-mule
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '60b0eaaa-9fa6-5ac2-a843-58cf42ff470a',
  'mexican-mule',
  'メキシカンミュール',
  'Mexican Mule',
  'モスコミュールをテキーラで作る、ライムとジンジャーが爽快な一杯。',
  'Tequila',
  11,
  'Mexico',
  NULL,
  'none',
  ARRAY['テキーラムュール']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '582a08d1-7179-520f-ad73-450e1c36d919',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '60b0eaaa-9fa6-5ac2-a843-58cf42ff470a',
  'メキシカンミュール（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '582a08d1-7179-520f-ad73-450e1c36d919';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '582a08d1-7179-520f-ad73-450e1c36d919';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('582a08d1-7179-520f-ad73-450e1c36d919', 'テキーラブランコ', 45, 'ml', 0),
  ('582a08d1-7179-520f-ad73-450e1c36d919', 'ライムジュース', 15, 'ml', 1),
  ('582a08d1-7179-520f-ad73-450e1c36d919', 'ジンジャービア', 120, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('582a08d1-7179-520f-ad73-450e1c36d919', 'グラスに氷を入れる。', 0),
  ('582a08d1-7179-520f-ad73-450e1c36d919', '材料を順に注ぐ。', 1),
  ('582a08d1-7179-520f-ad73-450e1c36d919', '軽く混ぜて仕上げる。', 2);

-- mint-julep
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '42b040f0-a9aa-51f7-8ae0-26f6bfe614db',
  'mint-julep',
  'ミントジュレップ',
  'Mint Julep',
  'バーボン、ミント、砂糖を砕氷で仕上げるケンタッキーダービーの公式ドリンク。',
  'Whisky',
  25,
  'United States',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'f379887f-5882-5650-8976-b4d801d9fda4',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '42b040f0-a9aa-51f7-8ae0-26f6bfe614db',
  'ミントジュレップ（基本レシピ）',
  'ミントは叩きすぎず香りだけを立たせる。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'f379887f-5882-5650-8976-b4d801d9fda4';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'f379887f-5882-5650-8976-b4d801d9fda4';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('f379887f-5882-5650-8976-b4d801d9fda4', 'バーボンウイスキー', 60, 'ml', 0),
  ('f379887f-5882-5650-8976-b4d801d9fda4', 'ミントの葉', 10, 'piece', 1),
  ('f379887f-5882-5650-8976-b4d801d9fda4', 'シュガーシロップ', 15, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('f379887f-5882-5650-8976-b4d801d9fda4', 'グラスでミントとシロップを軽く押す。', 0),
  ('f379887f-5882-5650-8976-b4d801d9fda4', '砕氷を高く盛り、バーボンを注ぐ。', 1),
  ('f379887f-5882-5650-8976-b4d801d9fda4', '軽く混ぜ、ミントの穂を飾る。', 2);

-- mojito
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c0c00000-0000-4000-8000-000000000003',
  'mojito',
  'モヒート',
  'Mojito',
  'ホワイトラム、ライム、ミント、砂糖、ソーダで作るキューバ生まれの定番カクテル。爽やかで飲みやすい夏の一杯。',
  'Rum',
  10,
  'Cuba',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '1a225b91-39fc-5c49-bb47-7b849ed3b1e2',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c0c00000-0000-4000-8000-000000000003',
  'モヒート（基本レシピ）',
  'ミントは潰しすぎず香りを立たせる。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '1a225b91-39fc-5c49-bb47-7b849ed3b1e2';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '1a225b91-39fc-5c49-bb47-7b849ed3b1e2';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('1a225b91-39fc-5c49-bb47-7b849ed3b1e2', 'ホワイトラム', 45, 'ml', 0),
  ('1a225b91-39fc-5c49-bb47-7b849ed3b1e2', 'ライム果汁', 20, 'ml', 1),
  ('1a225b91-39fc-5c49-bb47-7b849ed3b1e2', '砂糖', 2, 'tsp', 2),
  ('1a225b91-39fc-5c49-bb47-7b849ed3b1e2', 'ミントの葉', 10, 'piece', 3),
  ('1a225b91-39fc-5c49-bb47-7b849ed3b1e2', '炭酸水', 60, 'ml', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('1a225b91-39fc-5c49-bb47-7b849ed3b1e2', 'グラスにミント、砂糖、ライム果汁を入れ、軽くマドラーで押す。', 0),
  ('1a225b91-39fc-5c49-bb47-7b849ed3b1e2', '砕氷を入れ、ホワイトラムを注ぐ。', 1),
  ('1a225b91-39fc-5c49-bb47-7b849ed3b1e2', '炭酸水を加えて軽く混ぜ、ミントを飾る。', 2);

-- monkey-gland
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'de839e7a-108f-5264-8249-2d6fb402ed3b',
  'monkey-gland',
  'モンキーグランド',
  'Monkey Gland',
  'ジンとオレンジにグレナデンとアブサンを効かせる、1920年代パリの一杯。',
  'Gin',
  24,
  'France',
  NULL,
  'none',
  ARRAY['モンキー・グランド']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '9da1d14c-5752-5be4-a545-ccf1bd0bf9eb',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'de839e7a-108f-5264-8249-2d6fb402ed3b',
  'モンキーグランド（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '9da1d14c-5752-5be4-a545-ccf1bd0bf9eb';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '9da1d14c-5752-5be4-a545-ccf1bd0bf9eb';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('9da1d14c-5752-5be4-a545-ccf1bd0bf9eb', 'ドライジン', 45, 'ml', 0),
  ('9da1d14c-5752-5be4-a545-ccf1bd0bf9eb', 'オレンジジュース', 45, 'ml', 1),
  ('9da1d14c-5752-5be4-a545-ccf1bd0bf9eb', 'グレナデンシロップ', 5, 'ml', 2),
  ('9da1d14c-5752-5be4-a545-ccf1bd0bf9eb', 'アブサン', 1, 'dash', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('9da1d14c-5752-5be4-a545-ccf1bd0bf9eb', 'シェーカーに材料と氷を入れる。', 0),
  ('9da1d14c-5752-5be4-a545-ccf1bd0bf9eb', 'しっかりシェイクして冷やす。', 1),
  ('9da1d14c-5752-5be4-a545-ccf1bd0bf9eb', '冷やしたグラスに注ぐ。', 2);

-- moscow-mule
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '98343bf2-c6eb-5fb0-b188-98c41e062ea8',
  'moscow-mule',
  'モスコミュール',
  'Moscow Mule',
  'ウォッカ、ジンジャービア、ライムで作るアメリカ発のモダンクラシック。銅マグで出すスタイルが象徴的。',
  'Vodka',
  12,
  'United States',
  NULL,
  'none',
  ARRAY['モスクワミュール']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'f696662f-9e81-53e2-80de-90f6425d144e',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '98343bf2-c6eb-5fb0-b188-98c41e062ea8',
  'モスコミュール（基本レシピ）',
  'ジンジャービアはよく冷やしたものを使う。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'f696662f-9e81-53e2-80de-90f6425d144e';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'f696662f-9e81-53e2-80de-90f6425d144e';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('f696662f-9e81-53e2-80de-90f6425d144e', 'ウォッカ', 45, 'ml', 0),
  ('f696662f-9e81-53e2-80de-90f6425d144e', 'ライム果汁', 15, 'ml', 1),
  ('f696662f-9e81-53e2-80de-90f6425d144e', 'ジンジャービア', 120, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('f696662f-9e81-53e2-80de-90f6425d144e', '銅マグまたはグラスに氷を入れる。', 0),
  ('f696662f-9e81-53e2-80de-90f6425d144e', 'ウォッカとライム果汁を注ぐ。', 1),
  ('f696662f-9e81-53e2-80de-90f6425d144e', 'ジンジャービアを注ぎ、軽く混ぜてライムを飾る。', 2);

-- navy-grog
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '46999470-8b34-5fdb-bade-67e142724f21',
  'navy-grog',
  'ネイビーグロッグ',
  'Navy Grog',
  '複数のラムとグレープフルーツ、蜂蜜を合わせるティキの代表作。',
  'Rum',
  21,
  'United States',
  NULL,
  'none',
  ARRAY['ネイビー・グロッグ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '186a92e5-8aa8-51f6-8023-91efe01f2821',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '46999470-8b34-5fdb-bade-67e142724f21',
  'ネイビーグロッグ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '186a92e5-8aa8-51f6-8023-91efe01f2821';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '186a92e5-8aa8-51f6-8023-91efe01f2821';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('186a92e5-8aa8-51f6-8023-91efe01f2821', 'ライトラム', 30, 'ml', 0),
  ('186a92e5-8aa8-51f6-8023-91efe01f2821', 'ダークラム', 30, 'ml', 1),
  ('186a92e5-8aa8-51f6-8023-91efe01f2821', 'デメラララム', 30, 'ml', 2),
  ('186a92e5-8aa8-51f6-8023-91efe01f2821', 'グレープフルーツジュース', 30, 'ml', 3),
  ('186a92e5-8aa8-51f6-8023-91efe01f2821', 'ライムジュース', 20, 'ml', 4),
  ('186a92e5-8aa8-51f6-8023-91efe01f2821', '蜂蜜シロップ', 15, 'ml', 5);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('186a92e5-8aa8-51f6-8023-91efe01f2821', 'シェーカーに材料と氷を入れる。', 0),
  ('186a92e5-8aa8-51f6-8023-91efe01f2821', 'しっかりシェイクして冷やす。', 1),
  ('186a92e5-8aa8-51f6-8023-91efe01f2821', '冷やしたグラスに注ぐ。', 2);

-- negroni
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c0c00000-0000-4000-8000-000000000005',
  'negroni',
  'ネグローニ',
  'Negroni',
  'ジン、カンパリ、スイートベルモットを等量で割るイタリアの名作カクテル。ほろ苦くビターな味わいが通好み。',
  'Gin',
  24,
  'Italy',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '037c40e2-f683-5c3e-b431-ea02d30be946',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c0c00000-0000-4000-8000-000000000005',
  'ネグローニ（基本レシピ）',
  'オレンジピールをねじって香りを纏わせる。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '037c40e2-f683-5c3e-b431-ea02d30be946';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '037c40e2-f683-5c3e-b431-ea02d30be946';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('037c40e2-f683-5c3e-b431-ea02d30be946', 'ドライジン', 30, 'ml', 0),
  ('037c40e2-f683-5c3e-b431-ea02d30be946', 'カンパリ', 30, 'ml', 1),
  ('037c40e2-f683-5c3e-b431-ea02d30be946', 'スイートベルモット', 30, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('037c40e2-f683-5c3e-b431-ea02d30be946', 'ロックグラスに大きな氷を入れる。', 0),
  ('037c40e2-f683-5c3e-b431-ea02d30be946', 'ジン、カンパリ、スイートベルモットを等量注ぐ。', 1),
  ('037c40e2-f683-5c3e-b431-ea02d30be946', '軽くステアし、オレンジピールを飾る。', 2);

-- new-york-sour
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'e96d6c82-4297-5110-8106-aa0a1e24116d',
  'new-york-sour',
  'ニューヨークサワー',
  'New York Sour',
  'ウイスキーサワーに赤ワインを浮かべる、華やかなクラシック。',
  'Whisky',
  18,
  'United States',
  NULL,
  'none',
  ARRAY['ニューヨーク・サワー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '25ab6922-83d8-535e-b3e2-7137b484cf95',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'e96d6c82-4297-5110-8106-aa0a1e24116d',
  'ニューヨークサワー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '25ab6922-83d8-535e-b3e2-7137b484cf95';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '25ab6922-83d8-535e-b3e2-7137b484cf95';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('25ab6922-83d8-535e-b3e2-7137b484cf95', 'ライウイスキー', 45, 'ml', 0),
  ('25ab6922-83d8-535e-b3e2-7137b484cf95', 'レモンジュース', 20, 'ml', 1),
  ('25ab6922-83d8-535e-b3e2-7137b484cf95', 'シュガーシロップ', 15, 'ml', 2),
  ('25ab6922-83d8-535e-b3e2-7137b484cf95', '赤ワイン', 20, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('25ab6922-83d8-535e-b3e2-7137b484cf95', 'シェーカーに材料と氷を入れる。', 0),
  ('25ab6922-83d8-535e-b3e2-7137b484cf95', 'しっかりシェイクして冷やす。', 1),
  ('25ab6922-83d8-535e-b3e2-7137b484cf95', '冷やしたグラスに注ぐ。', 2);

-- nikolaschka
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '40c29e1d-03b9-56e6-9f2b-989a33fe51ab',
  'nikolaschka',
  'ニコラシカ',
  'Nikolaschka',
  'ブランデーに砂糖とレモンを添える、独特の飲み方で知られるクラシック。',
  'Brandy',
  35,
  'Germany',
  NULL,
  'none',
  ARRAY['ニコラシュカ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'eccfb93e-f145-5abc-81c4-52e81d43e8ce',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '40c29e1d-03b9-56e6-9f2b-989a33fe51ab',
  'ニコラシカ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'eccfb93e-f145-5abc-81c4-52e81d43e8ce';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'eccfb93e-f145-5abc-81c4-52e81d43e8ce';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('eccfb93e-f145-5abc-81c4-52e81d43e8ce', 'ブランデー', 45, 'ml', 0),
  ('eccfb93e-f145-5abc-81c4-52e81d43e8ce', 'レモンスライス', 1, 'piece', 1),
  ('eccfb93e-f145-5abc-81c4-52e81d43e8ce', '砂糖', 1, 'tsp', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('eccfb93e-f145-5abc-81c4-52e81d43e8ce', 'グラスに氷を入れる。', 0),
  ('eccfb93e-f145-5abc-81c4-52e81d43e8ce', '材料を順に注ぐ。', 1),
  ('eccfb93e-f145-5abc-81c4-52e81d43e8ce', '軽く混ぜて仕上げる。', 2);

-- oaxaca-old-fashioned
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '55fb3713-48f8-5b41-9e96-5aea17014784',
  'oaxaca-old-fashioned',
  'オアハカオールドファッションド',
  'Oaxaca Old Fashioned',
  'テキーラとメスカルをアガベでまとめる、現代テキーラカクテルの代表作。',
  'Tequila',
  32,
  'United States',
  NULL,
  'none',
  ARRAY['オアハカ・オールドファッションド']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'd76d368f-f645-55a0-ae0c-942e8b79c0df',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '55fb3713-48f8-5b41-9e96-5aea17014784',
  'オアハカオールドファッションド（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'd76d368f-f645-55a0-ae0c-942e8b79c0df';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'd76d368f-f645-55a0-ae0c-942e8b79c0df';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('d76d368f-f645-55a0-ae0c-942e8b79c0df', 'テキーラレポサド', 45, 'ml', 0),
  ('d76d368f-f645-55a0-ae0c-942e8b79c0df', 'メスカル', 15, 'ml', 1),
  ('d76d368f-f645-55a0-ae0c-942e8b79c0df', 'アガベシロップ', 1, 'tsp', 2),
  ('d76d368f-f645-55a0-ae0c-942e8b79c0df', 'アンゴスチュラビターズ', 2, 'dash', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('d76d368f-f645-55a0-ae0c-942e8b79c0df', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('d76d368f-f645-55a0-ae0c-942e8b79c0df', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('d76d368f-f645-55a0-ae0c-942e8b79c0df', '冷やしたグラスに注ぐ。', 2);

-- old-fashioned
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c0c00000-0000-4000-8000-000000000006',
  'old-fashioned',
  'オールドファッションド',
  'Old Fashioned',
  'バーボンまたはライウイスキーに角砂糖とビターズを加えた、カクテルの原点。シンプルだが奥深い大人の味わい。',
  'Whisky',
  32,
  'United States',
  NULL,
  'none',
  ARRAY['オールドファッション']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '8004c29b-06f2-53f9-9f9c-d6f739535c9c',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c0c00000-0000-4000-8000-000000000006',
  'オールドファッションド（基本レシピ）',
  '角砂糖にビターズを染み込ませてから潰すのが本式。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '8004c29b-06f2-53f9-9f9c-d6f739535c9c';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '8004c29b-06f2-53f9-9f9c-d6f739535c9c';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('8004c29b-06f2-53f9-9f9c-d6f739535c9c', 'バーボンウイスキー', 45, 'ml', 0),
  ('8004c29b-06f2-53f9-9f9c-d6f739535c9c', '角砂糖', 1, 'piece', 1),
  ('8004c29b-06f2-53f9-9f9c-d6f739535c9c', 'アンゴスチュラビターズ', 2, 'dash', 2),
  ('8004c29b-06f2-53f9-9f9c-d6f739535c9c', '水', 5, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('8004c29b-06f2-53f9-9f9c-d6f739535c9c', 'グラスに角砂糖とビターズ、少量の水を入れ、マドラーで溶かす。', 0),
  ('8004c29b-06f2-53f9-9f9c-d6f739535c9c', '大きな氷を入れ、バーボンを注ぐ。', 1),
  ('8004c29b-06f2-53f9-9f9c-d6f739535c9c', '軽くステアし、オレンジピールを飾る。', 2);

-- oolong-hai
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'ee6dd2c6-255f-5e09-b227-469bc2db522c',
  'oolong-hai',
  'ウーロンハイ',
  'Oolong Hai',
  '焼酎を烏龍茶で割る、居酒屋と日本のバーで定番の軽い一杯。',
  'Shochu',
  7,
  'Japan',
  NULL,
  'none',
  ARRAY['烏龍ハイ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'b488a0c6-4fa8-5a0f-89fb-a0fbf5135ad3',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'ee6dd2c6-255f-5e09-b227-469bc2db522c',
  'ウーロンハイ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'b488a0c6-4fa8-5a0f-89fb-a0fbf5135ad3';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'b488a0c6-4fa8-5a0f-89fb-a0fbf5135ad3';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('b488a0c6-4fa8-5a0f-89fb-a0fbf5135ad3', '焼酎', 45, 'ml', 0),
  ('b488a0c6-4fa8-5a0f-89fb-a0fbf5135ad3', '烏龍茶', 135, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('b488a0c6-4fa8-5a0f-89fb-a0fbf5135ad3', 'グラスに氷を入れる。', 0),
  ('b488a0c6-4fa8-5a0f-89fb-a0fbf5135ad3', '材料を順に注ぐ。', 1),
  ('b488a0c6-4fa8-5a0f-89fb-a0fbf5135ad3', '軽く混ぜて仕上げる。', 2);

-- painkiller
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c737e157-0c97-569c-aa10-58054e2796ce',
  'painkiller',
  'ペインキラー',
  'Painkiller',
  'ダークラム、パイナップル、オレンジ、ココナッツで作る英領バージン諸島の定番。',
  'Rum',
  14,
  'British Virgin Islands',
  NULL,
  'none',
  ARRAY['ペインキラーカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'f41e62c4-edea-5e19-9aa0-584c116a801c',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c737e157-0c97-569c-aa10-58054e2796ce',
  'ペインキラー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'f41e62c4-edea-5e19-9aa0-584c116a801c';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'f41e62c4-edea-5e19-9aa0-584c116a801c';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('f41e62c4-edea-5e19-9aa0-584c116a801c', 'ダークラム', 60, 'ml', 0),
  ('f41e62c4-edea-5e19-9aa0-584c116a801c', 'パイナップルジュース', 120, 'ml', 1),
  ('f41e62c4-edea-5e19-9aa0-584c116a801c', 'オレンジジュース', 30, 'ml', 2),
  ('f41e62c4-edea-5e19-9aa0-584c116a801c', 'ココナッツクリーム', 30, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('f41e62c4-edea-5e19-9aa0-584c116a801c', 'シェーカーに材料と氷を入れる。', 0),
  ('f41e62c4-edea-5e19-9aa0-584c116a801c', 'しっかりシェイクして冷やす。', 1),
  ('f41e62c4-edea-5e19-9aa0-584c116a801c', '冷やしたグラスに注ぐ。', 2);

-- paloma
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '60d16e45-0525-5378-9143-96dad496fb66',
  'paloma',
  'パロマ',
  'Paloma',
  'テキーラとグレープフルーツソーダの爽やかなロングドリンク。メキシコでマルガリータ以上に親しまれる。',
  'Tequila',
  12,
  'Mexico',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '385091da-42aa-5eed-a518-8825b5a91165',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '60d16e45-0525-5378-9143-96dad496fb66',
  'パロマ（基本レシピ）',
  NULL,
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '385091da-42aa-5eed-a518-8825b5a91165';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '385091da-42aa-5eed-a518-8825b5a91165';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('385091da-42aa-5eed-a518-8825b5a91165', 'テキーラ', 45, 'ml', 0),
  ('385091da-42aa-5eed-a518-8825b5a91165', 'ライム果汁', 15, 'ml', 1),
  ('385091da-42aa-5eed-a518-8825b5a91165', 'グレープフルーツソーダ', 120, 'ml', 2),
  ('385091da-42aa-5eed-a518-8825b5a91165', '塩', NULL, NULL, 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('385091da-42aa-5eed-a518-8825b5a91165', 'グラスの縁に塩を付け、氷を入れる。', 0),
  ('385091da-42aa-5eed-a518-8825b5a91165', 'テキーラとライム果汁を注ぐ。', 1),
  ('385091da-42aa-5eed-a518-8825b5a91165', 'グレープフルーツソーダを注ぎ、軽く混ぜる。', 2);

-- paper-plane
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '96423a48-ea29-570a-9975-2200193e56fc',
  'paper-plane',
  'ペーパープレーン',
  'Paper Plane',
  'バーボン、アマーロ、アペロール、レモンを等量で合わせる現代クラシック。',
  'Whisky',
  23,
  'United States',
  NULL,
  'none',
  ARRAY['ペーパー・プレーン']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '72b59864-d2fa-55b7-9a34-bb423185fc69',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '96423a48-ea29-570a-9975-2200193e56fc',
  'ペーパープレーン（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '72b59864-d2fa-55b7-9a34-bb423185fc69';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '72b59864-d2fa-55b7-9a34-bb423185fc69';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('72b59864-d2fa-55b7-9a34-bb423185fc69', 'バーボンウイスキー', 22.5, 'ml', 0),
  ('72b59864-d2fa-55b7-9a34-bb423185fc69', 'アマーロ', 22.5, 'ml', 1),
  ('72b59864-d2fa-55b7-9a34-bb423185fc69', 'アペロール', 22.5, 'ml', 2),
  ('72b59864-d2fa-55b7-9a34-bb423185fc69', 'レモンジュース', 22.5, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('72b59864-d2fa-55b7-9a34-bb423185fc69', 'シェーカーに材料と氷を入れる。', 0),
  ('72b59864-d2fa-55b7-9a34-bb423185fc69', 'しっかりシェイクして冷やす。', 1),
  ('72b59864-d2fa-55b7-9a34-bb423185fc69', '冷やしたグラスに注ぐ。', 2);

-- paradise
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '594eae24-89b3-53b9-a316-2eeca37052cf',
  'paradise',
  'パラダイス',
  'Paradise',
  'ジン、アプリコット、オレンジを合わせるフルーティーなIBAクラシック。',
  'Gin',
  22,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['パラダイスカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '4928e4bd-8923-5d51-88ed-fb761100e28e',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '594eae24-89b3-53b9-a316-2eeca37052cf',
  'パラダイス（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '4928e4bd-8923-5d51-88ed-fb761100e28e';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '4928e4bd-8923-5d51-88ed-fb761100e28e';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('4928e4bd-8923-5d51-88ed-fb761100e28e', 'ドライジン', 35, 'ml', 0),
  ('4928e4bd-8923-5d51-88ed-fb761100e28e', 'アプリコットブランデー', 20, 'ml', 1),
  ('4928e4bd-8923-5d51-88ed-fb761100e28e', 'オレンジジュース', 35, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('4928e4bd-8923-5d51-88ed-fb761100e28e', 'シェーカーに材料と氷を入れる。', 0),
  ('4928e4bd-8923-5d51-88ed-fb761100e28e', 'しっかりシェイクして冷やす。', 1),
  ('4928e4bd-8923-5d51-88ed-fb761100e28e', '冷やしたグラスに注ぐ。', 2);

-- penicillin
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'cf43f361-7985-5a08-8caa-93e9247454c6',
  'penicillin',
  'ペニシリン',
  'Penicillin',
  'スコッチ、ジンジャー、蜂蜜、レモンを合わせる現代の定番ウイスキーカクテル。',
  'Whisky',
  22,
  'United States',
  NULL,
  'none',
  ARRAY['ペニシリンカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '930ac036-7067-538c-ad85-80723f1e7a91',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'cf43f361-7985-5a08-8caa-93e9247454c6',
  'ペニシリン（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '930ac036-7067-538c-ad85-80723f1e7a91';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '930ac036-7067-538c-ad85-80723f1e7a91';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('930ac036-7067-538c-ad85-80723f1e7a91', 'ブレンデッドスコッチ', 45, 'ml', 0),
  ('930ac036-7067-538c-ad85-80723f1e7a91', 'レモンジュース', 20, 'ml', 1),
  ('930ac036-7067-538c-ad85-80723f1e7a91', '蜂蜜ジンジャーシロップ', 20, 'ml', 2),
  ('930ac036-7067-538c-ad85-80723f1e7a91', 'アイラモルト', 10, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('930ac036-7067-538c-ad85-80723f1e7a91', 'シェーカーに材料と氷を入れる。', 0),
  ('930ac036-7067-538c-ad85-80723f1e7a91', 'しっかりシェイクして冷やす。', 1),
  ('930ac036-7067-538c-ad85-80723f1e7a91', '冷やしたグラスに注ぐ。', 2);

-- pina-colada
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'e07fecbf-d666-5734-832f-000d545eb16d',
  'pina-colada',
  'ピニャコラーダ',
  'Piña Colada',
  'ラム、パイナップル、ココナッツミルクのトロピカルカクテル。プエルトリコ発祥の国民的一杯。',
  'Rum',
  13,
  'Puerto Rico',
  NULL,
  'none',
  ARRAY['ピナコラーダ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'c06385cf-48b8-5087-8813-b4c7c186b3fa',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'e07fecbf-d666-5734-832f-000d545eb16d',
  'ピニャコラーダ（基本レシピ）',
  'フローズンにする場合はクラッシュアイスを多めに。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'c06385cf-48b8-5087-8813-b4c7c186b3fa';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'c06385cf-48b8-5087-8813-b4c7c186b3fa';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('c06385cf-48b8-5087-8813-b4c7c186b3fa', 'ホワイトラム', 45, 'ml', 0),
  ('c06385cf-48b8-5087-8813-b4c7c186b3fa', 'ココナッツクリーム', 30, 'ml', 1),
  ('c06385cf-48b8-5087-8813-b4c7c186b3fa', 'パイナップルジュース', 90, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('c06385cf-48b8-5087-8813-b4c7c186b3fa', 'ブレンダーまたはシェイカーに材料と氷を入れる。', 0),
  ('c06385cf-48b8-5087-8813-b4c7c186b3fa', '滑らかになるまで混ぜる。', 1),
  ('c06385cf-48b8-5087-8813-b4c7c186b3fa', 'グラスに注ぎ、パイナップルを飾る。', 2);

-- pink-gin
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '6a87629c-6fe2-5f58-b7f5-cd187a22844b',
  'pink-gin',
  'ピンクジン',
  'Pink Gin',
  'ジンにアンゴスチュラビターズをまとわせる、英国海軍ゆかりのシンプルな古典。',
  'Gin',
  36,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['ピンク・ジン']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'e728b70c-4cec-5df0-a7f4-5b64d9a6e755',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '6a87629c-6fe2-5f58-b7f5-cd187a22844b',
  'ピンクジン（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'e728b70c-4cec-5df0-a7f4-5b64d9a6e755';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'e728b70c-4cec-5df0-a7f4-5b64d9a6e755';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('e728b70c-4cec-5df0-a7f4-5b64d9a6e755', 'ドライジン', 60, 'ml', 0),
  ('e728b70c-4cec-5df0-a7f4-5b64d9a6e755', 'アンゴスチュラビターズ', 3, 'dash', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('e728b70c-4cec-5df0-a7f4-5b64d9a6e755', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('e728b70c-4cec-5df0-a7f4-5b64d9a6e755', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('e728b70c-4cec-5df0-a7f4-5b64d9a6e755', '冷やしたグラスに注ぐ。', 2);

-- pisco-sour
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '043e0588-1df9-55ea-9d50-75591eea6e86',
  'pisco-sour',
  'ピスコサワー',
  'Pisco Sour',
  'ピスコにライム、甘味、卵白を合わせる、ペルーとチリで愛される代表的カクテル。',
  'Brandy',
  20,
  'Peru',
  NULL,
  'none',
  ARRAY['ピスコ・サワー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'd0403e5c-9263-54f5-b8f2-2169d21914a1',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '043e0588-1df9-55ea-9d50-75591eea6e86',
  'ピスコサワー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'd0403e5c-9263-54f5-b8f2-2169d21914a1';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'd0403e5c-9263-54f5-b8f2-2169d21914a1';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('d0403e5c-9263-54f5-b8f2-2169d21914a1', 'ピスコ', 60, 'ml', 0),
  ('d0403e5c-9263-54f5-b8f2-2169d21914a1', 'ライムジュース', 30, 'ml', 1),
  ('d0403e5c-9263-54f5-b8f2-2169d21914a1', 'シュガーシロップ', 20, 'ml', 2),
  ('d0403e5c-9263-54f5-b8f2-2169d21914a1', '卵白', 1, 'piece', 3),
  ('d0403e5c-9263-54f5-b8f2-2169d21914a1', 'アンゴスチュラビターズ', 2, 'dash', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('d0403e5c-9263-54f5-b8f2-2169d21914a1', 'シェーカーに材料と氷を入れる。', 0),
  ('d0403e5c-9263-54f5-b8f2-2169d21914a1', 'しっかりシェイクして冷やす。', 1),
  ('d0403e5c-9263-54f5-b8f2-2169d21914a1', '冷やしたグラスに注ぐ。', 2);

-- planters-punch
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '8b152337-7243-5b75-a4ef-3e4fbd603995',
  'planters-punch',
  'プランターズパンチ',
  'Planter''s Punch',
  'ラムに柑橘、甘味、ビターズを合わせる、カリブ海のパンチスタイル。',
  'Rum',
  15,
  'Jamaica',
  NULL,
  'none',
  ARRAY['プランターズ・パンチ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '48fb3106-817e-5aab-b677-a5cb8fd7543e',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '8b152337-7243-5b75-a4ef-3e4fbd603995',
  'プランターズパンチ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '48fb3106-817e-5aab-b677-a5cb8fd7543e';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '48fb3106-817e-5aab-b677-a5cb8fd7543e';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('48fb3106-817e-5aab-b677-a5cb8fd7543e', 'ダークラム', 50, 'ml', 0),
  ('48fb3106-817e-5aab-b677-a5cb8fd7543e', 'ライムジュース', 25, 'ml', 1),
  ('48fb3106-817e-5aab-b677-a5cb8fd7543e', 'シュガーシロップ', 15, 'ml', 2),
  ('48fb3106-817e-5aab-b677-a5cb8fd7543e', 'アンゴスチュラビターズ', 2, 'dash', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('48fb3106-817e-5aab-b677-a5cb8fd7543e', 'シェーカーに材料と氷を入れる。', 0),
  ('48fb3106-817e-5aab-b677-a5cb8fd7543e', 'しっかりシェイクして冷やす。', 1),
  ('48fb3106-817e-5aab-b677-a5cb8fd7543e', '冷やしたグラスに注ぐ。', 2);

-- queens-park-swizzle
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '1c505846-b9f3-5bf6-a7f2-fb2a0fffdd63',
  'queens-park-swizzle',
  'クイーンズパークスウィズル',
  'Queen’s Park Swizzle',
  'ラム、ミント、ライム、ビターズをクラッシュドアイスで仕上げるトリニダードの名物。',
  'Rum',
  16,
  'Trinidad and Tobago',
  NULL,
  'none',
  ARRAY['クイーンズパーク・スウィズル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '89672ef5-203c-55dd-9cb8-3fbc926957ec',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '1c505846-b9f3-5bf6-a7f2-fb2a0fffdd63',
  'クイーンズパークスウィズル（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '89672ef5-203c-55dd-9cb8-3fbc926957ec';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '89672ef5-203c-55dd-9cb8-3fbc926957ec';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('89672ef5-203c-55dd-9cb8-3fbc926957ec', 'ダークラム', 60, 'ml', 0),
  ('89672ef5-203c-55dd-9cb8-3fbc926957ec', 'ライムジュース', 25, 'ml', 1),
  ('89672ef5-203c-55dd-9cb8-3fbc926957ec', 'シュガーシロップ', 15, 'ml', 2),
  ('89672ef5-203c-55dd-9cb8-3fbc926957ec', 'ミントの葉', 10, 'piece', 3),
  ('89672ef5-203c-55dd-9cb8-3fbc926957ec', 'アンゴスチュラビターズ', 4, 'dash', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('89672ef5-203c-55dd-9cb8-3fbc926957ec', 'グラスの中でフルーツやハーブを軽くつぶす。', 0),
  ('89672ef5-203c-55dd-9cb8-3fbc926957ec', '残りの材料と氷を加える。', 1),
  ('89672ef5-203c-55dd-9cb8-3fbc926957ec', 'よく混ぜて仕上げる。', 2);

-- queens
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '8f03957a-deb6-5436-9346-f0d0a7240bb8',
  'queens',
  'クイーンズ',
  'Queens',
  'ジンとベルモットにパイナップルを合わせる、ブロンクスの変奏として知られる一杯。',
  'Gin',
  20,
  'United States',
  NULL,
  'none',
  ARRAY['クイーンズカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '6b3cd7f4-e279-5974-afff-236835682329',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '8f03957a-deb6-5436-9346-f0d0a7240bb8',
  'クイーンズ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '6b3cd7f4-e279-5974-afff-236835682329';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '6b3cd7f4-e279-5974-afff-236835682329';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('6b3cd7f4-e279-5974-afff-236835682329', 'ドライジン', 30, 'ml', 0),
  ('6b3cd7f4-e279-5974-afff-236835682329', 'ドライベルモット', 15, 'ml', 1),
  ('6b3cd7f4-e279-5974-afff-236835682329', 'スイートベルモット', 15, 'ml', 2),
  ('6b3cd7f4-e279-5974-afff-236835682329', 'パイナップルジュース', 30, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('6b3cd7f4-e279-5974-afff-236835682329', 'シェーカーに材料と氷を入れる。', 0),
  ('6b3cd7f4-e279-5974-afff-236835682329', 'しっかりシェイクして冷やす。', 1),
  ('6b3cd7f4-e279-5974-afff-236835682329', '冷やしたグラスに注ぐ。', 2);

-- quentao
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '45690b2f-793f-50ba-b341-cb359ac2d3f1',
  'quentao',
  'クエンタォン',
  'Quentao',
  'カシャッサを生姜、砂糖、スパイスと温める、ブラジルの祝祭で飲まれるホットカクテル。',
  'Cachaca',
  13,
  'Brazil',
  NULL,
  'none',
  ARRAY['ケンタオン']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '73e222a8-d932-510a-8b0a-f86eaffcb8d4',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '45690b2f-793f-50ba-b341-cb359ac2d3f1',
  'クエンタォン（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '73e222a8-d932-510a-8b0a-f86eaffcb8d4';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '73e222a8-d932-510a-8b0a-f86eaffcb8d4';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('73e222a8-d932-510a-8b0a-f86eaffcb8d4', 'カシャッサ', 60, 'ml', 0),
  ('73e222a8-d932-510a-8b0a-f86eaffcb8d4', '水', 90, 'ml', 1),
  ('73e222a8-d932-510a-8b0a-f86eaffcb8d4', '砂糖', 1, 'tbsp', 2),
  ('73e222a8-d932-510a-8b0a-f86eaffcb8d4', '生姜', 5, 'g', 3),
  ('73e222a8-d932-510a-8b0a-f86eaffcb8d4', 'シナモン', 1, 'piece', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('73e222a8-d932-510a-8b0a-f86eaffcb8d4', '耐熱グラスに甘味やスパイスを入れる。', 0),
  ('73e222a8-d932-510a-8b0a-f86eaffcb8d4', '温めた材料を注ぐ。', 1),
  ('73e222a8-d932-510a-8b0a-f86eaffcb8d4', '軽く混ぜて温かいうちに提供する。', 2);

-- rabo-de-galo
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '8c92c369-f903-5ad6-81c0-0b9e6decddf2',
  'rabo-de-galo',
  'ラボデガロ',
  'Rabo de Galo',
  'カシャッサとベルモット、ビターリキュールを合わせる、ブラジルのクラシック。',
  'Cachaca',
  29,
  'Brazil',
  NULL,
  'none',
  ARRAY['ラボ・デ・ガロ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'fa4b1050-7d01-590a-a7f1-1a0df7198144',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '8c92c369-f903-5ad6-81c0-0b9e6decddf2',
  'ラボデガロ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'fa4b1050-7d01-590a-a7f1-1a0df7198144';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'fa4b1050-7d01-590a-a7f1-1a0df7198144';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('fa4b1050-7d01-590a-a7f1-1a0df7198144', 'カシャッサ', 45, 'ml', 0),
  ('fa4b1050-7d01-590a-a7f1-1a0df7198144', 'スイートベルモット', 25, 'ml', 1),
  ('fa4b1050-7d01-590a-a7f1-1a0df7198144', 'カンパリ', 10, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('fa4b1050-7d01-590a-a7f1-1a0df7198144', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('fa4b1050-7d01-590a-a7f1-1a0df7198144', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('fa4b1050-7d01-590a-a7f1-1a0df7198144', '冷やしたグラスに注ぐ。', 2);

-- ramos-gin-fizz
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'bed472f6-d321-5f82-a79f-4d77b73f6450',
  'ramos-gin-fizz',
  'ラモスジンフィズ',
  'Ramos Gin Fizz',
  'クリームと卵白の泡が特徴的な、ニューオーリンズ生まれの華やかなジンフィズ。',
  'Gin',
  12,
  'United States',
  NULL,
  'none',
  ARRAY['ラモス・ジン・フィズ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '1c1ef99c-b90b-55fd-8381-ba55a8e79a68',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'bed472f6-d321-5f82-a79f-4d77b73f6450',
  'ラモスジンフィズ（基本レシピ）',
  '卵白とクリームを乳化させるため、最初に氷なしで振ってから氷を入れて振る。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '1c1ef99c-b90b-55fd-8381-ba55a8e79a68';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '1c1ef99c-b90b-55fd-8381-ba55a8e79a68';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('1c1ef99c-b90b-55fd-8381-ba55a8e79a68', 'ドライジン', 45, 'ml', 0),
  ('1c1ef99c-b90b-55fd-8381-ba55a8e79a68', 'レモンジュース', 15, 'ml', 1),
  ('1c1ef99c-b90b-55fd-8381-ba55a8e79a68', 'ライムジュース', 15, 'ml', 2),
  ('1c1ef99c-b90b-55fd-8381-ba55a8e79a68', 'シュガーシロップ', 20, 'ml', 3),
  ('1c1ef99c-b90b-55fd-8381-ba55a8e79a68', '生クリーム', 30, 'ml', 4),
  ('1c1ef99c-b90b-55fd-8381-ba55a8e79a68', '卵白', 1, 'piece', 5),
  ('1c1ef99c-b90b-55fd-8381-ba55a8e79a68', 'オレンジフラワーウォーター', 3, 'drop', 6),
  ('1c1ef99c-b90b-55fd-8381-ba55a8e79a68', 'ソーダ', 60, 'ml', 7);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('1c1ef99c-b90b-55fd-8381-ba55a8e79a68', 'シェーカーに材料と氷を入れる。', 0),
  ('1c1ef99c-b90b-55fd-8381-ba55a8e79a68', 'しっかりシェイクして冷やす。', 1),
  ('1c1ef99c-b90b-55fd-8381-ba55a8e79a68', '冷やしたグラスに注ぐ。', 2);

-- ranch-water
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '2cae96f6-d2ab-5f87-a7d4-f944976581f4',
  'ranch-water',
  'ランチウォーター',
  'Ranch Water',
  'テキーラ、ライム、炭酸水だけで作る、テキサス発の軽快なハイボール。',
  'Tequila',
  9,
  'United States',
  NULL,
  'none',
  ARRAY['ランチ・ウォーター']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '60e042db-049a-561f-b495-e8dcf19374a9',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '2cae96f6-d2ab-5f87-a7d4-f944976581f4',
  'ランチウォーター（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '60e042db-049a-561f-b495-e8dcf19374a9';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '60e042db-049a-561f-b495-e8dcf19374a9';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('60e042db-049a-561f-b495-e8dcf19374a9', 'テキーラブランコ', 45, 'ml', 0),
  ('60e042db-049a-561f-b495-e8dcf19374a9', 'ライムジュース', 15, 'ml', 1),
  ('60e042db-049a-561f-b495-e8dcf19374a9', 'ソーダ', 120, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('60e042db-049a-561f-b495-e8dcf19374a9', 'グラスに氷を入れる。', 0),
  ('60e042db-049a-561f-b495-e8dcf19374a9', '材料を順に注ぐ。', 1),
  ('60e042db-049a-561f-b495-e8dcf19374a9', '軽く混ぜて仕上げる。', 2);

-- red-snapper
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '3b354bcc-e9f3-52a9-845c-fcd258da24c4',
  'red-snapper',
  'レッドスナッパー',
  'Red Snapper',
  'ブラッディメアリーをジンで作る、スパイスとトマトの食中酒向きカクテル。',
  'Gin',
  10,
  'France',
  NULL,
  'none',
  ARRAY['ジンブラッディメアリー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'fc2a9f3e-9c2f-5f7f-822c-b7b803394e46',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '3b354bcc-e9f3-52a9-845c-fcd258da24c4',
  'レッドスナッパー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'fc2a9f3e-9c2f-5f7f-822c-b7b803394e46';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'fc2a9f3e-9c2f-5f7f-822c-b7b803394e46';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('fc2a9f3e-9c2f-5f7f-822c-b7b803394e46', 'ドライジン', 45, 'ml', 0),
  ('fc2a9f3e-9c2f-5f7f-822c-b7b803394e46', 'トマトジュース', 120, 'ml', 1),
  ('fc2a9f3e-9c2f-5f7f-822c-b7b803394e46', 'レモンジュース', 10, 'ml', 2),
  ('fc2a9f3e-9c2f-5f7f-822c-b7b803394e46', 'ウスターソース', 1, 'tsp', 3),
  ('fc2a9f3e-9c2f-5f7f-822c-b7b803394e46', 'ホットソース', 2, 'dash', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('fc2a9f3e-9c2f-5f7f-822c-b7b803394e46', 'グラスに氷を入れる。', 0),
  ('fc2a9f3e-9c2f-5f7f-822c-b7b803394e46', '材料を順に注ぐ。', 1),
  ('fc2a9f3e-9c2f-5f7f-822c-b7b803394e46', '軽く混ぜて仕上げる。', 2);

-- rob-roy
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b0174d03-eb0c-5646-9ed1-0a3f8cf6c393',
  'rob-roy',
  'ロブロイ',
  'Rob Roy',
  'マンハッタンをスコッチで作る、香ばしくなめらかなクラシック。',
  'Whisky',
  30,
  'United States',
  NULL,
  'none',
  ARRAY['ロブ・ロイ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '51f07b33-227d-503b-8c6f-b7f2e8d4eb4b',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b0174d03-eb0c-5646-9ed1-0a3f8cf6c393',
  'ロブロイ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '51f07b33-227d-503b-8c6f-b7f2e8d4eb4b';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '51f07b33-227d-503b-8c6f-b7f2e8d4eb4b';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('51f07b33-227d-503b-8c6f-b7f2e8d4eb4b', 'スコッチウイスキー', 50, 'ml', 0),
  ('51f07b33-227d-503b-8c6f-b7f2e8d4eb4b', 'スイートベルモット', 25, 'ml', 1),
  ('51f07b33-227d-503b-8c6f-b7f2e8d4eb4b', 'アンゴスチュラビターズ', 2, 'dash', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('51f07b33-227d-503b-8c6f-b7f2e8d4eb4b', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('51f07b33-227d-503b-8c6f-b7f2e8d4eb4b', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('51f07b33-227d-503b-8c6f-b7f2e8d4eb4b', '冷やしたグラスに注ぐ。', 2);

-- rosita
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '4ec924a7-3793-5260-b267-fa54c31876b6',
  'rosita',
  'ロジータ',
  'Rosita',
  'テキーラ、ベルモット、カンパリをステアする、ビターで複雑なクラシック。',
  'Tequila',
  26,
  'Mexico',
  NULL,
  'none',
  ARRAY['ロシータ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '05a87db4-5929-53ba-9257-f2a75ab5c4a2',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '4ec924a7-3793-5260-b267-fa54c31876b6',
  'ロジータ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '05a87db4-5929-53ba-9257-f2a75ab5c4a2';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '05a87db4-5929-53ba-9257-f2a75ab5c4a2';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('05a87db4-5929-53ba-9257-f2a75ab5c4a2', 'テキーラレポサド', 45, 'ml', 0),
  ('05a87db4-5929-53ba-9257-f2a75ab5c4a2', 'カンパリ', 15, 'ml', 1),
  ('05a87db4-5929-53ba-9257-f2a75ab5c4a2', 'ドライベルモット', 15, 'ml', 2),
  ('05a87db4-5929-53ba-9257-f2a75ab5c4a2', 'スイートベルモット', 15, 'ml', 3),
  ('05a87db4-5929-53ba-9257-f2a75ab5c4a2', 'アンゴスチュラビターズ', 1, 'dash', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('05a87db4-5929-53ba-9257-f2a75ab5c4a2', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('05a87db4-5929-53ba-9257-f2a75ab5c4a2', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('05a87db4-5929-53ba-9257-f2a75ab5c4a2', '冷やしたグラスに注ぐ。', 2);

-- rum-old-fashioned
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'c612ae46-c801-5a65-85f2-35b50aad08f4',
  'rum-old-fashioned',
  'ラムオールドファッションド',
  'Rum Old Fashioned',
  '熟成ラムを砂糖とビターズで引き立てる、オールドファッションドのラム版。',
  'Rum',
  32,
  'United States',
  NULL,
  'none',
  ARRAY['ラム・オールドファッションド']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'fe13c2f4-3f7d-5c85-b5ea-b4ce5937d247',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'c612ae46-c801-5a65-85f2-35b50aad08f4',
  'ラムオールドファッションド（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'fe13c2f4-3f7d-5c85-b5ea-b4ce5937d247';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'fe13c2f4-3f7d-5c85-b5ea-b4ce5937d247';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('fe13c2f4-3f7d-5c85-b5ea-b4ce5937d247', 'ダークラム', 60, 'ml', 0),
  ('fe13c2f4-3f7d-5c85-b5ea-b4ce5937d247', 'デメララシロップ', 1, 'tsp', 1),
  ('fe13c2f4-3f7d-5c85-b5ea-b4ce5937d247', 'アンゴスチュラビターズ', 2, 'dash', 2),
  ('fe13c2f4-3f7d-5c85-b5ea-b4ce5937d247', 'オレンジビターズ', 1, 'dash', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('fe13c2f4-3f7d-5c85-b5ea-b4ce5937d247', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('fe13c2f4-3f7d-5c85-b5ea-b4ce5937d247', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('fe13c2f4-3f7d-5c85-b5ea-b4ce5937d247', '冷やしたグラスに注ぐ。', 2);

-- rum-runner
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '74c8c901-ca33-5632-938b-8db29853e385',
  'rum-runner',
  'ラムランナー',
  'Rum Runner',
  'ラムにバナナとブラックベリー、果汁を合わせるフロリダ発のトロピカルカクテル。',
  'Rum',
  17,
  'United States',
  NULL,
  'none',
  ARRAY['ラム・ランナー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '323dec78-56dd-52bd-b2e7-c68ff3272286',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '74c8c901-ca33-5632-938b-8db29853e385',
  'ラムランナー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '323dec78-56dd-52bd-b2e7-c68ff3272286';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '323dec78-56dd-52bd-b2e7-c68ff3272286';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('323dec78-56dd-52bd-b2e7-c68ff3272286', 'ライトラム', 30, 'ml', 0),
  ('323dec78-56dd-52bd-b2e7-c68ff3272286', 'ダークラム', 30, 'ml', 1),
  ('323dec78-56dd-52bd-b2e7-c68ff3272286', 'バナナリキュール', 15, 'ml', 2),
  ('323dec78-56dd-52bd-b2e7-c68ff3272286', 'ブラックベリーリキュール', 15, 'ml', 3),
  ('323dec78-56dd-52bd-b2e7-c68ff3272286', 'パイナップルジュース', 45, 'ml', 4),
  ('323dec78-56dd-52bd-b2e7-c68ff3272286', 'ライムジュース', 15, 'ml', 5);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('323dec78-56dd-52bd-b2e7-c68ff3272286', 'シェーカーに材料と氷を入れる。', 0),
  ('323dec78-56dd-52bd-b2e7-c68ff3272286', 'しっかりシェイクして冷やす。', 1),
  ('323dec78-56dd-52bd-b2e7-c68ff3272286', '冷やしたグラスに注ぐ。', 2);

-- rusty-nail
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'bcd6f034-e153-5259-8e21-a4c49b3bae38',
  'rusty-nail',
  'ラスティネイル',
  'Rusty Nail',
  'スコッチとドランブイを合わせる、甘くハーブ香のある食後向きの一杯。',
  'Whisky',
  34,
  'United States',
  NULL,
  'none',
  ARRAY['ラスティ・ネイル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'ebf774f9-1b77-5385-b767-e2dab03ae964',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'bcd6f034-e153-5259-8e21-a4c49b3bae38',
  'ラスティネイル（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'ebf774f9-1b77-5385-b767-e2dab03ae964';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'ebf774f9-1b77-5385-b767-e2dab03ae964';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('ebf774f9-1b77-5385-b767-e2dab03ae964', 'スコッチウイスキー', 45, 'ml', 0),
  ('ebf774f9-1b77-5385-b767-e2dab03ae964', 'ドランブイ', 25, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('ebf774f9-1b77-5385-b767-e2dab03ae964', 'グラスに氷を入れる。', 0),
  ('ebf774f9-1b77-5385-b767-e2dab03ae964', '材料を順に注ぐ。', 1),
  ('ebf774f9-1b77-5385-b767-e2dab03ae964', '軽く混ぜて仕上げる。', 2);

-- ryokucha-hai
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'a91dd871-c0cb-561a-a24d-d64988e5fd72',
  'ryokucha-hai',
  '緑茶ハイ',
  'Ryokucha Hai',
  '焼酎を緑茶で割る、茶の渋みと香りを楽しむ日本の定番サワー。',
  'Shochu',
  7,
  'Japan',
  NULL,
  'none',
  ARRAY['緑茶割り']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '502e6c9b-5390-5cb3-b730-580d1055bd2c',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'a91dd871-c0cb-561a-a24d-d64988e5fd72',
  '緑茶ハイ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '502e6c9b-5390-5cb3-b730-580d1055bd2c';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '502e6c9b-5390-5cb3-b730-580d1055bd2c';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('502e6c9b-5390-5cb3-b730-580d1055bd2c', '焼酎', 45, 'ml', 0),
  ('502e6c9b-5390-5cb3-b730-580d1055bd2c', '緑茶', 135, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('502e6c9b-5390-5cb3-b730-580d1055bd2c', 'グラスに氷を入れる。', 0),
  ('502e6c9b-5390-5cb3-b730-580d1055bd2c', '材料を順に注ぐ。', 1),
  ('502e6c9b-5390-5cb3-b730-580d1055bd2c', '軽く混ぜて仕上げる。', 2);

-- salty-dog
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'a1b832b5-738c-5384-8d14-90498ee82c26',
  'salty-dog',
  'ソルティドッグ',
  'Salty Dog',
  'グレイハウンドに塩のスノースタイルを加えた、日本でも定番のウォッカカクテル。',
  'Vodka',
  10,
  'United States',
  NULL,
  'none',
  ARRAY['ソルティ・ドッグ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '5604cbb2-a782-5fd3-b8bc-1739446971b4',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'a1b832b5-738c-5384-8d14-90498ee82c26',
  'ソルティドッグ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '5604cbb2-a782-5fd3-b8bc-1739446971b4';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '5604cbb2-a782-5fd3-b8bc-1739446971b4';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('5604cbb2-a782-5fd3-b8bc-1739446971b4', 'ウォッカ', 45, 'ml', 0),
  ('5604cbb2-a782-5fd3-b8bc-1739446971b4', 'グレープフルーツジュース', 135, 'ml', 1),
  ('5604cbb2-a782-5fd3-b8bc-1739446971b4', '塩', 1, 'tsp', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('5604cbb2-a782-5fd3-b8bc-1739446971b4', 'グラスに氷を入れる。', 0),
  ('5604cbb2-a782-5fd3-b8bc-1739446971b4', '材料を順に注ぐ。', 1),
  ('5604cbb2-a782-5fd3-b8bc-1739446971b4', '軽く混ぜて仕上げる。', 2);

-- satans-whiskers
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'f1b84335-ef6b-5b34-a14f-0de5aff2aea5',
  'satans-whiskers',
  'サタンズウィスカーズ',
  'Satan''s Whiskers',
  'ジン、ベルモット、オレンジを重ねる、名前に反して上品なクラシック。',
  'Gin',
  21,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['サタンのひげ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '6f60d898-4525-50ec-8a6b-0c3dce9f8ff5',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'f1b84335-ef6b-5b34-a14f-0de5aff2aea5',
  'サタンズウィスカーズ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '6f60d898-4525-50ec-8a6b-0c3dce9f8ff5';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '6f60d898-4525-50ec-8a6b-0c3dce9f8ff5';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('6f60d898-4525-50ec-8a6b-0c3dce9f8ff5', 'ドライジン', 20, 'ml', 0),
  ('6f60d898-4525-50ec-8a6b-0c3dce9f8ff5', 'ドライベルモット', 20, 'ml', 1),
  ('6f60d898-4525-50ec-8a6b-0c3dce9f8ff5', 'スイートベルモット', 20, 'ml', 2),
  ('6f60d898-4525-50ec-8a6b-0c3dce9f8ff5', 'オレンジジュース', 20, 'ml', 3),
  ('6f60d898-4525-50ec-8a6b-0c3dce9f8ff5', 'グランマルニエ', 10, 'ml', 4),
  ('6f60d898-4525-50ec-8a6b-0c3dce9f8ff5', 'オレンジビターズ', 1, 'dash', 5);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('6f60d898-4525-50ec-8a6b-0c3dce9f8ff5', 'シェーカーに材料と氷を入れる。', 0),
  ('6f60d898-4525-50ec-8a6b-0c3dce9f8ff5', 'しっかりシェイクして冷やす。', 1),
  ('6f60d898-4525-50ec-8a6b-0c3dce9f8ff5', '冷やしたグラスに注ぐ。', 2);

-- sazerac
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '89a2784e-cc79-50c9-b25c-a322460340c7',
  'sazerac',
  'サゼラック',
  'Sazerac',
  'ライウイスキーにペイショーズビターズとアブサンの香りをまとわせるニューオーリンズの象徴。',
  'Whisky',
  36,
  'United States',
  NULL,
  'none',
  ARRAY['サゼラックカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '6e2ecee0-9491-5ef6-b06c-40af62a7de3a',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '89a2784e-cc79-50c9-b25c-a322460340c7',
  'サゼラック（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '6e2ecee0-9491-5ef6-b06c-40af62a7de3a';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '6e2ecee0-9491-5ef6-b06c-40af62a7de3a';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('6e2ecee0-9491-5ef6-b06c-40af62a7de3a', 'ライウイスキー', 60, 'ml', 0),
  ('6e2ecee0-9491-5ef6-b06c-40af62a7de3a', '角砂糖', 1, 'piece', 1),
  ('6e2ecee0-9491-5ef6-b06c-40af62a7de3a', 'ペイショーズビターズ', 3, 'dash', 2),
  ('6e2ecee0-9491-5ef6-b06c-40af62a7de3a', 'アブサン', 1, 'tsp', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('6e2ecee0-9491-5ef6-b06c-40af62a7de3a', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('6e2ecee0-9491-5ef6-b06c-40af62a7de3a', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('6e2ecee0-9491-5ef6-b06c-40af62a7de3a', '冷やしたグラスに注ぐ。', 2);

-- scofflaw
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '9c5247ec-f167-5873-bccc-8a783483da7f',
  'scofflaw',
  'スコッフロー',
  'Scofflaw',
  'ライウイスキー、ベルモット、レモン、グレナデンを合わせる禁酒法時代の一杯。',
  'Whisky',
  24,
  'France',
  NULL,
  'none',
  ARRAY['スコッフロウ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '72bfde7a-148c-5367-822f-d3a829f2af5b',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '9c5247ec-f167-5873-bccc-8a783483da7f',
  'スコッフロー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '72bfde7a-148c-5367-822f-d3a829f2af5b';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '72bfde7a-148c-5367-822f-d3a829f2af5b';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('72bfde7a-148c-5367-822f-d3a829f2af5b', 'ライウイスキー', 45, 'ml', 0),
  ('72bfde7a-148c-5367-822f-d3a829f2af5b', 'ドライベルモット', 30, 'ml', 1),
  ('72bfde7a-148c-5367-822f-d3a829f2af5b', 'レモンジュース', 20, 'ml', 2),
  ('72bfde7a-148c-5367-822f-d3a829f2af5b', 'グレナデンシロップ', 10, 'ml', 3),
  ('72bfde7a-148c-5367-822f-d3a829f2af5b', 'オレンジビターズ', 1, 'dash', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('72bfde7a-148c-5367-822f-d3a829f2af5b', 'シェーカーに材料と氷を入れる。', 0),
  ('72bfde7a-148c-5367-822f-d3a829f2af5b', 'しっかりシェイクして冷やす。', 1),
  ('72bfde7a-148c-5367-822f-d3a829f2af5b', '冷やしたグラスに注ぐ。', 2);

-- screwdriver
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '55ccfcc7-1ffe-5cce-8137-0d38a55b6d2f',
  'screwdriver',
  'スクリュードライバー',
  'Screwdriver',
  'ウォッカをオレンジジュースで割る、世界的に親しまれるシンプルなロングカクテル。',
  'Vodka',
  10,
  'United States',
  NULL,
  'none',
  ARRAY['ウォッカオレンジ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '332cb843-9aac-54f0-8ded-a4e383ff1013',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '55ccfcc7-1ffe-5cce-8137-0d38a55b6d2f',
  'スクリュードライバー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '332cb843-9aac-54f0-8ded-a4e383ff1013';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '332cb843-9aac-54f0-8ded-a4e383ff1013';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('332cb843-9aac-54f0-8ded-a4e383ff1013', 'ウォッカ', 45, 'ml', 0),
  ('332cb843-9aac-54f0-8ded-a4e383ff1013', 'オレンジジュース', 135, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('332cb843-9aac-54f0-8ded-a4e383ff1013', 'グラスに氷を入れる。', 0),
  ('332cb843-9aac-54f0-8ded-a4e383ff1013', '材料を順に注ぐ。', 1),
  ('332cb843-9aac-54f0-8ded-a4e383ff1013', '軽く混ぜて仕上げる。', 2);

-- sea-breeze
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '3ceef3e9-4647-5440-983d-d58f37cec69f',
  'sea-breeze',
  'シーブリーズ',
  'Sea Breeze',
  'ウォッカ、クランベリー、グレープフルーツで作る爽やかなフルーツカクテル。',
  'Vodka',
  9,
  'United States',
  NULL,
  'none',
  ARRAY['シー・ブリーズ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'b38d991d-63ae-5c54-847f-fbdaaef16eb3',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '3ceef3e9-4647-5440-983d-d58f37cec69f',
  'シーブリーズ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'b38d991d-63ae-5c54-847f-fbdaaef16eb3';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'b38d991d-63ae-5c54-847f-fbdaaef16eb3';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('b38d991d-63ae-5c54-847f-fbdaaef16eb3', 'ウォッカ', 45, 'ml', 0),
  ('b38d991d-63ae-5c54-847f-fbdaaef16eb3', 'クランベリージュース', 90, 'ml', 1),
  ('b38d991d-63ae-5c54-847f-fbdaaef16eb3', 'グレープフルーツジュース', 45, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('b38d991d-63ae-5c54-847f-fbdaaef16eb3', 'グラスに氷を入れる。', 0),
  ('b38d991d-63ae-5c54-847f-fbdaaef16eb3', '材料を順に注ぐ。', 1),
  ('b38d991d-63ae-5c54-847f-fbdaaef16eb3', '軽く混ぜて仕上げる。', 2);

-- seven-and-seven
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'a628e968-dd30-5a9a-a2fa-5bbdba9e0bd9',
  'seven-and-seven',
  'セブンアンドセブン',
  'Seven and Seven',
  'アメリカンウイスキーをレモンライムソーダで割る、軽快なハイボール。',
  'Whisky',
  9,
  'United States',
  NULL,
  'none',
  ARRAY['7 and 7']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'ff8c570d-ea6b-53be-a2f5-1f8220937b59',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'a628e968-dd30-5a9a-a2fa-5bbdba9e0bd9',
  'セブンアンドセブン（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'ff8c570d-ea6b-53be-a2f5-1f8220937b59';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'ff8c570d-ea6b-53be-a2f5-1f8220937b59';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('ff8c570d-ea6b-53be-a2f5-1f8220937b59', 'アメリカンウイスキー', 45, 'ml', 0),
  ('ff8c570d-ea6b-53be-a2f5-1f8220937b59', 'レモンライムソーダ', 135, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('ff8c570d-ea6b-53be-a2f5-1f8220937b59', 'グラスに氷を入れる。', 0),
  ('ff8c570d-ea6b-53be-a2f5-1f8220937b59', '材料を順に注ぐ。', 1),
  ('ff8c570d-ea6b-53be-a2f5-1f8220937b59', '軽く混ぜて仕上げる。', 2);

-- sex-on-the-beach
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '1fdfa351-fe18-5f4a-a640-c99f52428d6f',
  'sex-on-the-beach',
  'セックスオンザビーチ',
  'Sex on the Beach',
  'ウォッカ、ピーチ、クランベリー、オレンジを合わせる華やかなフルーツカクテル。',
  'Vodka',
  11,
  'United States',
  NULL,
  'none',
  ARRAY['セックス・オン・ザ・ビーチ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '35331b3f-14a0-52bc-ba36-85adca195195',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '1fdfa351-fe18-5f4a-a640-c99f52428d6f',
  'セックスオンザビーチ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '35331b3f-14a0-52bc-ba36-85adca195195';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '35331b3f-14a0-52bc-ba36-85adca195195';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('35331b3f-14a0-52bc-ba36-85adca195195', 'ウォッカ', 40, 'ml', 0),
  ('35331b3f-14a0-52bc-ba36-85adca195195', 'ピーチリキュール', 20, 'ml', 1),
  ('35331b3f-14a0-52bc-ba36-85adca195195', 'クランベリージュース', 40, 'ml', 2),
  ('35331b3f-14a0-52bc-ba36-85adca195195', 'オレンジジュース', 40, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('35331b3f-14a0-52bc-ba36-85adca195195', 'グラスに氷を入れる。', 0),
  ('35331b3f-14a0-52bc-ba36-85adca195195', '材料を順に注ぐ。', 1),
  ('35331b3f-14a0-52bc-ba36-85adca195195', '軽く混ぜて仕上げる。', 2);

-- shochu-mizuwari
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b64cd34c-fa64-53ea-b15a-b85dedf9ec7c',
  'shochu-mizuwari',
  '焼酎水割り',
  'Shochu Mizuwari',
  '焼酎を冷水で割り、香味を穏やかに楽しむ基本の飲み方。',
  'Shochu',
  12,
  'Japan',
  NULL,
  'none',
  ARRAY['水割り焼酎']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '37965552-bf96-5a06-8601-d2399822e17d',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b64cd34c-fa64-53ea-b15a-b85dedf9ec7c',
  '焼酎水割り（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '37965552-bf96-5a06-8601-d2399822e17d';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '37965552-bf96-5a06-8601-d2399822e17d';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('37965552-bf96-5a06-8601-d2399822e17d', '焼酎', 60, 'ml', 0),
  ('37965552-bf96-5a06-8601-d2399822e17d', '冷水', 90, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('37965552-bf96-5a06-8601-d2399822e17d', 'グラスに氷を入れる。', 0),
  ('37965552-bf96-5a06-8601-d2399822e17d', '材料を順に注ぐ。', 1),
  ('37965552-bf96-5a06-8601-d2399822e17d', '軽く混ぜて仕上げる。', 2);

-- shochu-oyuwari
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '16854665-3a81-5172-9a93-ce86ca0b5f77',
  'shochu-oyuwari',
  '焼酎お湯割り',
  'Shochu Oyuwari',
  '焼酎を湯で割り、芋や麦の香りを立たせる日本の定番スタイル。',
  'Shochu',
  12,
  'Japan',
  NULL,
  'none',
  ARRAY['お湯割り焼酎']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'cfaef2b9-ea60-5333-84cb-0d42d5639543',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '16854665-3a81-5172-9a93-ce86ca0b5f77',
  '焼酎お湯割り（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'cfaef2b9-ea60-5333-84cb-0d42d5639543';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'cfaef2b9-ea60-5333-84cb-0d42d5639543';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('cfaef2b9-ea60-5333-84cb-0d42d5639543', '焼酎', 60, 'ml', 0),
  ('cfaef2b9-ea60-5333-84cb-0d42d5639543', 'お湯', 90, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('cfaef2b9-ea60-5333-84cb-0d42d5639543', '耐熱グラスに甘味やスパイスを入れる。', 0),
  ('cfaef2b9-ea60-5333-84cb-0d42d5639543', '温めた材料を注ぐ。', 1),
  ('cfaef2b9-ea60-5333-84cb-0d42d5639543', '軽く混ぜて温かいうちに提供する。', 2);

-- shochu-rocks
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'afe06a18-28c3-5b58-8acd-9f858a37624b',
  'shochu-rocks',
  '焼酎ロック',
  'Shochu on the Rocks',
  '氷で冷やしながら焼酎の香味変化を楽しむ、最もシンプルな提供スタイル。',
  'Shochu',
  20,
  'Japan',
  NULL,
  'none',
  ARRAY['焼酎オンザロック']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '89dc68ce-5ac5-5f9b-be9d-4c1672ee345b',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'afe06a18-28c3-5b58-8acd-9f858a37624b',
  '焼酎ロック（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '89dc68ce-5ac5-5f9b-be9d-4c1672ee345b';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '89dc68ce-5ac5-5f9b-be9d-4c1672ee345b';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('89dc68ce-5ac5-5f9b-be9d-4c1672ee345b', '焼酎', 60, 'ml', 0),
  ('89dc68ce-5ac5-5f9b-be9d-4c1672ee345b', '氷', 1, 'piece', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('89dc68ce-5ac5-5f9b-be9d-4c1672ee345b', 'グラスに氷を入れる。', 0),
  ('89dc68ce-5ac5-5f9b-be9d-4c1672ee345b', '材料を順に注ぐ。', 1),
  ('89dc68ce-5ac5-5f9b-be9d-4c1672ee345b', '軽く混ぜて仕上げる。', 2);

-- shochu-soda
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '7facbb99-1786-514f-9a99-19b94c571842',
  'shochu-soda',
  '焼酎ソーダ割り',
  'Shochu Soda',
  '焼酎を炭酸で割り、香りを軽やかに広げるすっきりしたハイボール。',
  'Shochu',
  8,
  'Japan',
  NULL,
  'none',
  ARRAY['焼酎ハイボール']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '5cb0cba7-f9bc-5e87-a927-c970ddc73e2d',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '7facbb99-1786-514f-9a99-19b94c571842',
  '焼酎ソーダ割り（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '5cb0cba7-f9bc-5e87-a927-c970ddc73e2d';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '5cb0cba7-f9bc-5e87-a927-c970ddc73e2d';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('5cb0cba7-f9bc-5e87-a927-c970ddc73e2d', '焼酎', 45, 'ml', 0),
  ('5cb0cba7-f9bc-5e87-a927-c970ddc73e2d', 'ソーダ', 135, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('5cb0cba7-f9bc-5e87-a927-c970ddc73e2d', 'グラスに氷を入れる。', 0),
  ('5cb0cba7-f9bc-5e87-a927-c970ddc73e2d', '材料を順に注ぐ。', 1),
  ('5cb0cba7-f9bc-5e87-a927-c970ddc73e2d', '軽く混ぜて仕上げる。', 2);

-- sidecar
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b04b065e-7d24-5558-88ff-87771b4a40f3',
  'sidecar',
  'サイドカー',
  'Sidecar',
  'コニャック、オレンジリキュール、レモン果汁をシェイクしたエレガントなサワー系クラシック。',
  'Brandy',
  25,
  'France',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '87e3ef28-e7c5-573d-9143-986f99895f1e',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b04b065e-7d24-5558-88ff-87771b4a40f3',
  'サイドカー（基本レシピ）',
  '好みでグラスの縁にシュガーリムを付けてもよい。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '87e3ef28-e7c5-573d-9143-986f99895f1e';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '87e3ef28-e7c5-573d-9143-986f99895f1e';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('87e3ef28-e7c5-573d-9143-986f99895f1e', 'コニャック', 45, 'ml', 0),
  ('87e3ef28-e7c5-573d-9143-986f99895f1e', 'ホワイトキュラソー', 20, 'ml', 1),
  ('87e3ef28-e7c5-573d-9143-986f99895f1e', 'レモン果汁', 20, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('87e3ef28-e7c5-573d-9143-986f99895f1e', 'シェイカーに材料と氷を入れる。', 0),
  ('87e3ef28-e7c5-573d-9143-986f99895f1e', 'よくシェイクする。', 1),
  ('87e3ef28-e7c5-573d-9143-986f99895f1e', 'クーペグラスに注ぐ。', 2);

-- siesta
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'f4ae111e-5b96-50e2-b99a-06ac4142a7ae',
  'siesta',
  'シエスタ',
  'Siesta',
  'テキーラ、カンパリ、グレープフルーツ、ライムを合わせるモダンクラシック。',
  'Tequila',
  19,
  'United States',
  NULL,
  'none',
  ARRAY['シエスタカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '5c8ae15e-bc2b-5f81-bf2d-73442222b51e',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'f4ae111e-5b96-50e2-b99a-06ac4142a7ae',
  'シエスタ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '5c8ae15e-bc2b-5f81-bf2d-73442222b51e';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '5c8ae15e-bc2b-5f81-bf2d-73442222b51e';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('5c8ae15e-bc2b-5f81-bf2d-73442222b51e', 'テキーラブランコ', 45, 'ml', 0),
  ('5c8ae15e-bc2b-5f81-bf2d-73442222b51e', 'カンパリ', 15, 'ml', 1),
  ('5c8ae15e-bc2b-5f81-bf2d-73442222b51e', 'グレープフルーツジュース', 15, 'ml', 2),
  ('5c8ae15e-bc2b-5f81-bf2d-73442222b51e', 'ライムジュース', 15, 'ml', 3),
  ('5c8ae15e-bc2b-5f81-bf2d-73442222b51e', 'シュガーシロップ', 10, 'ml', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('5c8ae15e-bc2b-5f81-bf2d-73442222b51e', 'シェーカーに材料と氷を入れる。', 0),
  ('5c8ae15e-bc2b-5f81-bf2d-73442222b51e', 'しっかりシェイクして冷やす。', 1),
  ('5c8ae15e-bc2b-5f81-bf2d-73442222b51e', '冷やしたグラスに注ぐ。', 2);

-- singapore-sling
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '0c8d9c8e-86cc-5853-b55e-2e8c7cfef6c0',
  'singapore-sling',
  'シンガポールスリング',
  'Singapore Sling',
  'ジンをベースにリキュールと果汁を重ねた華やかなロングドリンク。ラッフルズホテル発祥。',
  'Gin',
  15,
  'Singapore',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '0c8d9c8e-86cc-5853-b55e-2e8c7cfef6c0',
  'シンガポールスリング（基本レシピ）',
  NULL,
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec', 'ドライジン', 30, 'ml', 0),
  ('0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec', 'チェリーブランデー', 15, 'ml', 1),
  ('0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec', 'コアントロー', 7.5, 'ml', 2),
  ('0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec', 'ベネディクティン', 7.5, 'ml', 3),
  ('0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec', 'パイナップルジュース', 120, 'ml', 4),
  ('0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec', 'ライム果汁', 15, 'ml', 5),
  ('0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec', 'グレナデン', 10, 'ml', 6),
  ('0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec', 'アンゴスチュラビターズ', 1, 'dash', 7);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec', 'シェイカーに材料と氷を入れる。', 0),
  ('0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec', 'よくシェイクする。', 1),
  ('0fcd8bf6-18fe-5a98-84ab-8005d18ef6ec', '氷入りのハイボールグラスに注ぎ、飾りを添える。', 2);

-- southside
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b9a8fbc1-197a-5fa1-950e-21caea539c98',
  'southside',
  'サウスサイド',
  'Southside',
  'ジンにミントとライムを合わせた、爽快な禁酒法時代の名作。',
  'Gin',
  22,
  'United States',
  NULL,
  'none',
  ARRAY['サウス・サイド']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'fb097054-80d5-5a6e-bea5-5631cd9a70e0',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b9a8fbc1-197a-5fa1-950e-21caea539c98',
  'サウスサイド（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'fb097054-80d5-5a6e-bea5-5631cd9a70e0';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'fb097054-80d5-5a6e-bea5-5631cd9a70e0';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('fb097054-80d5-5a6e-bea5-5631cd9a70e0', 'ドライジン', 45, 'ml', 0),
  ('fb097054-80d5-5a6e-bea5-5631cd9a70e0', 'ライムジュース', 20, 'ml', 1),
  ('fb097054-80d5-5a6e-bea5-5631cd9a70e0', 'シュガーシロップ', 15, 'ml', 2),
  ('fb097054-80d5-5a6e-bea5-5631cd9a70e0', 'ミントの葉', 8, 'piece', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('fb097054-80d5-5a6e-bea5-5631cd9a70e0', 'シェーカーに材料と氷を入れる。', 0),
  ('fb097054-80d5-5a6e-bea5-5631cd9a70e0', 'しっかりシェイクして冷やす。', 1),
  ('fb097054-80d5-5a6e-bea5-5631cd9a70e0', '冷やしたグラスに注ぐ。', 2);

-- spumoni
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '32caf4e4-0e0f-5419-b02f-66d8ae2fbb40',
  'spumoni',
  'スプモーニ',
  'Spumoni',
  'カンパリ、グレープフルーツ、トニックを合わせる、日本でも人気のビターなロングカクテル。',
  'Liqueur',
  6,
  'Italy',
  NULL,
  'none',
  ARRAY['スプモニ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '941b7650-c951-5012-98f6-2e2407df0c37',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '32caf4e4-0e0f-5419-b02f-66d8ae2fbb40',
  'スプモーニ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '941b7650-c951-5012-98f6-2e2407df0c37';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '941b7650-c951-5012-98f6-2e2407df0c37';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('941b7650-c951-5012-98f6-2e2407df0c37', 'カンパリ', 30, 'ml', 0),
  ('941b7650-c951-5012-98f6-2e2407df0c37', 'グレープフルーツジュース', 45, 'ml', 1),
  ('941b7650-c951-5012-98f6-2e2407df0c37', 'トニックウォーター', 90, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('941b7650-c951-5012-98f6-2e2407df0c37', 'グラスに氷を入れる。', 0),
  ('941b7650-c951-5012-98f6-2e2407df0c37', '材料を順に注ぐ。', 1),
  ('941b7650-c951-5012-98f6-2e2407df0c37', '軽く混ぜて仕上げる。', 2);

-- stinger
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'f35fc71e-ee1c-5278-aae4-72852619bf06',
  'stinger',
  'スティンガー',
  'Stinger',
  'ブランデーとホワイトミントリキュールを合わせる、清涼感のある食後酒。',
  'Brandy',
  29,
  'United States',
  NULL,
  'none',
  ARRAY['スティンガーカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '9d6fe090-c81d-53ca-93a4-5a5ebd821480',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'f35fc71e-ee1c-5278-aae4-72852619bf06',
  'スティンガー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '9d6fe090-c81d-53ca-93a4-5a5ebd821480';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '9d6fe090-c81d-53ca-93a4-5a5ebd821480';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('9d6fe090-c81d-53ca-93a4-5a5ebd821480', 'ブランデー', 50, 'ml', 0),
  ('9d6fe090-c81d-53ca-93a4-5a5ebd821480', 'ホワイトミントリキュール', 20, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('9d6fe090-c81d-53ca-93a4-5a5ebd821480', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('9d6fe090-c81d-53ca-93a4-5a5ebd821480', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('9d6fe090-c81d-53ca-93a4-5a5ebd821480', '冷やしたグラスに注ぐ。', 2);

-- tequila-sour
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '9fbb5f9f-ee98-59eb-9a7e-e4333d0e8be6',
  'tequila-sour',
  'テキーラサワー',
  'Tequila Sour',
  'テキーラにレモンと甘味、卵白を合わせる、なめらかなサワースタイル。',
  'Tequila',
  20,
  'Mexico',
  NULL,
  'none',
  ARRAY['テキーラ・サワー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '2b6fd4e2-6470-5870-9c1f-db842b665a49',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '9fbb5f9f-ee98-59eb-9a7e-e4333d0e8be6',
  'テキーラサワー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '2b6fd4e2-6470-5870-9c1f-db842b665a49';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '2b6fd4e2-6470-5870-9c1f-db842b665a49';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('2b6fd4e2-6470-5870-9c1f-db842b665a49', 'テキーラブランコ', 45, 'ml', 0),
  ('2b6fd4e2-6470-5870-9c1f-db842b665a49', 'レモンジュース', 20, 'ml', 1),
  ('2b6fd4e2-6470-5870-9c1f-db842b665a49', 'シュガーシロップ', 15, 'ml', 2),
  ('2b6fd4e2-6470-5870-9c1f-db842b665a49', '卵白', 1, 'piece', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('2b6fd4e2-6470-5870-9c1f-db842b665a49', 'シェーカーに材料と氷を入れる。', 0),
  ('2b6fd4e2-6470-5870-9c1f-db842b665a49', 'しっかりシェイクして冷やす。', 1),
  ('2b6fd4e2-6470-5870-9c1f-db842b665a49', '冷やしたグラスに注ぐ。', 2);

-- tequila-sunrise
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '6fe4f47d-db84-5adc-868b-51566789a124',
  'tequila-sunrise',
  'テキーラサンライズ',
  'Tequila Sunrise',
  'テキーラとオレンジにグレナデンを沈める、朝焼けの色で知られる定番。',
  'Tequila',
  11,
  'United States',
  NULL,
  'none',
  ARRAY['テキーラ・サンライズ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'c2fe1f08-1977-5be0-a8ad-84cccc4faf86',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '6fe4f47d-db84-5adc-868b-51566789a124',
  'テキーラサンライズ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'c2fe1f08-1977-5be0-a8ad-84cccc4faf86';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'c2fe1f08-1977-5be0-a8ad-84cccc4faf86';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('c2fe1f08-1977-5be0-a8ad-84cccc4faf86', 'テキーラブランコ', 45, 'ml', 0),
  ('c2fe1f08-1977-5be0-a8ad-84cccc4faf86', 'オレンジジュース', 120, 'ml', 1),
  ('c2fe1f08-1977-5be0-a8ad-84cccc4faf86', 'グレナデンシロップ', 15, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('c2fe1f08-1977-5be0-a8ad-84cccc4faf86', 'グラスに氷を入れる。', 0),
  ('c2fe1f08-1977-5be0-a8ad-84cccc4faf86', '材料を順に注ぐ。', 1),
  ('c2fe1f08-1977-5be0-a8ad-84cccc4faf86', '軽く混ぜて仕上げる。', 2);

-- ti-punch
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b901fe27-971a-5df2-8db7-b54354e5a30b',
  'ti-punch',
  'ティパンチ',
  'Ti’ Punch',
  'ラム・アグリコール、ライム、砂糖で作る仏領カリブのミニマルな一杯。',
  'Rum',
  33,
  'Martinique',
  NULL,
  'none',
  ARRAY['ティ・パンチ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '7446ee96-5dc9-55a9-9c6a-b1b1baf8b9a7',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b901fe27-971a-5df2-8db7-b54354e5a30b',
  'ティパンチ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '7446ee96-5dc9-55a9-9c6a-b1b1baf8b9a7';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '7446ee96-5dc9-55a9-9c6a-b1b1baf8b9a7';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('7446ee96-5dc9-55a9-9c6a-b1b1baf8b9a7', 'ラム・アグリコール', 60, 'ml', 0),
  ('7446ee96-5dc9-55a9-9c6a-b1b1baf8b9a7', 'ライム', 0.25, 'piece', 1),
  ('7446ee96-5dc9-55a9-9c6a-b1b1baf8b9a7', 'シュガーシロップ', 10, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('7446ee96-5dc9-55a9-9c6a-b1b1baf8b9a7', 'グラスの中でフルーツやハーブを軽くつぶす。', 0),
  ('7446ee96-5dc9-55a9-9c6a-b1b1baf8b9a7', '残りの材料と氷を加える。', 1),
  ('7446ee96-5dc9-55a9-9c6a-b1b1baf8b9a7', 'よく混ぜて仕上げる。', 2);

-- tom-collins
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '9d0c5d52-08b2-582a-9433-a0daf10ab766',
  'tom-collins',
  'トムコリンズ',
  'Tom Collins',
  'ジン、レモン、砂糖、ソーダの爽やかなロングドリンク。コリンズグラスで出す古典。',
  'Gin',
  12,
  'United States',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'ad122c74-1c6f-523c-982e-76a742e88f31',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '9d0c5d52-08b2-582a-9433-a0daf10ab766',
  'トムコリンズ（基本レシピ）',
  NULL,
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'ad122c74-1c6f-523c-982e-76a742e88f31';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'ad122c74-1c6f-523c-982e-76a742e88f31';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('ad122c74-1c6f-523c-982e-76a742e88f31', 'ドライジン', 45, 'ml', 0),
  ('ad122c74-1c6f-523c-982e-76a742e88f31', 'レモン果汁', 22.5, 'ml', 1),
  ('ad122c74-1c6f-523c-982e-76a742e88f31', 'シュガーシロップ', 15, 'ml', 2),
  ('ad122c74-1c6f-523c-982e-76a742e88f31', '炭酸水', 60, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('ad122c74-1c6f-523c-982e-76a742e88f31', 'シェイカーでジン、レモン、シロップをシェイクする。', 0),
  ('ad122c74-1c6f-523c-982e-76a742e88f31', '氷入りのコリンズグラスに注ぐ。', 1),
  ('ad122c74-1c6f-523c-982e-76a742e88f31', '炭酸水を加えて軽く混ぜる。', 2);

-- tomato-hai
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '8339422b-706c-5604-8ccf-54dc9affa5a6',
  'tomato-hai',
  'トマトハイ',
  'Tomato Hai',
  '焼酎をトマトジュースで割る、食事に合わせやすい日本のロングドリンク。',
  'Shochu',
  7,
  'Japan',
  NULL,
  'none',
  ARRAY['トマト割り']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '6c7d7866-622d-5bb3-b74e-3bfeb8197d55',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '8339422b-706c-5604-8ccf-54dc9affa5a6',
  'トマトハイ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '6c7d7866-622d-5bb3-b74e-3bfeb8197d55';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '6c7d7866-622d-5bb3-b74e-3bfeb8197d55';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('6c7d7866-622d-5bb3-b74e-3bfeb8197d55', '焼酎', 45, 'ml', 0),
  ('6c7d7866-622d-5bb3-b74e-3bfeb8197d55', 'トマトジュース', 135, 'ml', 1),
  ('6c7d7866-622d-5bb3-b74e-3bfeb8197d55', '塩', 1, 'dash', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('6c7d7866-622d-5bb3-b74e-3bfeb8197d55', 'グラスに氷を入れる。', 0),
  ('6c7d7866-622d-5bb3-b74e-3bfeb8197d55', '材料を順に注ぐ。', 1),
  ('6c7d7866-622d-5bb3-b74e-3bfeb8197d55', '軽く混ぜて仕上げる。', 2);

-- tuxedo
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'cb0ebecf-6953-596c-88d8-110b38e01eca',
  'tuxedo',
  'タキシード',
  'Tuxedo',
  'ジンとドライベルモットにマラスキーノとアブサンを添える、端正なクラシック。',
  'Gin',
  30,
  'United States',
  NULL,
  'none',
  ARRAY['タキシードNo.2']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'c5c03a1a-e949-508a-a6cf-94eea028cb52',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'cb0ebecf-6953-596c-88d8-110b38e01eca',
  'タキシード（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'c5c03a1a-e949-508a-a6cf-94eea028cb52';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'c5c03a1a-e949-508a-a6cf-94eea028cb52';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('c5c03a1a-e949-508a-a6cf-94eea028cb52', 'ドライジン', 45, 'ml', 0),
  ('c5c03a1a-e949-508a-a6cf-94eea028cb52', 'ドライベルモット', 30, 'ml', 1),
  ('c5c03a1a-e949-508a-a6cf-94eea028cb52', 'マラスキーノリキュール', 5, 'ml', 2),
  ('c5c03a1a-e949-508a-a6cf-94eea028cb52', 'アブサン', 1, 'dash', 3),
  ('c5c03a1a-e949-508a-a6cf-94eea028cb52', 'オレンジビターズ', 1, 'dash', 4);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('c5c03a1a-e949-508a-a6cf-94eea028cb52', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('c5c03a1a-e949-508a-a6cf-94eea028cb52', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('c5c03a1a-e949-508a-a6cf-94eea028cb52', '冷やしたグラスに注ぐ。', 2);

-- ume-sour
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '5c09729e-8bbd-5be5-8aa7-4abd441d91f1',
  'ume-sour',
  '梅サワー',
  'Ume Sour',
  '焼酎に梅の甘酸っぱさを合わせる、食中に飲みやすい和風サワー。',
  'Shochu',
  7,
  'Japan',
  NULL,
  'none',
  ARRAY['梅干しサワー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '8334608b-47ae-5fc4-a95b-eac2873608a4',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '5c09729e-8bbd-5be5-8aa7-4abd441d91f1',
  '梅サワー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '8334608b-47ae-5fc4-a95b-eac2873608a4';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '8334608b-47ae-5fc4-a95b-eac2873608a4';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('8334608b-47ae-5fc4-a95b-eac2873608a4', '焼酎', 45, 'ml', 0),
  ('8334608b-47ae-5fc4-a95b-eac2873608a4', '梅シロップ', 20, 'ml', 1),
  ('8334608b-47ae-5fc4-a95b-eac2873608a4', 'ソーダ', 120, 'ml', 2),
  ('8334608b-47ae-5fc4-a95b-eac2873608a4', '梅干し', 1, 'piece', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('8334608b-47ae-5fc4-a95b-eac2873608a4', 'グラスに氷を入れる。', 0),
  ('8334608b-47ae-5fc4-a95b-eac2873608a4', '材料を順に注ぐ。', 1),
  ('8334608b-47ae-5fc4-a95b-eac2873608a4', '軽く混ぜて仕上げる。', 2);

-- vesper
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '694d6f93-8599-58d5-bde9-e92825abddb8',
  'vesper',
  'ヴェスパー',
  'Vesper',
  'ジンとウォッカをリレでまとめる、ジェームズ・ボンドで知られる強いマティーニ。',
  'Gin',
  34,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['ヴェスパーマティーニ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '803d5f80-b24a-539f-82ec-562433334a54',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '694d6f93-8599-58d5-bde9-e92825abddb8',
  'ヴェスパー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '803d5f80-b24a-539f-82ec-562433334a54';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '803d5f80-b24a-539f-82ec-562433334a54';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('803d5f80-b24a-539f-82ec-562433334a54', 'ドライジン', 60, 'ml', 0),
  ('803d5f80-b24a-539f-82ec-562433334a54', 'ウォッカ', 20, 'ml', 1),
  ('803d5f80-b24a-539f-82ec-562433334a54', 'リレ・ブラン', 10, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('803d5f80-b24a-539f-82ec-562433334a54', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('803d5f80-b24a-539f-82ec-562433334a54', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('803d5f80-b24a-539f-82ec-562433334a54', '冷やしたグラスに注ぐ。', 2);

-- vieux-carre
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '7cea645c-b100-542f-b576-808e96e9d36e',
  'vieux-carre',
  'ヴューカレ',
  'Vieux Carre',
  'ライ、コニャック、ベルモットをビターズでまとめるニューオーリンズの名作。',
  'Whisky',
  29,
  'United States',
  NULL,
  'none',
  ARRAY['ヴュー・カレ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'd9e8e9a8-58f8-5a5f-84d1-d9280cb33491',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '7cea645c-b100-542f-b576-808e96e9d36e',
  'ヴューカレ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'd9e8e9a8-58f8-5a5f-84d1-d9280cb33491';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'd9e8e9a8-58f8-5a5f-84d1-d9280cb33491';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('d9e8e9a8-58f8-5a5f-84d1-d9280cb33491', 'ライウイスキー', 30, 'ml', 0),
  ('d9e8e9a8-58f8-5a5f-84d1-d9280cb33491', 'コニャック', 30, 'ml', 1),
  ('d9e8e9a8-58f8-5a5f-84d1-d9280cb33491', 'スイートベルモット', 30, 'ml', 2),
  ('d9e8e9a8-58f8-5a5f-84d1-d9280cb33491', 'ベネディクティン', 1, 'tsp', 3),
  ('d9e8e9a8-58f8-5a5f-84d1-d9280cb33491', 'ペイショーズビターズ', 2, 'dash', 4),
  ('d9e8e9a8-58f8-5a5f-84d1-d9280cb33491', 'アンゴスチュラビターズ', 2, 'dash', 5);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('d9e8e9a8-58f8-5a5f-84d1-d9280cb33491', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('d9e8e9a8-58f8-5a5f-84d1-d9280cb33491', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('d9e8e9a8-58f8-5a5f-84d1-d9280cb33491', '冷やしたグラスに注ぐ。', 2);

-- vodka-martini
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b33fffe1-efc3-50b3-84f6-a1efdb065efb',
  'vodka-martini',
  'ウォッカマティーニ',
  'Vodka Martini',
  'ジンの代わりにウォッカを使う、シャープでクリーンなマティーニ。',
  'Vodka',
  33,
  'United States',
  NULL,
  'none',
  ARRAY['カンガルー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '64994c30-a9d2-5428-b908-b4711b9cf8c9',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b33fffe1-efc3-50b3-84f6-a1efdb065efb',
  'ウォッカマティーニ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '64994c30-a9d2-5428-b908-b4711b9cf8c9';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '64994c30-a9d2-5428-b908-b4711b9cf8c9';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('64994c30-a9d2-5428-b908-b4711b9cf8c9', 'ウォッカ', 60, 'ml', 0),
  ('64994c30-a9d2-5428-b908-b4711b9cf8c9', 'ドライベルモット', 10, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('64994c30-a9d2-5428-b908-b4711b9cf8c9', 'ミキシンググラスに材料と氷を入れる。', 0),
  ('64994c30-a9d2-5428-b908-b4711b9cf8c9', 'ステアしてしっかり冷やし、香味をなじませる。', 1),
  ('64994c30-a9d2-5428-b908-b4711b9cf8c9', '冷やしたグラスに注ぐ。', 2);

-- vodka-tonic
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'acc6aefb-610a-5f0d-9fd8-730ad9141ead',
  'vodka-tonic',
  'ウォッカトニック',
  'Vodka Tonic',
  'ウォッカをトニックで割る、食中にも合わせやすいすっきりしたハイボール。',
  'Vodka',
  9,
  'United States',
  NULL,
  'none',
  ARRAY['ウォッカ・トニック']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'a72b5f8d-d330-5726-9e35-ecdc2fca7b58',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'acc6aefb-610a-5f0d-9fd8-730ad9141ead',
  'ウォッカトニック（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'a72b5f8d-d330-5726-9e35-ecdc2fca7b58';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'a72b5f8d-d330-5726-9e35-ecdc2fca7b58';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('a72b5f8d-d330-5726-9e35-ecdc2fca7b58', 'ウォッカ', 45, 'ml', 0),
  ('a72b5f8d-d330-5726-9e35-ecdc2fca7b58', 'トニックウォーター', 135, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('a72b5f8d-d330-5726-9e35-ecdc2fca7b58', 'グラスに氷を入れる。', 0),
  ('a72b5f8d-d330-5726-9e35-ecdc2fca7b58', '材料を順に注ぐ。', 1),
  ('a72b5f8d-d330-5726-9e35-ecdc2fca7b58', '軽く混ぜて仕上げる。', 2);

-- ward-eight
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '20303559-ef9d-5d34-9e0c-549cdf3d526a',
  'ward-eight',
  'ワードエイト',
  'Ward Eight',
  'ライウイスキーに柑橘とグレナデンを合わせる、ボストン生まれのサワー。',
  'Whisky',
  20,
  'United States',
  NULL,
  'none',
  ARRAY['ワード8']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '1993c45b-dab5-5b0b-9942-ed8137dab7f0',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '20303559-ef9d-5d34-9e0c-549cdf3d526a',
  'ワードエイト（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '1993c45b-dab5-5b0b-9942-ed8137dab7f0';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '1993c45b-dab5-5b0b-9942-ed8137dab7f0';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('1993c45b-dab5-5b0b-9942-ed8137dab7f0', 'ライウイスキー', 45, 'ml', 0),
  ('1993c45b-dab5-5b0b-9942-ed8137dab7f0', 'レモンジュース', 20, 'ml', 1),
  ('1993c45b-dab5-5b0b-9942-ed8137dab7f0', 'オレンジジュース', 20, 'ml', 2),
  ('1993c45b-dab5-5b0b-9942-ed8137dab7f0', 'グレナデンシロップ', 10, 'ml', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('1993c45b-dab5-5b0b-9942-ed8137dab7f0', 'シェーカーに材料と氷を入れる。', 0),
  ('1993c45b-dab5-5b0b-9942-ed8137dab7f0', 'しっかりシェイクして冷やす。', 1),
  ('1993c45b-dab5-5b0b-9942-ed8137dab7f0', '冷やしたグラスに注ぐ。', 2);

-- whiskey-smash
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'ba7ead34-930f-5515-9609-9acfc9169351',
  'whiskey-smash',
  'ウイスキースマッシュ',
  'Whiskey Smash',
  'ウイスキーにミントとレモンを合わせる、ジュレップとサワーの中間的な一杯。',
  'Whisky',
  20,
  'United States',
  NULL,
  'none',
  ARRAY['ウイスキー・スマッシュ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'be98af00-7a2b-56fa-a732-991d39b8316f',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'ba7ead34-930f-5515-9609-9acfc9169351',
  'ウイスキースマッシュ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'be98af00-7a2b-56fa-a732-991d39b8316f';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'be98af00-7a2b-56fa-a732-991d39b8316f';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('be98af00-7a2b-56fa-a732-991d39b8316f', 'バーボンウイスキー', 60, 'ml', 0),
  ('be98af00-7a2b-56fa-a732-991d39b8316f', 'レモン', 0.5, 'piece', 1),
  ('be98af00-7a2b-56fa-a732-991d39b8316f', 'シュガーシロップ', 15, 'ml', 2),
  ('be98af00-7a2b-56fa-a732-991d39b8316f', 'ミントの葉', 8, 'piece', 3);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('be98af00-7a2b-56fa-a732-991d39b8316f', 'グラスの中でフルーツやハーブを軽くつぶす。', 0),
  ('be98af00-7a2b-56fa-a732-991d39b8316f', '残りの材料と氷を加える。', 1),
  ('be98af00-7a2b-56fa-a732-991d39b8316f', 'よく混ぜて仕上げる。', 2);

-- whiskey-sour
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'b1c0aba9-b2cd-5aee-95d8-d47aafd1605f',
  'whiskey-sour',
  'ウイスキーサワー',
  'Whiskey Sour',
  'ウイスキー、レモン果汁、シロップをシェイクした古典的サワー。卵白を加えるバリエーションも人気。',
  'Whisky',
  20,
  'United States',
  NULL,
  'none',
  '{}'::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'c9d28594-43a7-5b6c-973f-fe24750557c0',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'b1c0aba9-b2cd-5aee-95d8-d47aafd1605f',
  'ウイスキーサワー（基本レシピ）',
  '好みで卵白を加えてドライシェイクすると泡立ちが美しい。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'c9d28594-43a7-5b6c-973f-fe24750557c0';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'c9d28594-43a7-5b6c-973f-fe24750557c0';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('c9d28594-43a7-5b6c-973f-fe24750557c0', 'バーボンウイスキー', 45, 'ml', 0),
  ('c9d28594-43a7-5b6c-973f-fe24750557c0', 'レモン果汁', 22.5, 'ml', 1),
  ('c9d28594-43a7-5b6c-973f-fe24750557c0', 'シュガーシロップ', 15, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('c9d28594-43a7-5b6c-973f-fe24750557c0', 'シェイカーに材料と氷を入れる。', 0),
  ('c9d28594-43a7-5b6c-973f-fe24750557c0', 'よくシェイクして冷やす。', 1),
  ('c9d28594-43a7-5b6c-973f-fe24750557c0', 'ロックグラスまたはクーペに注ぐ。', 2);

-- whisky-mac
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '5f12ddfe-024f-58e8-b2e5-e4cc893848c7',
  'whisky-mac',
  'ウイスキーマック',
  'Whisky Mac',
  'スコッチとジンジャーワインを合わせる、英国で親しまれる温冷両用の一杯。',
  'Whisky',
  28,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['ウイスキー・マック']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '1aeb6194-e6fe-5ef8-a475-6ea6450a66d0',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '5f12ddfe-024f-58e8-b2e5-e4cc893848c7',
  'ウイスキーマック（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '1aeb6194-e6fe-5ef8-a475-6ea6450a66d0';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '1aeb6194-e6fe-5ef8-a475-6ea6450a66d0';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('1aeb6194-e6fe-5ef8-a475-6ea6450a66d0', 'スコッチウイスキー', 45, 'ml', 0),
  ('1aeb6194-e6fe-5ef8-a475-6ea6450a66d0', 'ジンジャーワイン', 30, 'ml', 1);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('1aeb6194-e6fe-5ef8-a475-6ea6450a66d0', 'グラスに氷を入れる。', 0),
  ('1aeb6194-e6fe-5ef8-a475-6ea6450a66d0', '材料を順に注ぐ。', 1),
  ('1aeb6194-e6fe-5ef8-a475-6ea6450a66d0', '軽く混ぜて仕上げる。', 2);

-- white-lady
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'a6074afc-802a-5a60-a81d-70d84ad99e33',
  'white-lady',
  'ホワイトレディ',
  'White Lady',
  'ジン、ホワイトキュラソー、レモンで作る、透明感のあるサワースタイル。',
  'Gin',
  28,
  'United Kingdom',
  NULL,
  'none',
  ARRAY['ホワイト・レディ']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'd9da54cd-e7ca-53e4-88e7-b15bd4bf9dc8',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'a6074afc-802a-5a60-a81d-70d84ad99e33',
  'ホワイトレディ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'd9da54cd-e7ca-53e4-88e7-b15bd4bf9dc8';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'd9da54cd-e7ca-53e4-88e7-b15bd4bf9dc8';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('d9da54cd-e7ca-53e4-88e7-b15bd4bf9dc8', 'ドライジン', 40, 'ml', 0),
  ('d9da54cd-e7ca-53e4-88e7-b15bd4bf9dc8', 'ホワイトキュラソー', 20, 'ml', 1),
  ('d9da54cd-e7ca-53e4-88e7-b15bd4bf9dc8', 'レモンジュース', 20, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('d9da54cd-e7ca-53e4-88e7-b15bd4bf9dc8', 'シェーカーに材料と氷を入れる。', 0),
  ('d9da54cd-e7ca-53e4-88e7-b15bd4bf9dc8', 'しっかりシェイクして冷やす。', 1),
  ('d9da54cd-e7ca-53e4-88e7-b15bd4bf9dc8', '冷やしたグラスに注ぐ。', 2);

-- white-russian
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'ff36ee65-3f71-5845-b81d-3d85340eb404',
  'white-russian',
  'ホワイトルシアン',
  'White Russian',
  'ブラックルシアンにクリームを重ねた、まろやかなウォッカカクテル。',
  'Vodka',
  18,
  'United States',
  NULL,
  'none',
  ARRAY['ホワイト・ルシアン']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'dc0d5729-a6ff-57c6-b6fa-d95479a207f7',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'ff36ee65-3f71-5845-b81d-3d85340eb404',
  'ホワイトルシアン（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'dc0d5729-a6ff-57c6-b6fa-d95479a207f7';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'dc0d5729-a6ff-57c6-b6fa-d95479a207f7';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('dc0d5729-a6ff-57c6-b6fa-d95479a207f7', 'ウォッカ', 45, 'ml', 0),
  ('dc0d5729-a6ff-57c6-b6fa-d95479a207f7', 'コーヒーリキュール', 25, 'ml', 1),
  ('dc0d5729-a6ff-57c6-b6fa-d95479a207f7', '生クリーム', 30, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('dc0d5729-a6ff-57c6-b6fa-d95479a207f7', 'グラスに氷を入れる。', 0),
  ('dc0d5729-a6ff-57c6-b6fa-d95479a207f7', '材料を順に注ぐ。', 1),
  ('dc0d5729-a6ff-57c6-b6fa-d95479a207f7', '軽く混ぜて仕上げる。', 2);

-- woo-woo
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '45c39fe2-daed-5154-b162-72dc5ac087e2',
  'woo-woo',
  'ウーウー',
  'Woo Woo',
  'ウォッカ、ピーチ、クランベリーで作る、甘酸っぱく軽いパーティーカクテル。',
  'Vodka',
  12,
  'United States',
  NULL,
  'none',
  ARRAY['Woo Woo']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '1ed7755d-a77e-531f-ab60-c32c3d760794',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '45c39fe2-daed-5154-b162-72dc5ac087e2',
  'ウーウー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '1ed7755d-a77e-531f-ab60-c32c3d760794';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '1ed7755d-a77e-531f-ab60-c32c3d760794';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('1ed7755d-a77e-531f-ab60-c32c3d760794', 'ウォッカ', 40, 'ml', 0),
  ('1ed7755d-a77e-531f-ab60-c32c3d760794', 'ピーチリキュール', 20, 'ml', 1),
  ('1ed7755d-a77e-531f-ab60-c32c3d760794', 'クランベリージュース', 100, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('1ed7755d-a77e-531f-ab60-c32c3d760794', 'グラスに氷を入れる。', 0),
  ('1ed7755d-a77e-531f-ab60-c32c3d760794', '材料を順に注ぐ。', 1),
  ('1ed7755d-a77e-531f-ab60-c32c3d760794', '軽く混ぜて仕上げる。', 2);

-- yuzu-sour
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  '12bc6b19-bf43-5578-ad94-fd8839d59c01',
  'yuzu-sour',
  '柚子サワー',
  'Yuzu Sour',
  '焼酎に柚子の酸味と香りを合わせる、日本らしい爽やかなサワー。',
  'Shochu',
  7,
  'Japan',
  NULL,
  'none',
  ARRAY['ゆずサワー']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  '729ee20c-cc51-5ebe-b22a-119bc05ef166',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  '12bc6b19-bf43-5578-ad94-fd8839d59c01',
  '柚子サワー（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = '729ee20c-cc51-5ebe-b22a-119bc05ef166';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = '729ee20c-cc51-5ebe-b22a-119bc05ef166';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('729ee20c-cc51-5ebe-b22a-119bc05ef166', '焼酎', 45, 'ml', 0),
  ('729ee20c-cc51-5ebe-b22a-119bc05ef166', '柚子果汁', 20, 'ml', 1),
  ('729ee20c-cc51-5ebe-b22a-119bc05ef166', 'ソーダ', 120, 'ml', 2);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('729ee20c-cc51-5ebe-b22a-119bc05ef166', 'グラスに氷を入れる。', 0),
  ('729ee20c-cc51-5ebe-b22a-119bc05ef166', '材料を順に注ぐ。', 1),
  ('729ee20c-cc51-5ebe-b22a-119bc05ef166', '軽く混ぜて仕上げる。', 2);

-- zombie
INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, image_url, image_source, aliases)
VALUES (
  'fb3f6811-d62c-58f4-b581-93f75136bc7a',
  'zombie',
  'ゾンビ',
  'Zombie',
  '複数のラムと果汁を重ねる、ドン・ザ・ビーチコーマー発祥の強いティキカクテル。',
  'Rum',
  22,
  'United States',
  NULL,
  'none',
  ARRAY['ゾンビカクテル']::TEXT[]
)
ON CONFLICT (id) DO UPDATE SET
  slug = EXCLUDED.slug,
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  description = EXCLUDED.description,
  base_spirit = EXCLUDED.base_spirit,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  image_url = COALESCE(EXCLUDED.image_url, cocktails.image_url),
  image_source = CASE
    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source
    ELSE cocktails.image_source
  END,
  aliases = EXCLUDED.aliases,
  updated_at = now();

INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)
VALUES (
  'b902a469-13f9-5763-abd2-e12637202828',
  (SELECT id FROM auth.users WHERE email = 'official@sakehub.app'),
  'fb3f6811-d62c-58f4-b581-93f75136bc7a',
  'ゾンビ（基本レシピ）',
  'クラシックな配合を家庭でも作りやすい一杯分に整えた基本レシピ。',
  'published',
  true
)
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  cocktail_id = EXCLUDED.cocktail_id,
  name = EXCLUDED.name,
  memo = EXCLUDED.memo,
  status = EXCLUDED.status,
  is_official = EXCLUDED.is_official,
  updated_at = now();

DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = 'b902a469-13f9-5763-abd2-e12637202828';
DELETE FROM cocktail_recipe_steps WHERE recipe_id = 'b902a469-13f9-5763-abd2-e12637202828';

INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES
  ('b902a469-13f9-5763-abd2-e12637202828', 'ライトラム', 30, 'ml', 0),
  ('b902a469-13f9-5763-abd2-e12637202828', 'ダークラム', 30, 'ml', 1),
  ('b902a469-13f9-5763-abd2-e12637202828', 'オーバープルーフラム', 15, 'ml', 2),
  ('b902a469-13f9-5763-abd2-e12637202828', 'ライムジュース', 20, 'ml', 3),
  ('b902a469-13f9-5763-abd2-e12637202828', 'グレープフルーツジュース', 20, 'ml', 4),
  ('b902a469-13f9-5763-abd2-e12637202828', 'シナモンシロップ', 10, 'ml', 5);

INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES
  ('b902a469-13f9-5763-abd2-e12637202828', 'シェーカーに材料と氷を入れる。', 0),
  ('b902a469-13f9-5763-abd2-e12637202828', 'しっかりシェイクして冷やす。', 1),
  ('b902a469-13f9-5763-abd2-e12637202828', '冷やしたグラスに注ぐ。', 2);

