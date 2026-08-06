/**
 * Mirrors drinks.category CHECK constraint (supabase/migrations/20260515210611_create_drinks.sql)
 * and packages/types/src/drink.ts DRINK_CATEGORIES (excluding 'all').
 */
export const DRINK_CATEGORIES = [
  'beer',
  'wine',
  'whisky',
  'sake',
  'shochu',
  'vodka',
  'gin',
  'rum',
  'tequila',
  'brandy',
  'liqueur',
  'other',
] as const;

export type DrinkCategory = (typeof DRINK_CATEGORIES)[number];

/**
 * 粒度ルール（AGENTS.md 参照）: 1レコード = 商品（SKU / expression）レベル。
 * 年数・特定名称・度数（ABV）が異なれば別レコード、限定ラベル・ロット違いは
 * 同一レコードに寄せる。迷ったら data/drinks/dassai-23.json や
 * data/drinks/yamazaki-12.json を基準にする。
 *
 * abv / manufacturer / originCountry / description は事実系フィールドであり、
 * LLM が誤った値を自信満々に生成しやすい領域。draft.ts はこれらを埋めず
 * null のままにする（人が一次ソースを確認して補完する）。
 */
export interface DrinkSeed {
  slug: string;
  name: string;
  nameEn: string | null;
  category: DrinkCategory;
  subcategory: string | null;
  description: string;
  imageUrl: string | null;
  abv: number | null;
  originCountry: string | null;
  manufacturer: string | null;
  /** かな読み・ローマ字表記などの別名候補。drinks.search_vector に合流する。 */
  aliases: string[];
}

export const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

/** Mirrors chk_drinks_aliases_length (migrations/20260806100000_add_drink_cocktail_aliases.sql). */
export const MAX_ALIASES = 20;
