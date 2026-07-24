import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { ArrowLeft, Martini } from 'lucide-react';

import { Heading } from '@/components/ui/heading';
import { Separator } from '@/components/ui/separator';
import { StarRatingDisplay } from '@/components/ui/star-rating';
import {
  fetchCocktailBySlugServer,
  fetchCocktailRecipeServer,
} from '@/application/cocktails-api.server';
import { getOptionalAccessToken } from '@/application/require-access-token';
import {
  fetchMyRecipeRating,
  fetchRatingsByRecipeId,
} from '@/application/recipe-ratings-api.server';
import { RecipeRatingWidget } from './recipe-rating-widget';

type PageProps = {
  params: Promise<{ slug: string; id: string }>;
};

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug, id } = await params;

  try {
    const [cocktail, recipe] = await Promise.all([
      fetchCocktailBySlugServer(slug),
      fetchCocktailRecipeServer(id),
    ]);
    if (recipe.cocktailId !== cocktail.id) {
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

export default async function CocktailRecipeDetailPage({ params }: PageProps) {
  const { slug, id } = await params;

  let recipe;
  try {
    const [cocktail, fetchedRecipe] = await Promise.all([
      fetchCocktailBySlugServer(slug),
      fetchCocktailRecipeServer(id),
    ]);
    if (fetchedRecipe.cocktailId !== cocktail.id) {
      notFound();
    }
    recipe = fetchedRecipe;
  } catch {
    notFound();
  }

  const { user, accessToken } = await getOptionalAccessToken();

  const [ratingsResult, myRatingResult] = await Promise.allSettled([
    fetchRatingsByRecipeId(recipe.id),
    user && accessToken ? fetchMyRecipeRating(recipe.id, accessToken) : Promise.resolve(null),
  ]);
  const ratingPage =
    ratingsResult.status === 'fulfilled' ? ratingsResult.value : { ratings: [], hasMore: false };
  const ratings = ratingPage.ratings;
  const myRating = myRatingResult.status === 'fulfilled' ? myRatingResult.value : null;

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

              {ratings.length > 0 && (
                <div className="space-y-3">
                  <Heading level="h3">みんなの評価 ({recipe.totalRatings}件)</Heading>
                  {(ratingPage.hasMore || recipe.totalRatings > ratings.length) && (
                    <p className="text-muted-foreground text-sm">
                      新しい {ratings.length} 件を表示（全 {recipe.totalRatings} 件）
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
                </div>
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
