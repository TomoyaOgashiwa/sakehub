import Link from 'next/link';
import type { ListDepth } from '@sakehub/types';

import { drinkCategoryLabel, makerSearchHref } from '@/config/drinks';

interface ListDepthMapProps {
  depth: ListDepth;
}

export function ListDepthMap({ depth }: ListDepthMapProps) {
  if (depth.categories.length === 0) {
    return (
      <section aria-label="記録した銘柄の埋まり" className="rounded-lg border border-dashed p-4">
        <p className="text-muted-foreground mb-2 text-sm">まだ記録した銘柄がありません</p>
        <Link href="/" className="text-foreground text-sm font-medium underline">
          銘柄を探す
        </Link>
      </section>
    );
  }

  const { categories, makers, specialty } = depth;
  const makerCategory = depth.makerScope === 'specialty' ? specialty?.category : undefined;

  return (
    <section aria-label="記録した銘柄の埋まり" className="space-y-3 rounded-lg border p-4">
      <ul className="space-y-1">
        {categories.map((row) => (
          <li key={row.category} className="text-sm">
            <Link
              href={`/?category=${encodeURIComponent(row.category)}`}
              className="hover:underline"
            >
              <span className="font-medium">{drinkCategoryLabel(row.category)}</span>{' '}
              <span className="text-muted-foreground">
                {row.drank} / {row.total}
              </span>
            </Link>
          </li>
        ))}
      </ul>
      {makers.length > 0 ? (
        <ul className="space-y-2">
          {makers.map((maker) => {
            const searchHref = makerSearchHref(maker.manufacturer, makerCategory);
            return (
              <li key={maker.manufacturer} className="text-sm">
                <Link href={searchHref} className="hover:underline">
                  {maker.manufacturer} {maker.drank}種
                </Link>
                {maker.nextDrinks.length > 0 ? (
                  <ul className="text-muted-foreground mt-1 space-y-0.5 pl-3">
                    {maker.nextDrinks.map((drink) => (
                      <li key={drink.slug}>
                        <Link href={`/drinks/${drink.slug}`} className="hover:underline">
                          {drink.name}
                        </Link>
                      </li>
                    ))}
                    <li>
                      <Link href={searchHref} className="hover:underline">
                        同じ作り手の銘柄
                      </Link>
                    </li>
                  </ul>
                ) : null}
              </li>
            );
          })}
        </ul>
      ) : null}
    </section>
  );
}
