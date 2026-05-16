import { Suspense } from 'react';

import { JsonLd } from '@/components/json-ld';
import { DrinkListClient } from '@/components/drinks/drink-list-client';
import { DrinkGridSkeleton } from '@/components/drinks/drink-card-skeleton';
import { fetchDrinksServer } from '@/lib/drinks-api.server';

export const dynamic = 'force-dynamic';

export default function Home() {
  return (
    <>
      <JsonLd
        data={{
          '@context': 'https://schema.org',
          '@type': 'WebSite',
          name: 'SakeHub',
          url: 'https://sakehub.com',
          description:
            'Explore, review, and share your favorite spirits. From whisky to sake, beer to cocktails.',
          potentialAction: {
            '@type': 'SearchAction',
            target: 'https://sakehub.com/?q={search_term_string}',
            'query-input': 'required name=search_term_string',
          },
        }}
      />
      <div className="mx-auto max-w-7xl px-4 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold tracking-tight">Discover Spirits</h1>
          <p className="text-muted-foreground mt-2">
            お気に入りのお酒を見つけて、レビューを共有しましょう
          </p>
        </div>
        <Suspense fallback={<DrinkGridSkeleton />}>
          <DrinkListLoader />
        </Suspense>
      </div>
    </>
  );
}

async function DrinkListLoader() {
  const result = await fetchDrinksServer({ limit: 20 });
  return <DrinkListClient fallbackData={result} />;
}
