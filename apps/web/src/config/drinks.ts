import type { DrinkCategory } from '@sakehub/types';

interface FilterCategory {
  value: DrinkCategory | 'all';
  label: string;
}

export const MAIN_FILTER_CATEGORIES: FilterCategory[] = [
  { value: 'all', label: 'All' },
  { value: 'beer', label: 'Beer' },
  { value: 'wine', label: 'Wine' },
  { value: 'whisky', label: 'Whisky' },
  { value: 'sake', label: 'Sake' },
  { value: 'other', label: 'Other' },
];
