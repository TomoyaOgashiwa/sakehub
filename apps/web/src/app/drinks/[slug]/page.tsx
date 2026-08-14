import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { ArrowLeft, Wine } from 'lucide-react';

import { Badge } from '@/components/ui/badge';
import { Heading } from '@/components/ui/heading';
import { Separator } from '@/components/ui/separator';
import { StarRatingDisplay } from '@/components/ui/star-rating';
import { JsonLd } from '@/components/json-ld';
import { fetchCocktailBridgePreview } from '@/application/cocktails-api.server';
import { fetchDrinkBySlugServer } from '@/application/drinks-api.server';
import { getOptionalAccessToken } from '@/application/require-access-token';
import { fetchMySavedDrink } from '@/application/saved-drinks-api.server';
import { fetchMyReview, fetchReviewsByDrinkId } from '@/application/reviews-api.server';
import { BaseCocktailPreview } from '@/components/cocktails/base-cocktail-preview';
import {
  baseSpiritForDrinkCategory,
  cocktailsByBaseSpiritHref,
} from '@/config/drink-cocktail-bridge';
import { getCatalogImageSourceLabel } from '@/utils/catalog-image-source-label';
import { DrinkReviewWidget } from './drink-review-widget';

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

  const { user, accessToken } = await getOptionalAccessToken();
  const baseSpirit = baseSpiritForDrinkCategory(drink.category);

  const [reviews, myReview, mySaved, bridgeCocktails] = await Promise.all([
    fetchReviewsByDrinkId(drink.id),
    user && accessToken ? fetchMyReview(drink.id, accessToken) : Promise.resolve(null),
    user && accessToken ? fetchMySavedDrink(drink.id, accessToken) : Promise.resolve(null),
    baseSpirit ? fetchCocktailBridgePreview(baseSpirit) : Promise.resolve([]),
  ]);

  const displayName = drink.nameEn ? `${drink.name} (${drink.nameEn})` : drink.name;
  const imageSourceLabel = getCatalogImageSourceLabel(drink.imageSource);

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
              <Heading level="h1">{drink.name}</Heading>
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
                <Heading level="h2" id="description-heading" className="sr-only">
                  説明
                </Heading>
                <p className="text-foreground/90 leading-relaxed">{drink.description}</p>
              </section>

              <Separator />

              <section aria-labelledby="personal-list-heading" className="space-y-4">
                <Heading level="h2" id="personal-list-heading" className="sr-only">
                  リスト
                </Heading>
                {user ? (
                  <div className="bg-muted/40 rounded-xl border p-4">
                    <DrinkReviewWidget
                      key={`${mySaved?.id ?? 'unsaved'}-${mySaved?.status ?? 'none'}-${myReview?.updatedAt ?? 'none'}`}
                      drinkId={drink.id}
                      drinkSlug={slug}
                      initialSaved={mySaved != null}
                      initialStatus={mySaved?.status ?? null}
                      initialNote={mySaved?.note ?? ''}
                      initialReview={myReview}
                    />
                  </div>
                ) : (
                  <div className="bg-muted/40 rounded-xl border p-4">
                    <Link
                      href={`/login?next=${encodeURIComponent(`/drinks/${slug}`)}`}
                      className="bg-primary text-primary-foreground hover:bg-primary/90 inline-flex h-9 items-center rounded-md px-4 text-sm font-medium"
                    >
                      ログインして残す
                    </Link>
                  </div>
                )}
              </section>

              {baseSpirit && bridgeCocktails.length > 0 ? (
                <>
                  <Separator />
                  <BaseCocktailPreview
                    heading="このベースで作れる"
                    headingId="base-cocktails-heading"
                    description={`${baseSpirit} ベースの公式カクテル`}
                    cocktails={bridgeCocktails}
                    moreHref={cocktailsByBaseSpiritHref(baseSpirit)}
                  />
                </>
              ) : null}

              <Separator />

              <section aria-labelledby="reviews-heading" className="space-y-6">
                <div className="flex flex-wrap items-center gap-4">
                  <Heading level="h2" id="reviews-heading">
                    評価
                  </Heading>
                  <StarRatingDisplay
                    value={drink.averageRating}
                    count={drink.totalReviews}
                    size="md"
                  />
                </div>

                {reviews.length > 0 && (
                  <div className="space-y-3">
                    <Heading level="h3">みんなの評価 ({reviews.length}件)</Heading>
                    <div className="space-y-2">
                      {reviews.map((review) => (
                        <div
                          key={review.id}
                          className="flex items-start gap-3 rounded-lg border p-3 text-sm"
                        >
                          <StarRatingDisplay value={review.rating} size="sm" showValue={false} />
                          <span className="text-foreground font-medium tabular-nums">
                            {review.rating}.0
                          </span>
                          {review.comment && (
                            <p className="text-muted-foreground flex-1">{review.comment}</p>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </section>
            </div>

            <aside>
              <div className="sticky top-8 space-y-6">
                <figure className="bg-muted overflow-hidden rounded-xl">
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
                  {imageSourceLabel && (
                    <figcaption className="flex justify-end px-3 py-2">
                      <Badge variant={imageSourceLabel.variant}>{imageSourceLabel.text}</Badge>
                    </figcaption>
                  )}
                </figure>

                <section aria-labelledby="details-heading">
                  <Heading level="h2" id="details-heading" className="mb-3">
                    基本情報
                  </Heading>
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
                    <div className="flex flex-col gap-1">
                      <dt className="text-muted-foreground">評価</dt>
                      <dd>
                        <StarRatingDisplay
                          value={drink.averageRating}
                          count={drink.totalReviews}
                          size="sm"
                        />
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
