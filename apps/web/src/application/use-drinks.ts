'use client';

import useSWR from 'swr';

import type { DrinkListResult, FetchDrinksParams } from '@/application/drinks-api';
import { fetchDrinks } from '@/application/drinks-api';
import { useDebounce } from '@/hooks/use-debounce';

export function useDrinks(params: FetchDrinksParams, fallbackData?: DrinkListResult) {
  const debouncedQ = useDebounce(params.q ?? '', 300);
  const fetchParams = {
    ...params,
    q: debouncedQ,
  } satisfies FetchDrinksParams;

  const key = ['drinks', params.category ?? '', debouncedQ, params.limit, params.offset];

  return useSWR<DrinkListResult>(key, () => fetchDrinks(fetchParams), {
    fallbackData,
    keepPreviousData: true,
  });
}
