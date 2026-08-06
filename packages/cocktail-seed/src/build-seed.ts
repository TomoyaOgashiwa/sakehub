import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { OFFICIAL_DISPLAY_NAME, OFFICIAL_USER_EMAIL } from './schema.ts';
import {
  quoteLiteral,
  quoteNullableLiteral,
  quoteNullableNumber,
  quoteTextArrayLiteral,
} from './sql.ts';
import { officialRecipeIdFromSlug, resolveCocktailId } from './uuid.ts';
import { loadAndValidateCocktails } from './validate.ts';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const REPO_ROOT = path.resolve(ROOT, '../..');
const OUT_PATH = path.join(REPO_ROOT, 'supabase', 'seeds', 'official_cocktails.sql');

function buildOfficialUserSql(): string {
  // Idempotent: if Auth already has this email (e.g. production), INSERT is a no-op.
  return `-- ---------------------------------------------------------------------------
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
  ${quoteLiteral(OFFICIAL_USER_EMAIL)},
  crypt('official-seed-only', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('display_name', ${quoteLiteral(OFFICIAL_DISPLAY_NAME)}),
  now(),
  now(),
  '',
  '',
  '',
  ''
WHERE NOT EXISTS (
  SELECT 1 FROM auth.users WHERE email = ${quoteLiteral(OFFICIAL_USER_EMAIL)}
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
WHERE u.email = ${quoteLiteral(OFFICIAL_USER_EMAIL)}
  AND NOT EXISTS (
    SELECT 1 FROM auth.identities i
    WHERE i.user_id = u.id AND i.provider = 'email'
  );

UPDATE public.users
SET display_name = ${quoteLiteral(OFFICIAL_DISPLAY_NAME)}
WHERE email = ${quoteLiteral(OFFICIAL_USER_EMAIL)};
`;
}

function officialUserIdExpr(): string {
  return `(SELECT id FROM auth.users WHERE email = ${quoteLiteral(OFFICIAL_USER_EMAIL)})`;
}

