import type { DrinkCategory } from '@sakehub/types';

/**
 * Explicit drinks.category ↔ cocktails.base_spirit map.
 * Unmapped categories (sake / beer / wine / other) stay unmapped.
 * Cachaca has no drink category — cocktail → drink return is omitted.
 */
export const DRINK_CATEGORY_TO_BASE_SPIRIT = {
  whisky: 'Whisky',
  gin: 'Gin',
  vodka: 'Vodka',
  rum: 'Rum',
  tequila: 'Tequila',
  shochu: 'Shochu',
  brandy: 'Brandy',
  liqueur: 'Liqueur',
} as const satisfies Partial<Record<Exclude<DrinkCategory, 'all'>, string>>;

export type BridgedDrinkCategory = keyof typeof DRINK_CATEGORY_TO_BASE_SPIRIT;
export type BridgedBaseSpirit = (typeof DRINK_CATEGORY_TO_BASE_SPIRIT)[BridgedDrinkCategory];

export const BRIDGE_PREVIEW_LIMIT = 4;

const BASE_SPIRIT_TO_DRINK_CATEGORY = Object.fromEntries(
  Object.entries(DRINK_CATEGORY_TO_BASE_SPIRIT).map(([category, baseSpirit]) => [
    baseSpirit,
    category,
  ]),
) as Record<BridgedBaseSpirit, BridgedDrinkCategory>;

export function baseSpiritForDrinkCategory(category: string | undefined): BridgedBaseSpirit | null {
  if (!category) return null;
  if (category in DRINK_CATEGORY_TO_BASE_SPIRIT) {
    return DRINK_CATEGORY_TO_BASE_SPIRIT[category as BridgedDrinkCategory];
  }
  return null;
}

export function drinkCategoryForBaseSpirit(
  baseSpirit: string | undefined,
): BridgedDrinkCategory | null {
  if (!baseSpirit) return null;
  if (baseSpirit in BASE_SPIRIT_TO_DRINK_CATEGORY) {
    return BASE_SPIRIT_TO_DRINK_CATEGORY[baseSpirit as BridgedBaseSpirit];
  }
  return null;
}

export function firstMappedBaseSpirit(
  categories: ReadonlyArray<{ category: Exclude<DrinkCategory, 'all'> }>,
): BridgedBaseSpirit | null {
  for (const row of categories) {
    const baseSpirit = baseSpiritForDrinkCategory(row.category);
    if (baseSpirit) return baseSpirit;
  }
  return null;
}

export function cocktailsByBaseSpiritHref(baseSpirit: string): string {
  return `/cocktails?base_spirit=${encodeURIComponent(baseSpirit)}`;
}

export function drinksByCategoryHref(category: string): string {
  return `/?category=${encodeURIComponent(category)}`;
}
