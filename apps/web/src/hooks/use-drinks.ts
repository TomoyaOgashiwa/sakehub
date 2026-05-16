'use client';

import useSWR from 'swr';

import type { DrinkListResult, FetchDrinksParams } from '@/lib/drinks-api';
import { fetchDrinks } from '@/lib/drinks-api';

export function useDrinks(params: FetchDrinksParams, fallbackData?: DrinkListResult) {
  const key = ['drinks', params.category ?? '', params.q ?? '', params.limit, params.offset];

  return useSWR<DrinkListResult>(key, () => fetchDrinks(params), {
    fallbackData,
    keepPreviousData: true,
  });
}
