import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { Hourglass } from 'lucide-react';
import type { DrinkCategory, SavedDrinkStatus } from '@sakehub/types';

import { getOptionalAccessToken } from '@/application/require-access-token';
import { fetchMyListDepth, fetchMySavedDrinks } from '@/application/saved-drinks-api.server';
import { ConfirmedSearchInput } from '@/components/catalog/confirmed-search-input';
import { Card, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Heading } from '@/components/ui/heading';
import { drinkCategoryLabel, isProductDrinkCategory } from '@/config/drinks';

import { DrinkCategoryGlyph, ListDepthMap } from './list-depth';
import { SavedDrinkRow } from './saved-drink-row';

export const metadata: Metadata = {
  title: 'リスト',
};

type PageProps = {
  searchParams: Promise<{ q?: string; status?: string; category?: string; pending?: string }>;
};

function parseStatus(raw: string | undefined): SavedDrinkStatus | null {
  if (raw === 'drank' || raw === 'want') return raw;
  return null;
}

function parseListCategory(raw: string | undefined): Exclude<DrinkCategory, 'all'> | null {
  if (!isProductDrinkCategory(raw)) return null;
  return raw;
}

function matchesQuery(
  item: { drink?: { name: string; nameEn?: string }; note: string },
  q: string,
) {
  const haystack = [item.drink?.name, item.drink?.nameEn, item.note]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();
  return haystack.includes(q);
}

function PendingGlyph() {
  return (
    <span
      className="bg-drink-pending text-drink-pending-foreground flex size-8 items-center justify-center rounded-lg [&>svg]:size-4"
      aria-hidden="true"
    >
      <Hourglass />
    </span>
  );
}

function PendingCountLink({ count }: { count: number }) {
  if (count <= 0) return null;
  return (
    <Link
      href="/list?pending=1"
      className="group focus-visible:ring-ring/50 block rounded-xl outline-none focus-visible:ring-3"
    >
      <Card className="border-border border border-dashed ring-0 transition-shadow group-hover:shadow-md">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <PendingGlyph />
            図鑑待ち {count}
          </CardTitle>
          <CardDescription>図鑑待ちのマスは分数に入れていません</CardDescription>
        </CardHeader>
      </Card>
    </Link>
  );
}

