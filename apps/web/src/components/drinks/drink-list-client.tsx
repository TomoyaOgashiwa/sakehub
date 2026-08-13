'use client';

import Link from 'next/link';
import { useSearchParams } from 'next/navigation';

import type { SavedDrinkStatus } from '@sakehub/types';

import type { DrinkListResult } from '@/application/drinks-api';
import { useDrinks } from '@/application/use-drinks';
import { SearchMissLogger } from '@/components/catalog/search-miss-logger';
import { DRINK_LIST_PAGE_SIZE } from '@/config/drinks';
import { savedDrinkStatusLabel } from '@/utils/saved-drink-status';

import { CategoryFilter } from './category-filter';
import { DrinkGrid } from './drink-grid';
import { DrinkGridSkeleton } from './drink-card-skeleton';
import { DrinkSearch } from './drink-search';
import { SearchZeroExit } from './search-zero-exit';

interface RecentSave {
  drinkId: string;
  name: string;
  status: SavedDrinkStatus;
  href: string;
}

interface DrinkListClientProps {
  fallbackData: DrinkListResult;
  recentSaves?: RecentSave[];
  isAuthenticated?: boolean;
}

function parseOffset(raw: string | null): number {
  const n = Number(raw);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}

export function DrinkListClient({
  fallbackData,
  recentSaves,
  isAuthenticated = false,
}: DrinkListClientProps) {
  const searchParams = useSearchParams();

  const category = searchParams.get('category') ?? '';
  const q = searchParams.get('q') ?? '';
  const categoryFilterActive = category !== '' && category !== 'all';
  const filtered = Boolean(q || categoryFilterActive);
  const offset = filtered ? parseOffset(searchParams.get('offset')) : 0;

  const { data, isLoading, isValidating } = useDrinks(
    { category, q, limit: DRINK_LIST_PAGE_SIZE, offset },
    fallbackData,
  );
  const result = data ?? fallbackData;
  const missLogReady = !isLoading && !isValidating;

  const nextOffset = offset + result.drinks.length;
  const prevOffset = Math.max(0, offset - DRINK_LIST_PAGE_SIZE);
  const hasPrev = filtered && offset > 0;
  const hasNext = filtered && nextOffset < result.total;

  function hrefFor(next: number): string {
    const params = new URLSearchParams(searchParams.toString());
    if (next > 0) {
      params.set('offset', String(next));
    } else {
      params.delete('offset');
    }
    const qs = params.toString();
    return qs ? `/?${qs}` : '/';
  }

  return (
    <div className="space-y-6">
      <div className="w-full sm:max-w-md">
        <DrinkSearch />
      </div>

      <CategoryFilter />

      {recentSaves && recentSaves.length > 0 && (
        <section aria-labelledby="recent-saves-heading" className="space-y-2">
          <h2 id="recent-saves-heading" className="text-muted-foreground text-sm font-medium">
            最近残した
          </h2>
          <ul className="flex flex-wrap gap-x-4 gap-y-1 text-sm">
            {recentSaves.map((item) => (
              <li key={item.drinkId}>
                <Link href={item.href} className="hover:underline">
                  {item.name}（{savedDrinkStatusLabel(item.status)}）
                </Link>
              </li>
            ))}
          </ul>
        </section>
      )}

      {q && (
        <SearchMissLogger
          scope="drink"
          query={q}
          total={result.total}
          filtersActive={categoryFilterActive}
          ready={missLogReady}
        />
      )}

      {isLoading ? (
        <DrinkGridSkeleton />
      ) : result.drinks.length === 0 && q && !categoryFilterActive ? (
        <SearchZeroExit
          query={q}
          suggestions={result.suggestions ?? []}
          isAuthenticated={isAuthenticated}
        />
      ) : (
        <DrinkGrid drinks={result.drinks} />
      )}

      {result.total > 0 && (
        <p className="text-muted-foreground text-center text-sm">
          {filtered
            ? `${result.total}件中 ${offset + 1}–${offset + result.drinks.length}件を表示`
            : `${result.total}件中 ${result.drinks.length}件を表示`}
        </p>
      )}

      {(hasPrev || hasNext) && (
        <nav aria-label="ページネーション" className="flex justify-center gap-4">
          {hasPrev ? (
            <Link
              href={hrefFor(prevOffset)}
              className="text-sm font-medium underline-offset-4 hover:underline"
            >
              前へ
            </Link>
          ) : (
            <span className="text-muted-foreground text-sm">前へ</span>
          )}
          {hasNext ? (
            <Link
              href={hrefFor(nextOffset)}
              className="text-sm font-medium underline-offset-4 hover:underline"
            >
              次へ
            </Link>
          ) : (
            <span className="text-muted-foreground text-sm">次へ</span>
          )}
        </nav>
      )}
    </div>
  );
}
