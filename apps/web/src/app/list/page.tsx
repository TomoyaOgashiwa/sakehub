import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import type { SavedDrinkStatus } from '@sakehub/types';

import { getOptionalAccessToken } from '@/application/require-access-token';
import { fetchMyListDepth, fetchMySavedDrinks } from '@/application/saved-drinks-api.server';
import { ConfirmedSearchInput } from '@/components/catalog/confirmed-search-input';
import { Heading } from '@/components/ui/heading';
import { cn } from '@/utils/utils';

import { ListDepthMap } from './list-depth';
import { SavedDrinkRow } from './saved-drink-row';

export const metadata: Metadata = {
  title: 'リスト',
};

type PageProps = {
  searchParams: Promise<{ q?: string; status?: string }>;
};

function parseStatus(raw: string | undefined): SavedDrinkStatus | null {
  if (raw === 'drank' || raw === 'want') return raw;
  return null;
}

function listHref(status: SavedDrinkStatus | null, q: string): string {
  const params = new URLSearchParams();
  if (status) params.set('status', status);
  if (q) params.set('q', q);
  const qs = params.toString();
  return qs ? `/list?${qs}` : '/list';
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
  const statusFilter = parseStatus(sp.status);
  const [items, depth] = await Promise.all([
    fetchMySavedDrinks(accessToken, { limit: 100 }),
    fetchMyListDepth(accessToken),
  ]);

  const filtered = items.filter((item) => {
    if (!item.drink) return false;
    if (statusFilter && item.status !== statusFilter) return false;
    if (q && !matchesQuery(item, q.toLowerCase())) return false;
    return true;
  });

  const filters: { key: SavedDrinkStatus | null; label: string }[] = [
    { key: null, label: 'すべて' },
    { key: 'drank', label: '飲んだ' },
    { key: 'want', label: '飲みたい' },
  ];

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <div className="mb-8">
        <Heading level="h1" className="mb-2">
          リスト
        </Heading>
        <p className="text-muted-foreground text-sm">記録した銘柄の埋まりを見返す</p>
      </div>

      {items.length === 0 && depth.categories.length === 0 ? (
        <div className="rounded-lg border border-dashed p-8 text-center">
          <p className="text-muted-foreground mb-3 text-sm">まだリストに銘柄がありません</p>
          <Link href="/" className="text-foreground text-sm font-medium underline">
            銘柄を探す
          </Link>
        </div>
      ) : (
        <div className="space-y-6">
          <ListDepthMap depth={depth} />

          {items.length === 0 ? (
            <div className="rounded-lg border border-dashed p-8 text-center">
              <p className="text-muted-foreground mb-3 text-sm">まだリストに銘柄がありません</p>
              <Link href="/" className="text-foreground text-sm font-medium underline">
                銘柄を探す
              </Link>
            </div>
          ) : null}

          {items.length > 0 ? (
            <>
              <div className="w-full sm:max-w-md">
                <ConfirmedSearchInput
                  pathname="/list"
                  placeholder="名前やメモで探す"
                  ariaLabel="リスト内を検索"
                />
              </div>

              <nav aria-label="意図で絞る" className="flex flex-wrap gap-2">
                {filters.map((filter) => {
                  const active = statusFilter === filter.key;
                  return (
                    <Link
                      key={filter.label}
                      href={listHref(filter.key, q)}
                      className={cn(
                        'rounded-full border px-3 py-1 text-sm',
                        active
                          ? 'bg-foreground text-background border-foreground'
                          : 'text-muted-foreground hover:text-foreground border-border',
                      )}
                      aria-current={active ? 'page' : undefined}
                    >
                      {filter.label}
                    </Link>
                  );
                })}
              </nav>

              {filtered.length === 0 ? (
                <div className="rounded-lg border border-dashed p-8 text-center">
                  <p className="text-muted-foreground mb-3 text-sm">
                    リストに一致する銘柄がありません
                  </p>
                  <Link
                    href={q ? `/?q=${encodeURIComponent(q)}` : '/'}
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
                      specialtyCategory={
                        depth.makerScope === 'specialty' ? depth.specialty?.category : undefined
                      }
                    />
                  ))}
                </ul>
              )}
            </>
          ) : null}
        </div>
      )}
    </div>
  );
}
