-- =============================================================================
-- Seed: ローカル専用。杭「禅人未登録ラベル」に完全一致する published を足す。
-- 自動 seed / config.toml sql_paths / pnpm supabase:seed / seed:prod には載せない。
-- drinks.sql（生成物）には混ぜない。
--
-- 使い方（local_zero_hit.sql 投入後）:
--   supabase db query --local --file supabase/seeds/local_stake_merge_published.sql
--   pnpm seed:drinks:merge
-- =============================================================================

INSERT INTO drinks (
  id, slug, name, name_en, category, subcategory, description,
  image_url, image_source, abv, origin_country, manufacturer, aliases,
  created_at, updated_at
) VALUES (
  'b3000000-0000-4000-8000-000000000001',
  'zh-unlisted-label',
  '禅人未登録ラベル',
  'Zenhito Unlisted Label',
  'whisky',
  'Single Malt',
  'Local-only fixture to merge a provisional stake into a published SKU.',
  NULL,
  'none',
  43,
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
