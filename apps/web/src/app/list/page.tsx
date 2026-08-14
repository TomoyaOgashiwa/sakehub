import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import type { DrinkCategory, SavedDrinkStatus } from '@sakehub/types';

import { getOptionalAccessToken } from '@/application/require-access-token';
import { fetchMyListDepth, fetchMySavedDrinks } from '@/application/saved-drinks-api.server';
import { ConfirmedSearchInput } from '@/components/catalog/confirmed-search-input';
import { Heading } from '@/components/ui/heading';
import { drinkCategoryLabel, isProductDrinkCategory } from '@/config/drinks';

import { ListDepthMap } from './list-depth';
import { SavedDrinkRow } from './saved-drink-row';

export const metadata: Metadata = {
  title: 'リスト',
};

type PageProps = {
  searchParams: Promise<{ q?: string; status?: string; category?: string }>;
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

export default async function ListPage({ searchParams }: PageProps) {
  const { user, accessToken } = await getOptionalAccessToken();
  if (!user || !accessToken) {
    redirect('/login?next=/list');
  }

  const sp = await searchParams;
  const q = sp.q?.trim() ?? '';
  const categoryFilter = parseListCategory(sp.category);
  const isWantView = parseStatus(sp.status) === 'want';
  const isCategoryView = categoryFilter != null && !isWantView;

  const [items, depth] = await Promise.all([
    isCategoryView
      ? fetchMySavedDrinks(accessToken, {
          limit: 100,
          category: categoryFilter,
          status: 'drank',
        })
      : isWantView
        ? fetchMySavedDrinks(accessToken, { limit: 100, status: 'want' })
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

  const activeFill =
    categoryFilter != null
      ? (depth.categories.find((row) => row.category === categoryFilter) ?? null)
      : null;
  const overviewEmpty = !isWantView && !isCategoryView && depth.categories.length === 0;

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <div className="mb-8">
        {isCategoryView || isWantView ? (
          <p className="mb-2">
            <Link href="/list" className="text-muted-foreground text-sm hover:underline">
              カテゴリ一覧へ
            </Link>
          </p>
        ) : null}
        <Heading level="h1" className="mb-2">
          {isWantView
            ? '飲みたい'
            : isCategoryView && categoryFilter
              ? drinkCategoryLabel(categoryFilter)
              : 'リスト'}
        </Heading>
        <p className="text-muted-foreground text-sm">
          {isWantView
            ? 'まだ飲んでいない銘柄'
            : isCategoryView
              ? activeFill
                ? `${activeFill.drank} / ${activeFill.total}`
                : 'このカテゴリで飲んだ銘柄'
              : 'どれをどれくらい飲んだか'}
        </p>
      </div>

      {overviewEmpty ? (
        <div className="space-y-4">
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
        <div className="space-y-6">
          {!isWantView ? (
            <ListDepthMap
              depth={depth}
              activeCategory={isCategoryView ? categoryFilter : null}
              showMakers={isCategoryView}
            />
          ) : null}

          {isWantView || isCategoryView ? (
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
                      key={item.id}
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
