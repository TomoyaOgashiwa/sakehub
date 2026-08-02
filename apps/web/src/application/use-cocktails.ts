'use client';

import useSWR from 'swr';
import type { CocktailListParams } from '@sakehub/types';

import { fetchCocktails } from '@/application/cocktails-api';

/**
 * カクテルマスタ一覧を取得する。
 * enabled が false の間はフェッチしない。
 */
export function useCocktails(params: CocktailListParams = {}, enabled = true) {
  const key = enabled
    ? (['cocktails', params.q ?? '', params.baseSpirit ?? '', params.limit, params.offset] as const)
    : null;

  return useSWR(key, () => fetchCocktails(params), {
    keepPreviousData: true,
  });
}
