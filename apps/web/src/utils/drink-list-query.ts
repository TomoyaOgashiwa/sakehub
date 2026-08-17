import { DRINK_LIST_SORTS, type DrinkListSort } from '@sakehub/types';

function isDrinkListSort(value: string): value is DrinkListSort {
  return (DRINK_LIST_SORTS as readonly string[]).includes(value);
}

export function parseDrinkListSort(raw: string | null | undefined): DrinkListSort {
  if (raw && isDrinkListSort(raw)) {
    return raw;
  }
  return 'newest';
}

export function isCategoryFilterActive(category: string): boolean {
  return category !== '' && category !== 'all';
}

export function isDrinkListPaged(input: {
  q: string;
  category: string;
  sort: DrinkListSort;
}): boolean {
  // Do not treat category=all as a filter. A truthy category would page the shelf
  // for shared URLs like ?category=all&offset=20.
  // q is not trimmed here: RSC trims before calling; the client passes searchParams as-is.
  return Boolean(input.q || isCategoryFilterActive(input.category) || input.sort !== 'newest');
}

export function parseOffset(raw: string | null | undefined): number {
  const n = Number(raw);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}
