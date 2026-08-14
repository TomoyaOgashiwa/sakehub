import { Suspense } from 'react';

import { fetchDrinksServer } from '@/application/drinks-api.server';
import { getOptionalAccessToken } from '@/application/require-access-token';
import { fetchMySavedDrinks } from '@/application/saved-drinks-api.server';
import { DrinkGridSkeleton } from '@/components/drinks/drink-card-skeleton';
import { DrinkListClient } from '@/components/drinks/drink-list-client';
import { JsonLd } from '@/components/json-ld';
import { Heading } from '@/components/ui/heading';
import { DRINK_LIST_PAGE_SIZE } from '@/config/drinks';

export const dynamic = 'force-dynamic';

type PageProps = {
  searchParams: Promise<{
    q?: string;
    category?: string;
    offset?: string;
  }>;
};

function parseOffset(raw: string | undefined): number {
  const n = Number(raw);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}

export default function Home({ searchParams }: PageProps) {
  return (
    <>
      <JsonLd
        data={{
          '@context': 'https://schema.org',
          '@type': 'WebSite',
          name: 'SakeHub',
          url: 'https://sakehub.com',
          description: 'ラベルや名前の手がかりから、商品単位で銘柄を探す。',
          potentialAction: {
            '@type': 'SearchAction',
            target: 'https://sakehub.com/?q={search_term_string}',
            'query-input': 'required name=search_term_string',
          },
        }}
      />
      <div className="mx-auto max-w-7xl px-4 py-8">
        <div className="mb-8">
          <Heading level="h1">銘柄を特定する</Heading>
          <p className="text-muted-foreground mt-2">ラベルや名前の手がかりから、商品単位で探す</p>
        </div>
        <Suspense fallback={<DrinkGridSkeleton />}>
          <DrinkListLoader searchParams={searchParams} />
        </Suspense>
      </div>
    </>
  );
}

async function DrinkListLoader({ searchParams }: PageProps) {
  const sp = await searchParams;
  const q = sp.q?.trim() ?? '';
  const category = sp.category?.trim() ?? '';
  const filtered = Boolean(q || (category && category !== 'all'));
  const offset = filtered ? parseOffset(sp.offset) : 0;

  const { user, accessToken } = await getOptionalAccessToken();
  const [result, saved] = await Promise.all([
    fetchDrinksServer({
      q: q || undefined,
      category: category && category !== 'all' ? category : undefined,
      limit: DRINK_LIST_PAGE_SIZE,
      offset,
    }),
    user && accessToken ? fetchMySavedDrinks(accessToken, { limit: 8 }) : Promise.resolve([]),
  ]);

  const recentSaves = saved.flatMap((item) => {
    if (!item.drink) return [];
    const href =
      item.drink.visibility === 'provisional' ? '/list?pending=1' : `/drinks/${item.drink.slug}`;
    return [{ drinkId: item.drink.id, name: item.drink.name, status: item.status, href }];
  });

  return (
    <DrinkListClient
      fallbackData={result}
      recentSaves={recentSaves.length > 0 ? recentSaves : undefined}
      isAuthenticated={Boolean(user)}
    />
  );
}
