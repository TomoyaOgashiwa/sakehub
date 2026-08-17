'use client';

import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';

import type { DrinkListSort, SavedDrinkStatus } from '@sakehub/types';

import type { DrinkListResult } from '@/application/drinks-api';
import { useDrinks } from '@/application/use-drinks';
import { SearchMissLogger } from '@/components/catalog/search-miss-logger';
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { DRINK_LIST_PAGE_SIZE } from '@/config/drinks';
import {
  isCategoryFilterActive,
  isDrinkListPaged,
  parseDrinkListSort,
  parseOffset,
} from '@/utils/drink-list-query';
import { savedDrinkStatusLabel } from '@/utils/saved-drink-status';
import { cn } from '@/utils/utils';

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

const DRINK_LIST_SORT_ITEMS = [
  { value: 'newest', label: '新着' },
  { value: 'abv_desc', label: '度数が高い順' },
  { value: 'abv_asc', label: '度数が低い順' },
] as const satisfies ReadonlyArray<{ value: DrinkListSort; label: string }>;

export function DrinkListClient({
  fallbackData,
  recentSaves,
  isAuthenticated = false,
}: DrinkListClientProps) {
  const router = useRouter();
  const searchParams = useSearchParams();

  const category = searchParams.get('category') ?? '';
  const q = searchParams.get('q') ?? '';
  const sort = parseDrinkListSort(searchParams.get('sort'));
  const categoryFilterActive = isCategoryFilterActive(category);
  const paged = isDrinkListPaged({ q, category, sort });
  const offset = paged ? parseOffset(searchParams.get('offset')) : 0;

  const { data, isLoading, isValidating } = useDrinks(
    { category, q, sort, limit: DRINK_LIST_PAGE_SIZE, offset },
    fallbackData,
  );
  const result = data ?? fallbackData;
  const missLogReady = !isLoading && !isValidating;

  const nextOffset = offset + result.drinks.length;
  const prevOffset = Math.max(0, offset - DRINK_LIST_PAGE_SIZE);
  const hasPrev = paged && offset > 0;
  const hasNext = paged && nextOffset < result.total;

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

  function handleSortChange(next: DrinkListSort) {
    const params = new URLSearchParams(searchParams.toString());
    if (next === 'newest') {
      params.delete('sort');
    } else {
      params.set('sort', next);
    }
    params.delete('offset');
    const qs = params.toString();
    router.push(qs ? `/?${qs}` : '/', { scroll: false });
  }

  return (
    <div className="space-y-6">
      <div className="w-full sm:max-w-md">
        <DrinkSearch />
      </div>

      <CategoryFilter />

      {q && (
        <SearchMissLogger
          scope="drink"
          query={q}
          total={result.total}
          filtersActive={categoryFilterActive}
          ready={missLogReady}
        />
      )}

      <div
        className={cn(
          'flex items-center gap-4',
          result.total > 0 ? 'justify-between' : 'justify-end',
        )}
      >
        {result.total > 0 && (
          <p className="text-muted-foreground text-sm">
            {paged
              ? `${result.total}件中 ${offset + 1}–${offset + result.drinks.length}件を表示`
              : `${result.total}件中 ${result.drinks.length}件を表示`}
          </p>
        )}
        <DrinkListSortSelect value={sort} onValueChange={handleSortChange} />
      </div>

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
    </div>
  );
}

function DrinkListSortSelect({
  value,
  onValueChange,
}: {
  value: DrinkListSort;
  onValueChange: (value: DrinkListSort) => void;
}) {
  return (
    <Select
      items={DRINK_LIST_SORT_ITEMS}
      value={value}
      onValueChange={(next) => {
        if (typeof next !== 'string') return;
        onValueChange(parseDrinkListSort(next));
      }}
    >
      <SelectTrigger size="sm" className="min-w-40" aria-label="並び順">
        <SelectValue />
      </SelectTrigger>
      <SelectContent align="end">
        <SelectGroup>
          {DRINK_LIST_SORT_ITEMS.map((item) => (
            <SelectItem key={item.value} value={item.value}>
              {item.label}
            </SelectItem>
          ))}
        </SelectGroup>
      </SelectContent>
    </Select>
  );
}
