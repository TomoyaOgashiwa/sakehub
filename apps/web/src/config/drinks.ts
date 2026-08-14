import { DRINK_CATEGORIES, type DrinkCategory } from '@sakehub/types';

interface FilterCategory {
  value: DrinkCategory;
  label: string;
}

// DB の CHECK 制約（drinks.category）は 12 分類あるが、以前はこの一覧が
// beer/wine/whisky/sake/other の 5 チップのみだったため shochu/gin/rum 等へ
// フィルタ UI から到達できなかった（検索でのみ発見可能）。search_misses による
// ゼロヒット計測を導入するにあたり、まず IA 側の「見かけ上のゼロヒット」を
// 解消してから需要を読む必要があるため、全カテゴリをチップとして公開する。
//
// value の一覧は `@sakehub/types`（実体は `@sakehub/seed-utils`）の
// DRINK_CATEGORIES を single source として導出する。表示ラベルだけここで
// 管理する（Record を Exclude<never> にすることで、カテゴリ追加時に
// ラベルが無いとコンパイルエラーになる）。
const CATEGORY_LABELS: Record<DrinkCategory, string> = {
  all: 'All',
  beer: 'Beer',
  wine: 'Wine',
  whisky: 'Whisky',
  sake: 'Sake',
  shochu: 'Shochu',
  vodka: 'Vodka',
  gin: 'Gin',
  rum: 'Rum',
  tequila: 'Tequila',
  brandy: 'Brandy',
  liqueur: 'Liqueur',
  other: 'Other',
};

export const MAIN_FILTER_CATEGORIES: FilterCategory[] = DRINK_CATEGORIES.map((value) => ({
  value,
  label: CATEGORY_LABELS[value],
}));

export function drinkCategoryLabel(category: string): string {
  if (category in CATEGORY_LABELS) {
    return CATEGORY_LABELS[category as DrinkCategory];
  }
  return category;
}

export function isProductDrinkCategory(
  value: string | undefined,
): value is Exclude<DrinkCategory, 'all'> {
  return Boolean(value) && value !== 'all' && value in CATEGORY_LABELS;
}

export function makerSearchHref(manufacturer: string, category?: string): string {
  const params = new URLSearchParams();
  params.set('q', manufacturer);
  if (category) params.set('category', category);
  return `/?${params.toString()}`;
}

/** Home shelf and filtered-result page size. */
export const DRINK_LIST_PAGE_SIZE = 20;
