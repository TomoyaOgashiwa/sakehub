import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';

import { getOptionalAccessToken } from '@/application/require-access-token';
import { fetchMySavedDrinks } from '@/application/saved-drinks-api.server';
import { Heading } from '@/components/ui/heading';
import { StarRatingDisplay } from '@/components/ui/star-rating';

import { UnsaveDrinkButton } from './unsave-drink-button';

export const metadata: Metadata = {
  title: 'リスト',
};

export default async function ListPage() {
  const { user, accessToken } = await getOptionalAccessToken();
  if (!user || !accessToken) {
    redirect('/login?next=/list');
  }

  const items = await fetchMySavedDrinks(accessToken);

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <div className="mb-8">
        <Heading level="h1" className="mb-2">
          リスト
        </Heading>
        <p className="text-muted-foreground text-sm">残した銘柄を見返せます。</p>
      </div>

      {items.length === 0 ? (
        <div className="rounded-lg border border-dashed p-8 text-center">
          <p className="text-muted-foreground mb-3 text-sm">まだリストに銘柄がありません</p>
          <Link href="/" className="text-foreground text-sm font-medium underline">
            銘柄を探す
          </Link>
        </div>
      ) : (
        <ul className="flex flex-col gap-3">
          {items.map((item) => {
            const drink = item.drink;
            if (!drink) return null;
            return (
              <li
                key={item.id}
                className="flex items-start justify-between gap-3 rounded-lg border p-3"
              >
                <div className="min-w-0 space-y-1">
                  <Link href={`/drinks/${drink.slug}`} className="font-medium hover:underline">
                    {drink.name}
                  </Link>
                  {item.rating != null && (
                    <StarRatingDisplay value={item.rating} size="sm" showValue={false} />
                  )}
                </div>
                <UnsaveDrinkButton drinkId={item.drinkId} drinkSlug={drink.slug} />
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
