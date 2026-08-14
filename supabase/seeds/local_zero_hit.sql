-- =============================================================================
-- Seed: ローカル専用 Zero Hit 再現データ
-- 本番 / pnpm supabase:seed:prod には流さない。
-- drinks.sql（生成物）には混ぜない。local_demo の後に実行する。
--
-- 再現クエリ（トップ / の q）:
--   類似ありゼロ件:  Zenhito Cedr Malt
--   類似なしゼロ件:  xqzt9zeroHitNoCatalog
--
-- 仮の印: rater01@example.com / password123 でログインすると
--   「禅人未登録ラベル」が /list?pending=1 と「最近残した」に出る（図鑑待ち）。
-- rater02 にも同じ正規化名の杭を入れ、マージで複数ユーザー付け替えを見られる。
--
-- マージ再現（自動 seed には載せない。drinks.sql / seed:prod にも入れない）:
--   1. rater01 で /list → 図鑑待ち 1。行は非リンク。
--   2. supabase db query --local --file supabase/seeds/local_stake_merge_published.sql
--   3. pnpm seed:drinks:merge
--   4. /list で「禅人未登録ラベル」が /drinks/zh-unlisted-label になり、
--      Whisky の分子と分母が 1 増える。最近残したも銘柄ページへ。
-- =============================================================================

-- 1. 類似用 published フィクスチャ（造語。aliases なし。棚の先頭を占領しないよう古い created_at）
INSERT INTO drinks (
  id, slug, name, name_en, category, subcategory, description,
  image_url, image_source, abv, origin_country, manufacturer, aliases,
  created_at, updated_at
) VALUES
(
  'b1000000-0000-4000-8000-000000000001',
  'zh-cedar-malt',
  'Zenhito Cedar Malt',
  'Zenhito Cedar Malt',
  'whisky',
  'Single Malt',
  'Local-only fixture for zero-hit similarity. Not a real product.',
  NULL,
  'none',
  43,
  'Japan',
  'Zenhito Distillery',
  '{}'::TEXT[],
  TIMESTAMPTZ '2000-01-01 00:00:00+00',
  TIMESTAMPTZ '2000-01-01 00:00:00+00'
),
(
  'b1000000-0000-4000-8000-000000000002',
  'zh-cedar-malt-reserve',
  'Zenhito Cedar Malt Reserve',
  'Zenhito Cedar Malt Reserve',
  'whisky',
  'Single Malt',
  'Local-only fixture for zero-hit similarity. Not a real product.',
  NULL,
  'none',
  46,
  'Japan',
  'Zenhito Distillery',
  '{}'::TEXT[],
  TIMESTAMPTZ '2000-01-01 00:00:00+00',
  TIMESTAMPTZ '2000-01-01 00:00:00+00'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  created_at = EXCLUDED.created_at,
  updated_at = EXCLUDED.updated_at;

-- 2. rater01 の仮の印（公開検索・sitemap・詳細には出さない）
--    name_normalized は pkg/normalize.Query（「禅人未登録ラベル」→「禅人未登録らべる」）
INSERT INTO drinks (
  id, slug, name, name_normalized, category, description,
  visibility, submitted_by, image_source, created_at, updated_at
) VALUES (
  'b2000000-0000-4000-8000-000000000001',
  'p-b2000000000040008000000000000001',
  '禅人未登録ラベル',
  '禅人未登録らべる',
  'other',
  '',
  'provisional',
  'a1000000-0000-4000-8000-000000000001',
  'none',
  TIMESTAMPTZ '2000-01-02 00:00:00+00',
  TIMESTAMPTZ '2000-01-02 00:00:00+00'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_normalized = EXCLUDED.name_normalized,
  visibility = EXCLUDED.visibility,
  submitted_by = EXCLUDED.submitted_by,
  category = EXCLUDED.category;

INSERT INTO saved_drinks (user_id, drink_id, status, note)
VALUES (
  'a1000000-0000-4000-8000-000000000001',
  'b2000000-0000-4000-8000-000000000001',
  'drank',
  ''
)
ON CONFLICT (user_id, drink_id) DO UPDATE SET
  status = EXCLUDED.status;

-- 3. rater02 の同じ正規化名の杭（複数ユーザー付け替え用）
INSERT INTO drinks (
  id, slug, name, name_normalized, category, description,
  visibility, submitted_by, image_source, created_at, updated_at
) VALUES (
  'b2000000-0000-4000-8000-000000000002',
  'p-b2000000000040008000000000000002',
  '禅人未登録ラベル',
  '禅人未登録らべる',
  'other',
  '',
  'provisional',
  'a1000000-0000-4000-8000-000000000002',
  'none',
  TIMESTAMPTZ '2000-01-02 00:00:00+00',
  TIMESTAMPTZ '2000-01-02 00:00:00+00'
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_normalized = EXCLUDED.name_normalized,
  visibility = EXCLUDED.visibility,
  submitted_by = EXCLUDED.submitted_by,
  category = EXCLUDED.category;

INSERT INTO saved_drinks (user_id, drink_id, status, note)
VALUES (
  'a1000000-0000-4000-8000-000000000002',
  'b2000000-0000-4000-8000-000000000002',
  'drank',
  ''
)
ON CONFLICT (user_id, drink_id) DO UPDATE SET
  status = EXCLUDED.status;
