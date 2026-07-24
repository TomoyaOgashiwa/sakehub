import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { ArrowLeft, Martini } from 'lucide-react';

import { Heading } from '@/components/ui/heading';
import { Separator } from '@/components/ui/separator';
import { StarRatingDisplay } from '@/components/ui/star-rating';
import { fetchCocktailRecipeServer } from '@/application/cocktails-api.server';
import { getOptionalAccessToken } from '@/application/require-access-token';
import {
  fetchMyRecipeRating,
  fetchRatingsByRecipeId,
} from '@/application/recipe-ratings-api.server';
import { RecipeRatingWidget } from './recipe-rating-widget';

const RATING_PAGE_SIZE = 20;

type PageProps = {
  params: Promise<{ slug: string; id: string }>;
  searchParams: Promise<{ ratings_offset?: string }>;
};

function parseOffset(raw: string | undefined): number {
  const n = Number(raw);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug, id } = await params;

  try {
    const recipe = await fetchCocktailRecipeServer(id);
    if (recipe.cocktailSlug !== slug) {
      return { title: 'レシピが見つかりません' };
    }
    return {
      title: recipe.name,
      description: recipe.memo ?? `${recipe.name} のレシピと評価`,
    };
  } catch {
    return { title: 'レシピが見つかりません' };
  }
}

