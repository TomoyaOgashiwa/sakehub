'use client';

import { useSearchParams } from 'next/navigation';
import Link from 'next/link';

import type { DrinkListResult } from '@/application/drinks-api';
import { useDrinks } from '@/application/use-drinks';
import { SearchMissLogger } from '@/components/catalog/search-miss-logger';

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

  const { data, isLoading } = useDrinks({ category, q, limit: 20 }, fallbackData);
  const result = data ?? fallbackData;

  return (
    <div className="space-y-6">
      <div className="bg-muted/50 flex flex-col gap-2 rounded-lg px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm">
          カクテルのレシピを探すなら{' '}
          <Link href="/cocktails" className="font-medium underline-offset-4 hover:underline">
            カクテル一覧
          </Link>
        </p>
      </div>

      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <CategoryFilter />
        <div className="w-full sm:max-w-md">
          <DrinkSearch />
        </div>
      </div>

      {q && !category && !isLoading && result.total === 0 && (
        <SearchMissLogger scope="drink" query={q} total={result.total} />
      )}

      {isLoading ? <DrinkGridSkeleton /> : <DrinkGrid drinks={result.drinks} />}

      {result.total > 0 && (
        <p className="text-muted-foreground text-center text-sm">
          {result.total}件中 {result.drinks.length}件を表示
        </p>
      )}
    </div>
  );
}
