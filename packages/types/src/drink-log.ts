import type { DrinkCategory } from './drink';

export type VolumeUnit = 'ml' | 'oz';
export type VolumePrecision = 'exact' | 'estimated';

export type DrinkCategoryProduct = Exclude<DrinkCategory, 'all'>;

export interface ServingPreset {
  key: string;
  label: string;
  volumeMl: number;
  /** Categories that show this preset. */
  categories: readonly DrinkCategoryProduct[];
  /** Precision when the preset value is used unchanged. */
  defaultPrecision: VolumePrecision;
}

const SPIRIT_CATEGORIES = [
  'whisky',
  'vodka',
  'gin',
  'rum',
  'tequila',
  'brandy',
  'liqueur',
  'shochu',
] as const satisfies readonly DrinkCategoryProduct[];

/** Japan-oriented serving presets. Single source for Web UI. */
export const SERVING_PRESETS: readonly ServingPreset[] = [
  {
    key: 'beer_mug_m',
    label: '中ジョッキ',
    volumeMl: 300,
    categories: ['beer'],
    defaultPrecision: 'estimated',
  },
  {
    key: 'beer_mug_l',
    label: '大ジョッキ',
    volumeMl: 500,
    categories: ['beer'],
    defaultPrecision: 'estimated',
  },
  {
    key: 'beer_glass_s',
    label: '小グラス',
    volumeMl: 200,
    categories: ['beer'],
    defaultPrecision: 'estimated',
  },
  {
    key: 'beer_can_350',
    label: '350ml缶',
    volumeMl: 350,
    categories: ['beer'],
    defaultPrecision: 'exact',
  },
  {
    key: 'beer_can_500',
    label: '500ml缶',
    volumeMl: 500,
    categories: ['beer'],
    defaultPrecision: 'exact',
  },
  {
    key: 'sake_go',
    label: '一合',
    volumeMl: 180,
    categories: ['sake'],
    defaultPrecision: 'exact',
  },
  {
    key: 'sake_half_go',
    label: '半合',
    volumeMl: 90,
    categories: ['sake'],
    defaultPrecision: 'exact',
  },
  {
    key: 'sake_tokkuri',
    label: '徳利（二合目安）',
    volumeMl: 360,
    categories: ['sake'],
    defaultPrecision: 'estimated',
  },
  {
    key: 'sake_guinomi',
    label: 'ぐい飲み',
    volumeMl: 60,
    categories: ['sake'],
    defaultPrecision: 'estimated',
  },
  {
    key: 'spirit_single',
    label: 'シングル',
    volumeMl: 30,
    categories: SPIRIT_CATEGORIES,
    defaultPrecision: 'estimated',
  },
  {
    key: 'spirit_double',
    label: 'ダブル',
    volumeMl: 60,
    categories: SPIRIT_CATEGORIES,
    defaultPrecision: 'estimated',
  },
  {
    key: 'spirit_on_rocks',
    label: 'ロック（目安）',
    volumeMl: 40,
    categories: SPIRIT_CATEGORIES,
    defaultPrecision: 'estimated',
  },
  {
    key: 'wine_glass',
    label: 'グラス',
    volumeMl: 120,
    categories: ['wine'],
    defaultPrecision: 'estimated',
  },
  {
    key: 'wine_half_bottle',
    label: 'ハーフボトル',
    volumeMl: 375,
    categories: ['wine'],
    defaultPrecision: 'exact',
  },
] as const;

export const SERVING_PRESET_KEYS = SERVING_PRESETS.map((p) => p.key);

export function presetsForCategory(category: DrinkCategoryProduct): ServingPreset[] {
  return SERVING_PRESETS.filter((p) => (p.categories as readonly string[]).includes(category));
}

export function findServingPreset(key: string): ServingPreset | undefined {
  return SERVING_PRESETS.find((p) => p.key === key);
}

export interface DrinkLogDrinkSummary {
  id: string;
  slug: string;
  name: string;
  category: DrinkCategoryProduct;
  abv?: number;
}

export interface DrinkLog {
  id: string;
  userId: string;
  drinkId?: string;
  customDrinkName?: string;
  drankAt: string;
  volumeMl: number;
  quantity: number;
  inputUnit: VolumeUnit;
  inputValue: number;
  servingKey?: string;
  volumePrecision: VolumePrecision;
  placeName?: string;
  placeUrl?: string;
  createdAt: string;
  updatedAt: string;
  drink?: DrinkLogDrinkSummary;
}

export interface DrinkLogItemInput {
  drinkId?: string;
  customDrinkName?: string;
  inputUnit: VolumeUnit;
  inputValue: number;
  servingKey?: string;
  volumePrecision: VolumePrecision;
  quantity?: number;
}

export interface DrinkLogBatchCreateInput {
  drankAt?: string;
  placeName?: string;
  placeUrl?: string;
  items: DrinkLogItemInput[];
}

/** Single-log update payload (edit form). */
export interface DrinkLogUpdateInput extends DrinkLogItemInput {
  drankAt?: string;
  placeName?: string;
  placeUrl?: string;
}

/** @deprecated Prefer DrinkLogBatchCreateInput */
export interface DrinkLogCreateInput extends DrinkLogItemInput {
  drankAt?: string;
  placeName?: string;
  placeUrl?: string;
}

export interface DrinkLogSummary {
  from: string;
  to: string;
  logCount: number;
  pureAlcoholGrams: number;
  skippedMissingAbv: number;
}
