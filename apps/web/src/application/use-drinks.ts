'use client';

import useSWR from 'swr';

import type { DrinkListResult, FetchDrinksParams } from '@/application/drinks-api';
import { fetchDrinks } from '@/application/drinks-api';
import { isCategoryFilterActive, parseDrinkListSort } from '@/utils/drink-list-query';

export function useDrinks(
  params: FetchDrinksParams,
  fallbackData?: DrinkListResult,
  enabled = true,
) {
  const q = params.q ?? '';
  const sort = parseDrinkListSort(params.sort);
  const categoryKey = isCategoryFilterActive(params.category ?? '') ? (params.category ?? '') : '';
  const key = enabled ? ['drinks', categoryKey, q, sort, params.limit, params.offset] : null;

  return useSWR<DrinkListResult>(key, () => fetchDrinks(params), {
    fallbackData,
    keepPreviousData: true,
  });
}
