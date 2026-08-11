import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { assertAliases, type ValidationIssue } from '@sakehub/seed-utils';

import {
  IMAGE_SOURCES,
  INGREDIENT_UNITS,
  MAX_ALIASES,
  SLUG_PATTERN,
  type CocktailSeed,
  type ImageSource,
  type IngredientUnit,
} from './schema.ts';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const DATA_DIR = path.join(ROOT, 'data', 'cocktails');

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const UNIT_SET = new Set<string>(INGREDIENT_UNITS);
const IMAGE_SOURCE_SET = new Set<string>(IMAGE_SOURCES);

function resolveImageSource(
  imageUrl: string | null | undefined,
  imageSource: unknown,
): ImageSource {
  if (typeof imageSource === 'string' && IMAGE_SOURCE_SET.has(imageSource)) {
    return imageSource as ImageSource;
  }
  if (
    typeof imageUrl === 'string' &&
    imageUrl.includes('/storage/v1/object/public/catalog-images/cocktails/')
  ) {
    return 'generated';
  }
  return 'none';
}

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

function runeLength(s: string): number {
  return [...s].length;
}

function validateCocktail(file: string, raw: unknown, issues: ValidationIssue[]): CocktailSeed | null {
  if (!isRecord(raw)) {
    issues.push({ file, field: '(root)', message: 'must be a JSON object' });
    return null;
  }

  const slug = raw.slug;
  if (typeof slug !== 'string' || !SLUG_PATTERN.test(slug)) {
    issues.push({
      file,
      field: 'slug',
      message: 'must match /^[a-z0-9]+(?:-[a-z0-9]+)*$/',
    });
  } else if (`${slug}.json` !== file) {
    // build-seed.ts UPSERTs by the JSON's slug, so a filename/slug mismatch
    // (e.g. old-fashioned.json containing "slug": "negroni") would silently
    // write to a different row than the one a reviewer thinks they're editing.
    issues.push({
      file,
      field: 'slug',
      message: `must match filename (expected ${slug}.json, got ${file})`,
    });
  }

  if (raw.id !== null && (typeof raw.id !== 'string' || !UUID_PATTERN.test(raw.id))) {
    issues.push({ file, field: 'id', message: 'must be null or a valid UUID' });
  }

  if (typeof raw.name !== 'string' || runeLength(raw.name) < 1 || runeLength(raw.name) > 100) {
    issues.push({ file, field: 'name', message: 'must be 1–100 characters' });
  }

  if (raw.nameEn !== null && typeof raw.nameEn !== 'string') {
    issues.push({ file, field: 'nameEn', message: 'must be string or null' });
  }

  if (typeof raw.description !== 'string' || raw.description.trim() === '') {
    issues.push({ file, field: 'description', message: 'must be a non-empty string' });
  }

  if (raw.baseSpirit !== null && typeof raw.baseSpirit !== 'string') {
    issues.push({ file, field: 'baseSpirit', message: 'must be string or null' });
  }

  if (raw.abv !== null) {
    if (typeof raw.abv !== 'number' || raw.abv < 0 || raw.abv > 100) {
      issues.push({ file, field: 'abv', message: 'must be null or a number 0–100' });
    }
  }

  if (raw.originCountry !== null && typeof raw.originCountry !== 'string') {
    issues.push({ file, field: 'originCountry', message: 'must be string or null' });
  }

  // Missing imageUrl is treated as null so existing JSON files stay valid until upload fills them.
  if (
    raw.imageUrl !== undefined &&
    raw.imageUrl !== null &&
    typeof raw.imageUrl !== 'string'
  ) {
    issues.push({ file, field: 'imageUrl', message: 'must be string or null' });
  }

  if (
    raw.imageSource !== undefined &&
    (typeof raw.imageSource !== 'string' || !IMAGE_SOURCE_SET.has(raw.imageSource))
  ) {
    issues.push({
      file,
      field: 'imageSource',
      message: `must be one of ${IMAGE_SOURCES.join(', ')}`,
    });
  }

  assertAliases(file, raw.aliases, MAX_ALIASES, issues);

  if (!isRecord(raw.officialRecipe)) {
    issues.push({ file, field: 'officialRecipe', message: 'must be an object' });
    return null;
  }

  const recipe = raw.officialRecipe;
  if (typeof recipe.name !== 'string' || runeLength(recipe.name) < 1 || runeLength(recipe.name) > 100) {
    issues.push({ file, field: 'officialRecipe.name', message: 'must be 1–100 characters' });
  }

  if (recipe.memo !== null) {
    if (typeof recipe.memo !== 'string' || runeLength(recipe.memo) > 1000) {
      issues.push({
        file,
        field: 'officialRecipe.memo',
        message: 'must be null or ≤1000 characters',
      });
    }
  }

  if (!Array.isArray(recipe.ingredients) || recipe.ingredients.length < 1) {
    issues.push({
      file,
      field: 'officialRecipe.ingredients',
      message: 'must have at least 1 ingredient',
    });
  } else {
    recipe.ingredients.forEach((ing, i) => {
      if (!isRecord(ing)) {
        issues.push({
          file,
          field: `officialRecipe.ingredients[${i}]`,
          message: 'must be an object',
        });
        return;
      }
      if (typeof ing.name !== 'string' || runeLength(ing.name) < 1 || runeLength(ing.name) > 100) {
        issues.push({
          file,
          field: `officialRecipe.ingredients[${i}].name`,
          message: 'must be 1–100 characters',
        });
      }
      if (ing.amount !== null && (typeof ing.amount !== 'number' || !(ing.amount > 0))) {
        issues.push({
          file,
          field: `officialRecipe.ingredients[${i}].amount`,
          message: 'must be null or a positive number',
        });
      }
      if (ing.unit !== null && (typeof ing.unit !== 'string' || !UNIT_SET.has(ing.unit))) {
        issues.push({
          file,
          field: `officialRecipe.ingredients[${i}].unit`,
          message: `must be null or one of ${INGREDIENT_UNITS.join(', ')}`,
        });
      }
    });
  }

  if (!Array.isArray(recipe.steps) || recipe.steps.length < 1) {
    issues.push({
      file,
      field: 'officialRecipe.steps',
      message: 'must have at least 1 step',
    });
  } else {
    recipe.steps.forEach((step, i) => {
      if (typeof step !== 'string' || runeLength(step) < 1 || runeLength(step) > 500) {
        issues.push({
          file,
          field: `officialRecipe.steps[${i}]`,
          message: 'must be 1–500 characters',
        });
      }
    });
  }

  if (issues.some((iss) => iss.file === file)) {
    return null;
  }

  const cocktail = raw as unknown as CocktailSeed;
  const imageUrl =
    cocktail.imageUrl === undefined || cocktail.imageUrl === null ? null : cocktail.imageUrl;
  cocktail.imageUrl = imageUrl;
  cocktail.imageSource = resolveImageSource(imageUrl, raw.imageSource);
  if (cocktail.imageUrl === null && cocktail.imageSource !== 'none') {
    cocktail.imageSource = 'none';
  }
  return cocktail;
}

