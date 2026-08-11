/**
 * drinks.category の CHECK 制約
 * （supabase/migrations/20260515210611_create_drinks.sql）と一致させる single
 * source は `@sakehub/seed-utils`。`packages/types/src/drink.ts` の
 * `DRINK_CATEGORIES`（'all' を含む UI 向け一覧）も同じ起点から導出している。
 * import 元をこのファイルのまま保つため、ここで re-export する。
 */
import { DRINK_CATEGORIES, type DrinkCategory } from '@sakehub/seed-utils';

export { DRINK_CATEGORIES, type DrinkCategory };

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
/** Catalog master image attribution (UI label + regulatory disclosure). */
export const IMAGE_SOURCES = ['none', 'generated', 'brand'] as const;
export type ImageSource = (typeof IMAGE_SOURCES)[number];

export interface DrinkSeed {
  slug: string;
  name: string;
  nameEn: string | null;
  category: DrinkCategory;
  subcategory: string | null;
  description: string;
  imageUrl: string | null;
  /** none = no image; generated = AI; brand = company-provided. */
  imageSource: ImageSource;
  abv: number | null;
  originCountry: string | null;
  manufacturer: string | null;
  /** かな読み・ローマ字表記などの別名候補。drinks.search_vector に合流する。 */
  aliases: string[];
}

export const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

/** chk_drinks_aliases_length（migrations/20260806100000_add_drink_cocktail_aliases.sql）と一致。 */
export const MAX_ALIASES = 20;