export default async function CocktailRecipeDetailPage({ params, searchParams }: PageProps) {
  const { slug, id } = await params;
  const { ratings_offset: ratingsOffsetRaw } = await searchParams;
  const ratingsOffset = parseOffset(ratingsOffsetRaw);

  let recipe;
  try {
    recipe = await fetchCocktailRecipeServer(id);
    if (recipe.cocktailSlug !== slug) {
      notFound();
    }
  } catch {
    notFound();
  }

  const { user, accessToken } = await getOptionalAccessToken();

  let ratingPage: Awaited<ReturnType<typeof fetchRatingsByRecipeId>>;
  let ratingsLoadFailed = false;
  try {
    ratingPage = await fetchRatingsByRecipeId(recipe.id, {
      limit: RATING_PAGE_SIZE,
      offset: ratingsOffset,
    });
  } catch {
    ratingPage = { ratings: [], hasMore: false };
    ratingsLoadFailed = true;
  }

  let myRating = null;
  if (user && accessToken) {
    try {
      myRating = await fetchMyRecipeRating(recipe.id, accessToken);
    } catch {
      myRating = null;
    }
  }

  const ratings = ratingPage.ratings;
  const nextRatingsOffset = ratingsOffset + ratings.length;
  const prevRatingsOffset = Math.max(0, ratingsOffset - RATING_PAGE_SIZE);

  return (
    <div className="mx-auto max-w-4xl px-4 py-8">
      <nav aria-label="パンくずリスト" className="mb-6">
        <Link
          href={`/cocktails/${slug}`}
          className="text-muted-foreground hover:text-foreground inline-flex items-center gap-1 text-sm transition-colors"
        >
          <ArrowLeft className="size-4" aria-hidden="true" />
          レシピ一覧に戻る
        </Link>
      </nav>

      <article>
        <header className="mb-8">
          <Heading level="h1">{recipe.name}</Heading>
          {recipe.averageRating > 0 && (
            <div className="mt-2">
              <StarRatingDisplay
                value={recipe.averageRating}
                count={recipe.totalRatings}
                size="md"
              />
            </div>
          )}
        </header>

        <div className="grid gap-8 md:grid-cols-[1fr_300px]">
          <div className="space-y-8">
            {recipe.memo && (
              <section aria-labelledby="memo-heading">
                <Heading level="h2" id="memo-heading" className="sr-only">
                  メモ
                </Heading>
                <p className="text-foreground/90 leading-relaxed whitespace-pre-wrap">
                  {recipe.memo}
                </p>
              </section>
            )}

            <section aria-labelledby="ingredients-heading" className="space-y-3">
              <Heading level="h2" id="ingredients-heading">
                材料
              </Heading>
              <ul className="divide-y rounded-xl border" role="list">
                {recipe.ingredients.map((ingredient) => (
                  <li
                    key={ingredient.id}
                    className="flex items-center justify-between px-4 py-2.5 text-sm"
                  >
                    <span className="text-foreground">{ingredient.name}</span>
                    <span className="text-muted-foreground tabular-nums">
                      {ingredient.amount != null
                        ? `${ingredient.amount} ${ingredient.unit ?? ''}`.trim()
                        : '適量'}
                    </span>
                  </li>
                ))}
              </ul>
            </section>

            <Separator />

            <section aria-labelledby="ratings-heading" className="space-y-6">
              <div className="flex flex-wrap items-center gap-4">
                <Heading level="h2" id="ratings-heading">
                  評価
                </Heading>
                <StarRatingDisplay
                  value={recipe.averageRating}
                  count={recipe.totalRatings}
                  size="md"
                />
              </div>

              {user ? (
                <div className="bg-muted/40 rounded-xl border p-4">
                  <RecipeRatingWidget
                    key={myRating?.updatedAt ?? 'none'}
                    recipeId={recipe.id}
                    cocktailSlug={slug}
                    initialRating={myRating}
                  />
                </div>
              ) : (
                <div className="bg-muted/40 rounded-xl border p-4">
                  <p className="text-muted-foreground text-sm">
                    <Link href="/login" className="text-foreground font-medium underline">
                      ログイン
                    </Link>
                    すると星評価を付けられます
                  </p>
                </div>
              )}

              {ratingsLoadFailed ? (
                <p className="text-destructive text-sm" role="alert">
                  評価一覧を取得できませんでした。しばらくしてから再読み込みしてください。
                </p>
              ) : (
                ratings.length > 0 && (
                  <div className="space-y-3">
                    <Heading level="h3">みんなの評価 ({recipe.totalRatings}件)</Heading>
                    {(ratingPage.hasMore ||
                      recipe.totalRatings > ratings.length ||
                      ratingsOffset > 0) && (
                      <p className="text-muted-foreground text-sm">
                        {ratingsOffset + 1}〜{ratingsOffset + ratings.length} 件を表示（全{' '}
                        {recipe.totalRatings} 件）
                      </p>
                    )}
                    <div className="space-y-2">
                      {ratings.map((rating) => (
                        <div
                          key={rating.id}
                          className="flex items-start gap-3 rounded-lg border p-3 text-sm"
                        >
                          <StarRatingDisplay value={rating.rating} size="sm" showValue={false} />
                          <span className="text-foreground font-medium tabular-nums">
                            {rating.rating}.0
                          </span>
                          {rating.comment && (
                            <p className="text-muted-foreground flex-1">{rating.comment}</p>
                          )}
                        </div>
                      ))}
                    </div>
                    <div className="flex flex-wrap gap-3">
                      {ratingsOffset > 0 && (
                        <Link
                          href={
                            prevRatingsOffset === 0
                              ? `/cocktails/${slug}/recipes/${id}`
                              : `/cocktails/${slug}/recipes/${id}?ratings_offset=${prevRatingsOffset}`
                          }
                          className="text-muted-foreground hover:text-foreground text-sm underline underline-offset-2"
                        >
                          前の評価
                        </Link>
                      )}
                      {ratingPage.hasMore && (
                        <Link
                          href={`/cocktails/${slug}/recipes/${id}?ratings_offset=${nextRatingsOffset}`}
                          className="text-foreground text-sm font-medium underline underline-offset-2"
                        >
                          もっと見る
                        </Link>
                      )}
                    </div>
                  </div>
                )
              )}
            </section>
          </div>

          <aside>
            <div className="sticky top-8 space-y-6">
              <figure className="bg-muted flex items-center justify-center overflow-hidden rounded-xl">
                {recipe.imageUrl ? (
                  <div className="relative aspect-square w-full">
                    <Image
                      src={recipe.imageUrl}
                      alt={recipe.name}
                      fill
                      sizes="300px"
                      className="object-cover"
                      priority
                    />
                  </div>
                ) : (
                  <div className="from-muted to-muted-foreground/10 flex aspect-square w-full items-center justify-center bg-gradient-to-br">
                    <Martini className="text-muted-foreground/40 size-16" aria-hidden="true" />
                  </div>
                )}
              </figure>

              <section aria-labelledby="details-heading">
                <Heading level="h2" id="details-heading" className="mb-3">
                  基本情報
                </Heading>
                <dl className="space-y-3 text-sm">
                  <div className="flex justify-between">
                    <dt className="text-muted-foreground">材料数</dt>
                    <dd className="font-medium">{recipe.ingredients.length}品</dd>
                  </div>
                  <Separator />
                  <div className="flex flex-col gap-1">
                    <dt className="text-muted-foreground">評価</dt>
                    <dd>
                      <StarRatingDisplay
                        value={recipe.averageRating}
                        count={recipe.totalRatings}
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
  );
}