async function main(): Promise<void> {
  const { cocktails, issues } = await loadAndValidateCocktails();
  if (issues.length > 0) {
    console.error(`Validation failed (${issues.length} issue(s)):`);
    for (const iss of issues) {
      console.error(`  ${iss.file} :: ${iss.field}: ${iss.message}`);
    }
    process.exit(1);
  }

  const lines: string[] = [];
  lines.push(`-- =============================================================================`);
  lines.push(`-- packages/cocktail-seed（src/build-seed.ts）が自動生成。`);
  lines.push(`-- 手編集しないこと。再生成: pnpm seed:cocktails:build`);
  lines.push(`-- 生成日時: ${new Date().toISOString()}`);
  lines.push(`-- 件数: ${cocktails.length}`);
  lines.push(`-- =============================================================================`);
  lines.push('');
  lines.push(`CREATE EXTENSION IF NOT EXISTS pgcrypto;`);
  lines.push('');
  lines.push(buildOfficialUserSql());
  lines.push(`-- ---------------------------------------------------------------------------`);
  lines.push(`-- cocktails master + official recipes`);
  lines.push(`-- ---------------------------------------------------------------------------`);
  lines.push('');

  const userId = officialUserIdExpr();

  for (const c of cocktails) {
    const cocktailId = resolveCocktailId(c.slug, c.id);
    const recipeId = officialRecipeIdFromSlug(c.slug);
    const recipe = c.officialRecipe;

    lines.push(`-- ${c.slug}`);
    lines.push(
      `INSERT INTO cocktails (id, slug, name, name_en, description, base_spirit, abv, origin_country, aliases)`,
    );
    lines.push(`VALUES (`);
    lines.push(`  ${quoteLiteral(cocktailId)},`);
    lines.push(`  ${quoteLiteral(c.slug)},`);
    lines.push(`  ${quoteLiteral(c.name)},`);
    lines.push(`  ${quoteNullableLiteral(c.nameEn)},`);
    lines.push(`  ${quoteLiteral(c.description)},`);
    lines.push(`  ${quoteNullableLiteral(c.baseSpirit)},`);
    lines.push(`  ${quoteNullableNumber(c.abv)},`);
    lines.push(`  ${quoteNullableLiteral(c.originCountry)},`);
    lines.push(`  ${quoteTextArrayLiteral(c.aliases)}`);
    lines.push(`)`);
    lines.push(`ON CONFLICT (id) DO UPDATE SET`);
    lines.push(`  slug = EXCLUDED.slug,`);
    lines.push(`  name = EXCLUDED.name,`);
    lines.push(`  name_en = EXCLUDED.name_en,`);
    lines.push(`  description = EXCLUDED.description,`);
    lines.push(`  base_spirit = EXCLUDED.base_spirit,`);
    lines.push(`  abv = EXCLUDED.abv,`);
    lines.push(`  origin_country = EXCLUDED.origin_country,`);
    lines.push(`  aliases = EXCLUDED.aliases,`);
    lines.push(`  updated_at = now();`);
    lines.push('');

    lines.push(
      `INSERT INTO cocktail_recipes (id, user_id, cocktail_id, name, memo, status, is_official)`,
    );
    lines.push(`VALUES (`);
    lines.push(`  ${quoteLiteral(recipeId)},`);
    lines.push(`  ${userId},`);
    lines.push(`  ${quoteLiteral(cocktailId)},`);
    lines.push(`  ${quoteLiteral(recipe.name)},`);
    lines.push(`  ${quoteNullableLiteral(recipe.memo)},`);
    lines.push(`  'published',`);
    lines.push(`  true`);
    lines.push(`)`);
    lines.push(`ON CONFLICT (id) DO UPDATE SET`);
    lines.push(`  user_id = EXCLUDED.user_id,`);
    lines.push(`  cocktail_id = EXCLUDED.cocktail_id,`);
    lines.push(`  name = EXCLUDED.name,`);
    lines.push(`  memo = EXCLUDED.memo,`);
    lines.push(`  status = EXCLUDED.status,`);
    lines.push(`  is_official = EXCLUDED.is_official,`);
    lines.push(`  updated_at = now();`);
    lines.push('');

    lines.push(
      `DELETE FROM cocktail_recipe_ingredients WHERE recipe_id = ${quoteLiteral(recipeId)};`,
    );
    lines.push(`DELETE FROM cocktail_recipe_steps WHERE recipe_id = ${quoteLiteral(recipeId)};`);
    lines.push('');

    if (recipe.ingredients.length > 0) {
      lines.push(
        `INSERT INTO cocktail_recipe_ingredients (recipe_id, name, amount, unit, sort_order) VALUES`,
      );
      const ingRows = recipe.ingredients.map((ing, idx) => {
        return `  (${quoteLiteral(recipeId)}, ${quoteLiteral(ing.name)}, ${quoteNullableNumber(ing.amount)}, ${quoteNullableLiteral(ing.unit)}, ${idx})`;
      });
      lines.push(ingRows.join(',\n') + ';');
      lines.push('');
    }

    if (recipe.steps.length > 0) {
      lines.push(`INSERT INTO cocktail_recipe_steps (recipe_id, body, sort_order) VALUES`);
      const stepRows = recipe.steps.map((body, idx) => {
        return `  (${quoteLiteral(recipeId)}, ${quoteLiteral(body)}, ${idx})`;
      });
      lines.push(stepRows.join(',\n') + ';');
      lines.push('');
    }
  }

  await mkdir(path.dirname(OUT_PATH), { recursive: true });
  await writeFile(OUT_PATH, lines.join('\n') + '\n', 'utf8');
  console.log(`Wrote ${cocktails.length} cocktail(s) → ${path.relative(REPO_ROOT, OUT_PATH)}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
