'use client';

import { useState } from 'react';
import useSWR from 'swr';

import type { DrinkListSort } from '@sakehub/types';

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

  // SWR の keepPreviousData は cache が空のとき laggyDataRef（前キー）を返す。
  // sort 変更直後に true へ戻すと、新しい RSC fallback より古い並びが勝つ。
  // 新しい sort の fetch が成功するまでオフのままにする。
  const [committedSort, setCommittedSort] = useState<DrinkListSort>(sort);

  return useSWR<DrinkListResult>(key, () => fetchDrinks(params), {
    fallbackData,
    keepPreviousData: committedSort === sort,
    onSuccess() {
      setCommittedSort(sort);
    },
  });
}
