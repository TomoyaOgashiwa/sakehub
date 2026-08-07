'use client';

import useSWR from 'swr';

import type { DrinkListResult, FetchDrinksParams } from '@/application/drinks-api';
import { fetchDrinks } from '@/application/drinks-api';

export function useDrinks(
  params: FetchDrinksParams,
  fallbackData?: DrinkListResult,
  enabled = true,
) {
  const q = params.q ?? '';
  const key = enabled
    ? ['drinks', params.category ?? '', q, params.limit, params.offset]
    : null;

  return useSWR<DrinkListResult>(key, () => fetchDrinks(params), {
    fallbackData,
    keepPreviousData: true,
  });
}