export async function loadAndValidateCocktails(
  dir: string = DATA_DIR,
): Promise<{ cocktails: CocktailSeed[]; issues: ValidationIssue[] }> {
  const issues: ValidationIssue[] = [];
  let entries: string[];
  try {
    entries = (await readdir(dir)).filter((f) => f.endsWith('.json')).sort();
  } catch (err) {
    throw new Error(`cannot read data dir ${dir}: ${err}`);
  }

  if (entries.length === 0) {
    issues.push({ file: dir, field: '(dir)', message: 'no .json files found' });
    return { cocktails: [], issues };
  }

  const cocktails: CocktailSeed[] = [];
  const slugs = new Map<string, string>();
  const ids = new Map<string, string>();

  for (const entry of entries) {
    const file = path.join(dir, entry);
    let raw: unknown;
    try {
      raw = JSON.parse(await readFile(file, 'utf8'));
    } catch (err) {
      issues.push({ file: entry, field: '(parse)', message: String(err) });
      continue;
    }

    const cocktail = validateCocktail(entry, raw, issues);
    if (!cocktail) continue;

    const prevSlug = slugs.get(cocktail.slug);
    if (prevSlug) {
      issues.push({
        file: entry,
        field: 'slug',
        message: `duplicate slug "${cocktail.slug}" (also in ${prevSlug})`,
      });
    } else {
      slugs.set(cocktail.slug, entry);
    }

    if (cocktail.id) {
      const prevId = ids.get(cocktail.id);
      if (prevId) {
        issues.push({
          file: entry,
          field: 'id',
          message: `duplicate id "${cocktail.id}" (also in ${prevId})`,
        });
      } else {
        ids.set(cocktail.id, entry);
      }
    }

    // Narrow units for type safety after validation.
    for (const ing of cocktail.officialRecipe.ingredients) {
      if (ing.unit != null && !UNIT_SET.has(ing.unit)) {
        // already reported
      } else if (ing.unit != null) {
        ing.unit = ing.unit as IngredientUnit;
      }
    }

    cocktails.push(cocktail);
  }

  return { cocktails, issues };
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
  console.log(`OK: ${cocktails.length} cocktail(s) validated.`);
}

const isMain =
  process.argv[1] != null &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);

if (isMain) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
