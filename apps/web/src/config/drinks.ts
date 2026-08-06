import type { DrinkCategory } from '@sakehub/types';

interface FilterCategory {
  value: DrinkCategory | 'all';
  label: string;
}

// DB の CHECK 制約（drinks.category）は 12 分類あるが、以前はこの一覧が
// beer/wine/whisky/sake/other の 5 チップのみだったため shochu/gin/rum 等へ
// フィルタ UI から到達できなかった（検索でのみ発見可能）。search_misses による
// ゼロヒット計測を導入するにあたり、まず IA 側の「見かけ上のゼロヒット」を
// 解消してから需要を読む必要があるため、全カテゴリをチップとして公開する。
export const MAIN_FILTER_CATEGORIES: FilterCategory[] = [
  { value: 'all', label: 'All' },
  { value: 'beer', label: 'Beer' },
  { value: 'wine', label: 'Wine' },
  { value: 'whisky', label: 'Whisky' },
  { value: 'sake', label: 'Sake' },
  { value: 'shochu', label: 'Shochu' },
  { value: 'vodka', label: 'Vodka' },
  { value: 'gin', label: 'Gin' },
  { value: 'rum', label: 'Rum' },
  { value: 'tequila', label: 'Tequila' },
  { value: 'brandy', label: 'Brandy' },
  { value: 'liqueur', label: 'Liqueur' },
  { value: 'other', label: 'Other' },
];
