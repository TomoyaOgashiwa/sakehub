import type { Metadata } from 'next';
import { Suspense } from 'react';
import Link from 'next/link';

import { Heading } from '@/components/ui/heading';
import { CocktailGrid } from '@/components/cocktails/cocktail-grid';
import { CocktailSearch } from '@/components/cocktails/cocktail-search';
import { BaseSpiritFilter } from '@/components/cocktails/base-spirit-filter';
import { SearchMissLogger } from '@/components/catalog/search-miss-logger';
import { DrinkGridSkeleton } from '@/components/drinks/drink-card-skeleton';
import { fetchCocktailsServer } from '@/application/cocktails-api.server';
import { COCKTAIL_LIST_PAGE_SIZE } from '@/config/cocktails';

export const metadata: Metadata = {
  title: 'カクテル一覧',
  description: '名前やベースからカクテルを特定し、公式レシピを見る。',
};

export const dynamic = 'force-dynamic';

type PageProps = {
  searchParams: Promise<{
    q?: string;
    base_spirit?: string;
    offset?: string;
  }>;
};

function parseOffset(raw: string | undefined): number {
  const n = Number(raw);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}

export default function CocktailsPage({ searchParams }: PageProps) {
  return (
    <div className="mx-auto max-w-7xl px-4 py-8">
      <div className="mb-8">
        <Heading level="h1">カクテルを探す</Heading>
        <p className="text-muted-foreground mt-2">
          名前やベースからカクテルを特定する。
          <Link href="/" className="text-foreground ml-2 underline-offset-4 hover:underline">
            お酒一覧へ
          </Link>
        </p>
      </div>

      <div className="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <Suspense fallback={null}>
          <BaseSpiritFilter />
        </Suspense>
        <div className="w-full lg:max-w-md">
          <Suspense fallback={null}>
            <CocktailSearch />
          </Suspense>
        </div>
      </div>

      <Suspense fallback={<DrinkGridSkeleton />}>
        <CocktailListLoader searchParams={searchParams} />
      </Suspense>
    </div>
  );
}

async function CocktailListLoader({ searchParams }: PageProps) {
  const sp = await searchParams;
  const q = sp.q?.trim() ?? '';
  const baseSpirit = sp.base_spirit?.trim() ?? '';
  const offset = parseOffset(sp.offset);

  const result = await fetchCocktailsServer({
    q: q || undefined,
    baseSpirit: baseSpirit || undefined,
    limit: COCKTAIL_LIST_PAGE_SIZE,
    offset,
  });

  const nextOffset = offset + result.cocktails.length;
  const prevOffset = Math.max(0, offset - COCKTAIL_LIST_PAGE_SIZE);
  const hasPrev = offset > 0;
  const hasNext = nextOffset < result.total;

  function hrefFor(next: number): string {
    const params = new URLSearchParams();
    if (q) params.set('q', q);
    if (baseSpirit) params.set('base_spirit', baseSpirit);
    if (next > 0) params.set('offset', String(next));
    const qs = params.toString();
    return qs ? `/cocktails?${qs}` : '/cocktails';
  }

  return (
    <div className="space-y-6">
      {q && (
        <SearchMissLogger
          scope="cocktail"
          query={q}
          total={result.total}
          filtersActive={baseSpirit !== ''}
        />
      )}

      {result.total > 0 && (
        <p className="text-muted-foreground text-sm">
          {result.total}件中 {offset + 1}–{offset + result.cocktails.length}件を表示
        </p>
      )}

      <CocktailGrid cocktails={result.cocktails} />

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