export default async function ListPage({ searchParams }: PageProps) {
  const { user, accessToken } = await getOptionalAccessToken();
  if (!user || !accessToken) {
    redirect('/login?next=/list');
  }

  const sp = await searchParams;
  const q = sp.q?.trim() ?? '';
  const categoryFilter = parseListCategory(sp.category);
  const isWantView = parseStatus(sp.status) === 'want';
  const isPendingView = sp.pending === '1' && !isWantView;
  const isCategoryView = categoryFilter != null && !isWantView && !isPendingView;
  const isOverview = !isWantView && !isPendingView && !isCategoryView;

  const [items, depth] = await Promise.all([
    isCategoryView
      ? fetchMySavedDrinks(accessToken, {
          limit: 100,
          category: categoryFilter,
          union: 'drank',
        })
      : isWantView
        ? fetchMySavedDrinks(accessToken, { limit: 100, status: 'want' })
        : isPendingView
          ? fetchMySavedDrinks(accessToken, { limit: 100, visibility: 'provisional' })
          : Promise.resolve([]),
    fetchMyListDepth(
      accessToken,
      isCategoryView && categoryFilter ? { category: categoryFilter } : undefined,
    ),
  ]);

  const filtered = items.filter((item) => {
    if (!item.drink) return false;
    if (q && !matchesQuery(item, q.toLowerCase())) return false;
    return true;
  });

  const depthFailed = depth === null;
  const provisionalCount = depth?.provisionalCount ?? 0;
  const activeFill =
    categoryFilter != null && depth
      ? (depth.categories.find((row) => row.category === categoryFilter) ?? null)
      : null;
  const overviewEmpty =
    !depthFailed && isOverview && depth.categories.length === 0 && provisionalCount === 0;
  const showRows = isWantView || isCategoryView || isPendingView;

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <div className="mb-8">
        {isCategoryView || isWantView || isPendingView ? (
          <p className="mb-2">
            <Link href="/list" className="text-muted-foreground text-sm hover:underline">
              カテゴリ一覧へ
            </Link>
          </p>
        ) : null}
        <Heading
          level="h1"
          className={
            (isCategoryView && categoryFilter) || isPendingView
              ? 'mb-2 flex items-center gap-3'
              : 'mb-2'
          }
        >
          {isCategoryView && categoryFilter ? (
            <DrinkCategoryGlyph category={categoryFilter} />
          ) : isPendingView ? (
            <PendingGlyph />
          ) : null}
          {isWantView
            ? '飲みたい'
            : isPendingView
              ? '図鑑待ち'
              : isCategoryView && categoryFilter
                ? drinkCategoryLabel(categoryFilter)
                : 'リスト'}
        </Heading>
        <p className="text-muted-foreground text-sm">
          {isWantView
            ? 'まだ飲んでいない銘柄'
            : isPendingView
              ? '図鑑にまだ無いマス'
              : isCategoryView
                ? activeFill
                  ? `${activeFill.drank} / ${activeFill.total}`
                  : 'このカテゴリで飲んだ銘柄'
                : 'どれをどれくらい飲んだか'}
        </p>
      </div>

      {overviewEmpty ? (
        <div className="flex flex-col gap-4">
          <div className="rounded-lg border border-dashed p-8 text-center">
            <p className="text-muted-foreground mb-3 text-sm">まだ記録した銘柄がありません</p>
            <Link href="/" className="text-foreground text-sm font-medium underline">
              銘柄を探す
            </Link>
          </div>
          <p>
            <Link
              href="/list?status=want"
              className="text-muted-foreground text-sm hover:underline"
            >
              飲みたいを見る
            </Link>
          </p>
        </div>
      ) : (
        <div className="flex flex-col gap-6">
          {depthFailed && !isWantView && !isPendingView ? (
            <section
              aria-label="記録した銘柄の埋まり"
              className="rounded-lg border border-dashed p-4"
              role="alert"
            >
              <p className="text-muted-foreground mb-2 text-sm">深さを読み込めませんでした</p>
              <Link href="/list" className="text-foreground text-sm font-medium underline">
                再試行
              </Link>
            </section>
          ) : null}

          {!isWantView && !isPendingView && depth && depth.categories.length > 0 ? (
            <ListDepthMap
              depth={depth}
              activeCategory={isCategoryView ? categoryFilter : null}
              showMakers={isCategoryView}
            />
          ) : null}

          {isOverview ? <PendingCountLink count={provisionalCount} /> : null}

          {showRows ? (
            <>
              <div className="w-full sm:max-w-md">
                <ConfirmedSearchInput
                  pathname="/list"
                  placeholder="名前やメモで探す"
                  ariaLabel="リスト内を検索"
                />
              </div>

              {filtered.length === 0 ? (
                <div className="rounded-lg border border-dashed p-8 text-center">
                  <p className="text-muted-foreground mb-3 text-sm">
                    {q
                      ? 'リストに一致する銘柄がありません'
                      : isWantView
                        ? '飲みたい銘柄はまだありません'
                        : isPendingView
                          ? '図鑑待ちのマスはありません'
                          : 'このカテゴリで飲んだ銘柄はまだありません'}
                  </p>
                  <Link
                    href={
                      q
                        ? `/?q=${encodeURIComponent(q)}`
                        : categoryFilter
                          ? `/?category=${encodeURIComponent(categoryFilter)}`
                          : '/'
                    }
                    className="text-foreground text-sm font-medium underline"
                  >
                    カタログで探す
                  </Link>
                </div>
              ) : (
                <ul className="flex flex-col gap-3">
                  {filtered.map((item) => (
                    <SavedDrinkRow
                      key={item.id || item.drinkId}
                      item={item}
                      specialtyCategory={categoryFilter ?? undefined}
                    />
                  ))}
                </ul>
              )}
            </>
          ) : (
            <p>
              <Link
                href="/list?status=want"
                className="text-muted-foreground text-sm hover:underline"
              >
                飲みたいを見る
              </Link>
            </p>
          )}
        </div>
      )}
    </div>
  );
}
