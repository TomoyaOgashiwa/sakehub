/** Allowed ingredient units — mirrors DB chk_ingredient_unit. */
export const INGREDIENT_UNITS = [
  'ml',
  'g',
  'piece',
  'tsp',
  'tbsp',
  'dash',
  'drop',
  'oz',
  'cl',
] as const;

export type IngredientUnit = (typeof INGREDIENT_UNITS)[number];

export interface SeedIngredient {
  name: string;
  amount: number | null;
  unit: IngredientUnit | null;
}

export interface OfficialRecipeSeed {
  name: string;
  memo: string | null;
  ingredients: SeedIngredient[];
  /** Step bodies in display order (1–500 chars each). */
  steps: string[];
}

/**
 * One cocktail master + its official basic recipe.
 * `id` is null for new cocktails (derived from slug via UUIDv5).
 * Existing 8 cocktails set `id` explicitly to preserve seed FK references.
 */
export interface CocktailSeed {
  slug: string;
  id: string | null;
  name: string;
  nameEn: string | null;
  description: string;
  baseSpirit: string | null;
  abv: number | null;
  originCountry: string | null;
  /** かな読み・ローマ字表記などの別名候補。cocktails.search_vector に合流する。 */
  aliases: string[];
  officialRecipe: OfficialRecipeSeed;
}

export const OFFICIAL_USER_EMAIL = 'official@sakehub.app';
export const OFFICIAL_DISPLAY_NAME = 'SakeHub公式';

/** slug: lowercase kebab-case, 1–80 chars. */
export const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
