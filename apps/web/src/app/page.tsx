import { Suspense } from 'react';

import { JsonLd } from '@/components/json-ld';
import { DrinkListClient } from '@/components/drinks/drink-list-client';
import { DrinkGridSkeleton } from '@/components/drinks/drink-card-skeleton';
import { Heading } from '@/components/ui/heading';
import { fetchDrinksServer } from '@/application/drinks-api.server';

export const dynamic = 'force-dynamic';

export default function Home() {
  return (
    <>
      {/*
        SEO: Schema.org の WebSite 構造化データ（JSON-LD）を埋め込む。
        検索エンジンがサイト名・説明・検索 URL を機械可読に解釈でき、
        サイトリンク検索ボックス等のリッチリザルト表示につながりやすい。
      */}
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
          <Heading level="h1">Discover Spirits</Heading>
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
