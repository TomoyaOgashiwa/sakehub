'use client';

import { useSearchParams } from 'next/navigation';

import type { DrinkListResult } from '@/application/drinks-api';
import { useDrinks } from '@/application/use-drinks';
import { useCocktails } from '@/application/use-cocktails';
import { CocktailGrid } from '@/components/cocktails/cocktail-grid';

import { CategoryFilter } from './category-filter';
import { DrinkSearch } from './drink-search';
import { DrinkGrid } from './drink-grid';
import { DrinkGridSkeleton } from './drink-card-skeleton';

interface DrinkListClientProps {
  fallbackData: DrinkListResult;
}

export function DrinkListClient({ fallbackData }: DrinkListClientProps) {
  const searchParams = useSearchParams();

  const category = searchParams.get('category') ?? '';
  const q = searchParams.get('q') ?? '';

  // 暫定導線: drinks カテゴリ UI に cocktail マスタ一覧を載せている。
  // 本来は別ドメインなので、将来は /cocktails ルートへ分離する。
  const isCocktail = category === 'cocktail';

  const { data, isLoading } = useDrinks({ category, q, limit: 20 }, fallbackData, !isCocktail);
  const { data: cocktails, isLoading: isCocktailsLoading } = useCocktails(isCocktail);

  const result = data ?? fallbackData;

  // カクテルマスタは件数が少ないため検索はクライアント側で絞り込む
  const filteredCocktails = (cocktails ?? []).filter((c) => {
    if (!q) return true;
    const needle = q.toLowerCase();
    return (
      c.name.toLowerCase().includes(needle) || (c.nameEn ?? '').toLowerCase().includes(needle)
    );
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <CategoryFilter />
        <div className="w-full sm:max-w-xs">
          <DrinkSearch />
        </div>
      </div>

      {isCocktail ? (
        isCocktailsLoading && !cocktails ? (
          <DrinkGridSkeleton />
        ) : (
          <CocktailGrid cocktails={filteredCocktails} />
        )
      ) : isLoading ? (
        <DrinkGridSkeleton />
      ) : (
        <DrinkGrid drinks={result.drinks} />
      )}

      {isCocktail ? (
        filteredCocktails.length > 0 && (
          <p className="text-muted-foreground text-center text-sm">
            {filteredCocktails.length}件のカクテルを表示
          </p>
        )
      ) : (
        result.total > 0 && (
          <p className="text-muted-foreground text-center text-sm">
            {result.total}件中 {result.drinks.length}件を表示
          </p>
        )
      )}
    </div>
  );
}
