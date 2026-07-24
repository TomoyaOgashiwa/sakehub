'use client';

import useSWR from 'swr';

import { fetchCocktails } from '@/application/cocktails-api';

/**
 * カクテルマスタ一覧を取得する。
 * enabled が false の間はフェッチしない（カテゴリ未選択時の無駄な取得を防ぐ）。
 */
export function useCocktails(enabled = true) {
  return useSWR(enabled ? ['cocktails'] : null, () => fetchCocktails(), {
    keepPreviousData: true,
  });
}
