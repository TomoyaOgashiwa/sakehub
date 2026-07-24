import type { DrinkCategory } from '@sakehub/types';

interface FilterCategory {
  // 'cocktail' は drinks のカテゴリではなく、cocktails マスタ一覧を表示する特別な値
  value: DrinkCategory | 'all' | 'cocktail';
  label: string;
}

export const MAIN_FILTER_CATEGORIES: FilterCategory[] = [
  { value: 'all', label: 'All' },
  { value: 'beer', label: 'Beer' },
  { value: 'wine', label: 'Wine' },
  { value: 'whisky', label: 'Whisky' },
  { value: 'sake', label: 'Sake' },
  { value: 'cocktail', label: 'Cocktail' },
  { value: 'other', label: 'Other' },
];
