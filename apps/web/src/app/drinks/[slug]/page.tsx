import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { ArrowLeft, Wine } from 'lucide-react';

import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { JsonLd } from '@/components/json-ld';
import { fetchDrinkBySlugServer } from '@/application/drinks-api.server';

type PageProps = {
  params: Promise<{ slug: string }>;
};

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;

  try {
    const drink = await fetchDrinkBySlugServer(slug);
    const title = drink.nameEn ? `${drink.name} (${drink.nameEn})` : drink.name;

    return {
      title,
      description: drink.description,
      openGraph: {
        title: `${title} | SakeHub`,
        description: drink.description,
        type: 'article',
        ...(drink.imageUrl && { images: [{ url: drink.imageUrl }] }),
      },
    };
  } catch {
    return { title: 'お酒が見つかりません' };
  }
}

export default async function DrinkDetailPage({ params }: PageProps) {
  const { slug } = await params;

  let drink;
  try {
    drink = await fetchDrinkBySlugServer(slug);
  } catch {
    notFound();
  }

  const displayName = drink.nameEn ? `${drink.name} (${drink.nameEn})` : drink.name;

  return (
    <>
      <JsonLd
        data={{
          '@context': 'https://schema.org',
          '@type': 'Product',
          name: drink.name,
          description: drink.description,
          category: drink.category,
          ...(drink.imageUrl && { image: drink.imageUrl }),
          ...(drink.manufacturer && {
            brand: {
              '@type': 'Brand',
              name: drink.manufacturer,
            },
          }),
          ...(drink.averageRating > 0 && {
            aggregateRating: {
              '@type': 'AggregateRating',
              ratingValue: drink.averageRating,
              bestRating: 5,
              ratingCount: drink.totalReviews,
            },
          }),
        }}
      />

      <div className="mx-auto max-w-4xl px-4 py-8">
        <nav aria-label="パンくずリスト" className="mb-6">
          <Link
            href="/"
            className="text-muted-foreground hover:text-foreground inline-flex items-center gap-1 text-sm transition-colors"
          >
            <ArrowLeft className="size-4" aria-hidden="true" />
            お酒一覧に戻る
          </Link>
        </nav>

        <article>
          <header className="mb-8">
            <div className="flex flex-wrap items-start gap-3">
              <h1 className="text-3xl font-bold tracking-tight">{drink.name}</h1>
              <Badge variant="outline" className="mt-1 capitalize">
                {drink.category}
              </Badge>
              {drink.subcategory && (
                <Badge variant="secondary" className="mt-1">
                  {drink.subcategory}
                </Badge>
              )}
            </div>
            {drink.nameEn && <p className="text-muted-foreground mt-1 text-lg">{drink.nameEn}</p>}
          </header>

          <div className="grid gap-8 md:grid-cols-[1fr_300px]">
            <div className="space-y-8">
              <section aria-labelledby="description-heading">
                <h2 id="description-heading" className="sr-only">
                  説明
                </h2>
                <p className="text-foreground/90 leading-relaxed">{drink.description}</p>
              </section>

              <Separator />

              {/* Reviews section placeholder */}
              <section aria-labelledby="reviews-heading" className="space-y-4">
                <h2 id="reviews-heading" className="text-xl font-semibold">
                  レビュー
                </h2>
                <div className="rounded-lg border border-dashed p-8 text-center">
                  <p className="text-muted-foreground text-sm">レビュー機能は近日公開予定です</p>
                </div>
              </section>

              <Separator />

              {/* Flavor profile placeholder */}
              <section aria-labelledby="flavor-heading" className="space-y-4">
                <h2 id="flavor-heading" className="text-xl font-semibold">
                  フレーバープロファイル
                </h2>
                <div className="rounded-lg border border-dashed p-8 text-center">
                  <p className="text-muted-foreground text-sm">
                    フレーバー評価機能は近日公開予定です
                  </p>
                </div>
              </section>
            </div>

            <aside>
              <div className="sticky top-8 space-y-6">
                <figure className="bg-muted flex items-center justify-center overflow-hidden rounded-xl">
                  {drink.imageUrl ? (
                    <div className="relative aspect-square w-full">
                      <Image
                        src={drink.imageUrl}
                        alt={displayName}
                        fill
                        sizes="300px"
                        className="object-cover"
                        priority
                      />
                    </div>
                  ) : (
                    <div className="from-muted to-muted-foreground/10 flex aspect-square w-full items-center justify-center bg-gradient-to-br">
                      <Wine className="text-muted-foreground/40 size-16" aria-hidden="true" />
                    </div>
                  )}
                </figure>

                <section aria-labelledby="details-heading">
                  <h2 id="details-heading" className="mb-3 text-lg font-semibold">
                    基本情報
                  </h2>
                  <dl className="space-y-3 text-sm">
                    {drink.abv != null && (
                      <div className="flex justify-between">
                        <dt className="text-muted-foreground">アルコール度数</dt>
                        <dd className="font-medium">{drink.abv}%</dd>
                      </div>
                    )}
                    {drink.originCountry && (
                      <div className="flex justify-between">
                        <dt className="text-muted-foreground">原産国</dt>
                        <dd className="font-medium">{drink.originCountry}</dd>
                      </div>
                    )}
                    {drink.manufacturer && (
                      <div className="flex justify-between">
                        <dt className="text-muted-foreground">製造者</dt>
                        <dd className="font-medium">{drink.manufacturer}</dd>
                      </div>
                    )}
                    {drink.subcategory && (
                      <div className="flex justify-between">
                        <dt className="text-muted-foreground">サブカテゴリ</dt>
                        <dd className="font-medium">{drink.subcategory}</dd>
                      </div>
                    )}
                    <Separator />
                    <div className="flex justify-between">
                      <dt className="text-muted-foreground">評価</dt>
                      <dd className="font-medium">
                        {drink.averageRating > 0
                          ? `${'★'} ${drink.averageRating.toFixed(1)} (${drink.totalReviews}件)`
                          : 'まだ評価がありません'}
                      </dd>
                    </div>
                  </dl>
                </section>
              </div>
            </aside>
          </div>
        </article>
      </div>
    </>
  );
}
