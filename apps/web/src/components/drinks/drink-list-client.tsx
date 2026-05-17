'use client';

import { useSearchParams } from 'next/navigation';

import type { DrinkListResult } from '@/application/drinks-api';
import { useDrinks } from '@/application/use-drinks';

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
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <CategoryFilter />
        <div className="w-full sm:max-w-xs">
          <DrinkSearch />
        </div>
      </div>

      {isLoading ? <DrinkGridSkeleton /> : <DrinkGrid drinks={result.drinks} />}

      {result.total > 0 && (
        <p className="text-muted-foreground text-center text-sm">
          {result.total}件中 {result.drinks.length}件を表示
        </p>
      )}
    </div>
  );
}
