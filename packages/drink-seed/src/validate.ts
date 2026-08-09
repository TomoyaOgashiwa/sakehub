import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  assertAliases,
  assertManufacturerQuality,
  type ValidationIssue,
} from '@sakehub/seed-utils';

import { DRINK_CATEGORIES, MAX_ALIASES, SLUG_PATTERN, type DrinkSeed } from './schema.ts';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const DATA_DIR = path.join(ROOT, 'data', 'drinks');

const CATEGORY_SET = new Set<string>(DRINK_CATEGORIES);

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

function runeLength(s: string): number {
  return [...s].length;
}

function validateDrink(file: string, raw: unknown, issues: ValidationIssue[]): DrinkSeed | null {
  if (!isRecord(raw)) {
    issues.push({ file, field: '(root)', message: 'must be a JSON object' });
    return null;
  }

  const slug = raw.slug;
  if (typeof slug !== 'string' || !SLUG_PATTERN.test(slug)) {
    issues.push({ file, field: 'slug', message: 'must match /^[a-z0-9]+(?:-[a-z0-9]+)*$/' });
  } else if (`${slug}.json` !== file) {
    // build-seed.ts は JSON の slug で ON CONFLICT (slug) するため、ファイル名と
    // slug がずれると「レビュー時に見ていたファイル」と「実際の UPSERT 先」が
    // 一致しなくなる（dassai-23.json の中身が yamazaki-12 を指す、等の事故）。
    issues.push({
      file,
      field: 'slug',
      message: `must match filename (expected ${slug}.json, got ${file})`,
    });
  }

  if (typeof raw.name !== 'string' || runeLength(raw.name) < 1 || runeLength(raw.name) > 200) {
    issues.push({ file, field: 'name', message: 'must be 1–200 characters' });
  }

  if (raw.nameEn !== null && typeof raw.nameEn !== 'string') {
    issues.push({ file, field: 'nameEn', message: 'must be string or null' });
  }

  if (typeof raw.category !== 'string' || !CATEGORY_SET.has(raw.category)) {
    issues.push({
      file,
      field: 'category',
      message: `must be one of ${DRINK_CATEGORIES.join(', ')}`,
    });
  }

  if (raw.subcategory !== null && typeof raw.subcategory !== 'string') {
    issues.push({ file, field: 'subcategory', message: 'must be string or null' });
  }

  if (typeof raw.description !== 'string') {
    issues.push({ file, field: 'description', message: 'must be a string (may be empty)' });
  }

  if (raw.imageUrl !== null && typeof raw.imageUrl !== 'string') {
    issues.push({ file, field: 'imageUrl', message: 'must be string or null' });
  }

  if (raw.abv !== null) {
    if (typeof raw.abv !== 'number' || raw.abv < 0 || raw.abv > 100) {
      issues.push({ file, field: 'abv', message: 'must be null or a number 0–100' });
    }
  }

  if (raw.originCountry !== null && typeof raw.originCountry !== 'string') {
    issues.push({ file, field: 'originCountry', message: 'must be string or null' });
  }

  if (raw.manufacturer !== null && typeof raw.manufacturer !== 'string') {
    issues.push({ file, field: 'manufacturer', message: 'must be string or null' });
  }

  assertManufacturerQuality(file, raw.manufacturer, issues, raw.description);
  assertAliases(file, raw.aliases, MAX_ALIASES, issues);

  if (issues.some((iss) => iss.file === file)) {
    return null;
  }

  return raw as unknown as DrinkSeed;
}

export async function loadAndValidateDrinks(
  dir: string = DATA_DIR,
): Promise<{ drinks: DrinkSeed[]; issues: ValidationIssue[] }> {
  const issues: ValidationIssue[] = [];
  let entries: string[];
  try {
    entries = (await readdir(dir)).filter((f) => f.endsWith('.json')).sort();
  } catch (err) {
    throw new Error(`cannot read data dir ${dir}: ${err}`);
  }

  if (entries.length === 0) {
    issues.push({ file: dir, field: '(dir)', message: 'no .json files found' });
    return { drinks: [], issues };
  }

  const drinks: DrinkSeed[] = [];
  const slugs = new Map<string, string>();

  for (const entry of entries) {
    const file = path.join(dir, entry);
    let raw: unknown;
    try {
      raw = JSON.parse(await readFile(file, 'utf8'));
    } catch (err) {
      issues.push({ file: entry, field: '(parse)', message: String(err) });
      continue;
    }

    const drink = validateDrink(entry, raw, issues);
    if (!drink) continue;

    const prevSlug = slugs.get(drink.slug);
    if (prevSlug) {
      issues.push({
        file: entry,
        field: 'slug',
        message: `duplicate slug "${drink.slug}" (also in ${prevSlug})`,
      });
    } else {
      slugs.set(drink.slug, entry);
    }

    drinks.push(drink);
  }

  return { drinks, issues };
}

async function main(): Promise<void> {
  const { drinks, issues } = await loadAndValidateDrinks();
  if (issues.length > 0) {
    console.error(`Validation failed (${issues.length} issue(s)):`);
    for (const iss of issues) {
      console.error(`  ${iss.file} :: ${iss.field}: ${iss.message}`);
    }
    process.exit(1);
  }
  console.log(`OK: ${drinks.length} drink(s) validated.`);
}

const isMain =
  process.argv[1] != null && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);

if (isMain) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
