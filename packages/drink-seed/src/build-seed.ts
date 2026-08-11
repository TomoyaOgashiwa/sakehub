import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  quoteLiteral,
  quoteNullableLiteral,
  quoteNullableNumber,
  quoteTextArrayLiteral,
} from '@sakehub/seed-utils';

import { loadAndValidateDrinks } from './validate.ts';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const REPO_ROOT = path.resolve(ROOT, '../..');
const OUT_PATH = path.join(REPO_ROOT, 'supabase', 'seeds', 'drinks.sql');

async function main(): Promise<void> {
  const { drinks, issues } = await loadAndValidateDrinks();
  if (issues.length > 0) {
    console.error(`Validation failed (${issues.length} issue(s)):`);
    for (const iss of issues) {
      console.error(`  ${iss.file} :: ${iss.field}: ${iss.message}`);
    }
    process.exit(1);
  }

  const lines: string[] = [];
  lines.push(`-- =============================================================================`);
  lines.push(`-- packages/drink-seed（src/build-seed.ts）が自動生成。`);
  lines.push(`-- 手編集しないこと。再生成: pnpm seed:drinks:build`);
  lines.push(`-- 生成日時: ${new Date().toISOString()}`);
  lines.push(`-- 件数: ${drinks.length}`);
  lines.push(`--`);
  lines.push(`-- aliases: かな読み・ローマ字表記などの別名候補。「獺祭」で登録されていても`);
  lines.push(`-- 「だっさい」で検索するとヒットしない、といった表記ゆれを吸収するために`);
  lines.push(`-- drinks.search_vector に合流させている`);
  lines.push(`-- (migrations/20260806100000_add_drink_cocktail_aliases.sql)。`);
  lines.push(`-- =============================================================================`);
  lines.push('');

  for (const d of drinks) {
    lines.push(`-- ${d.slug}`);
    lines.push(
      `INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, image_source, abv, origin_country, manufacturer, aliases)`,
    );
    lines.push(`VALUES (`);
    lines.push(`  ${quoteLiteral(d.slug)},`);
    lines.push(`  ${quoteLiteral(d.name)},`);
    lines.push(`  ${quoteNullableLiteral(d.nameEn)},`);
    lines.push(`  ${quoteLiteral(d.category)},`);
    lines.push(`  ${quoteNullableLiteral(d.subcategory)},`);
    lines.push(`  ${quoteLiteral(d.description)},`);
    lines.push(`  ${quoteNullableLiteral(d.imageUrl)},`);
    lines.push(`  ${quoteLiteral(d.imageSource)},`);
    lines.push(`  ${quoteNullableNumber(d.abv)},`);
    lines.push(`  ${quoteNullableLiteral(d.originCountry)},`);
    lines.push(`  ${quoteNullableLiteral(d.manufacturer)},`);
    lines.push(`  ${quoteTextArrayLiteral(d.aliases)}`);
    lines.push(`)`);
    // slug は UNIQUE NOT NULL（create_drinks.sql）。既存 DB（Phase 3 承認後など）
    // に対してパイプラインを再実行しても、エラーや行の二重化ではなく
    // その場で UPSERT されるようにする。
    lines.push(`ON CONFLICT (slug) DO UPDATE SET`);
    lines.push(`  name = EXCLUDED.name,`);
    lines.push(`  name_en = EXCLUDED.name_en,`);
    lines.push(`  category = EXCLUDED.category,`);
    lines.push(`  subcategory = EXCLUDED.subcategory,`);
    lines.push(`  description = EXCLUDED.description,`);
    // Preserve existing Storage URL / attribution when seed has not uploaded an image yet.
    lines.push(`  image_url = COALESCE(EXCLUDED.image_url, drinks.image_url),`);
    lines.push(`  image_source = CASE`);
    lines.push(`    WHEN EXCLUDED.image_url IS NOT NULL THEN EXCLUDED.image_source`);
    lines.push(`    ELSE drinks.image_source`);
    lines.push(`  END,`);
    lines.push(`  abv = EXCLUDED.abv,`);
    lines.push(`  origin_country = EXCLUDED.origin_country,`);
    lines.push(`  manufacturer = EXCLUDED.manufacturer,`);
    lines.push(`  aliases = EXCLUDED.aliases,`);
    lines.push(`  updated_at = now();`);
    lines.push('');
  }

  await mkdir(path.dirname(OUT_PATH), { recursive: true });
  await writeFile(OUT_PATH, lines.join('\n') + '\n', 'utf8');
  console.log(`Wrote ${drinks.length} drink(s) → ${path.relative(REPO_ROOT, OUT_PATH)}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
