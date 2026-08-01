import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { ArrowLeft, Martini } from 'lucide-react';

import { Badge } from '@/components/ui/badge';
import { Heading } from '@/components/ui/heading';
import { Separator } from '@/components/ui/separator';
import { StarRatingDisplay } from '@/components/ui/star-rating';
import { JsonLd } from '@/components/json-ld';
import { fetchCocktailBySlugServer } from '@/application/cocktails-api.server';
import { buildRecipeJsonLd } from '@/utils/recipe-json-ld';

const RECIPE_PAGE_SIZE = 50;

type PageProps = {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ recipes_offset?: string }>;
};

function parseOffset(raw: string | undefined): number {
  const n = Number(raw);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;

  try {
    // Metadata only needs master fields; skip recipe page payload.
    const cocktail = await fetchCocktailBySlugServer(slug, { limit: 1, offset: 0 });
    const title = cocktail.nameEn ? `${cocktail.name} (${cocktail.nameEn})` : cocktail.name;

    return {
      title,
      description: cocktail.description,
      openGraph: {
        title: `${title} | SakeHub`,
        description: cocktail.description,
        type: 'article',
        ...(cocktail.imageUrl && { images: [{ url: cocktail.imageUrl }] }),
      },
    };
  } catch {
    return { title: 'カクテルが見つかりません' };
  }
}

export default async function CocktailDetailPage({ params, searchParams }: PageProps) {
  const { slug } = await params;
  const { recipes_offset: recipesOffsetRaw } = await searchParams;
  const recipesOffset = parseOffset(recipesOffsetRaw);

  let cocktail;
  try {
    cocktail = await fetchCocktailBySlugServer(slug, {
      limit: RECIPE_PAGE_SIZE,
      offset: recipesOffset,
    });
  } catch {
    notFound();
  }

  const nextRecipesOffset = recipesOffset + cocktail.recipes.length;
  const prevRecipesOffset = Math.max(0, recipesOffset - RECIPE_PAGE_SIZE);
  const official = cocktail.officialRecipe;

  return (
    <>
      {official && <JsonLd data={buildRecipeJsonLd(official)} />}

      <div className="mx-auto max-w-4xl px-4 py-8">
        <nav aria-label="パンくずリスト" className="mb-6">
          <Link
            href="/?category=cocktail"
            className="text-muted-foreground hover:text-foreground inline-flex items-center gap-1 text-sm transition-colors"
          >
            <ArrowLeft className="size-4" aria-hidden="true" />
            カクテル一覧に戻る
          </Link>
        </nav>

        <article>
          <header className="mb-8">
            <div className="flex flex-wrap items-start gap-3">
              <Heading level="h1">{cocktail.name}</Heading>
              {cocktail.baseSpirit && (
                <Badge variant="outline" className="mt-1 capitalize">
                  {cocktail.baseSpirit}
                </Badge>
              )}
            </div>
            {cocktail.nameEn && (
              <p className="text-muted-foreground mt-1 text-lg">{cocktail.nameEn}</p>
            )}
          </header>

          <div className="mb-8 flex flex-col gap-6 sm:flex-row">
            <figure className="bg-muted flex w-full shrink-0 items-center justify-center overflow-hidden rounded-xl sm:w-56">
              {cocktail.imageUrl ? (
                <div className="relative aspect-square w-full">
                  <Image
                    src={cocktail.imageUrl}
                    alt={cocktail.name}
                    fill
                    sizes="224px"
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

            <div className="space-y-4">
              <p className="text-foreground/90 leading-relaxed">{cocktail.description}</p>
              <dl className="text-muted-foreground flex flex-wrap gap-x-6 gap-y-2 text-sm">
                {cocktail.abv != null && (
                  <div className="flex gap-2">
                    <dt>アルコール度数</dt>
                    <dd className="text-foreground font-medium">{cocktail.abv}%</dd>
                  </div>
                )}
                {cocktail.originCountry && (
                  <div className="flex gap-2">
                    <dt>発祥</dt>
                    <dd className="text-foreground font-medium">{cocktail.originCountry}</dd>
                  </div>
                )}
                <div className="flex gap-2">
                  <dt>投稿レシピ</dt>
                  <dd className="text-foreground font-medium">{cocktail.recipeCount}件</dd>
                </div>
              </dl>
            </div>
          </div>

          {official && (
            <section aria-labelledby="official-recipe-heading" className="mb-8 space-y-6">
              <div className="flex flex-wrap items-center gap-3">
                <Heading level="h2" id="official-recipe-heading">
                  基本レシピ
                </Heading>
                <Badge>公式</Badge>
              </div>

              <div className="space-y-3">
                <Heading level="h3">材料</Heading>
                <ul className="divide-y rounded-xl border" role="list">
                  {official.ingredients.map((ingredient) => (
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
              </div>

              {official.steps.length > 0 && (
                <div className="space-y-3">
                  <Heading level="h3">作り方</Heading>
                  <ol className="space-y-3" role="list">
                    {official.steps.map((step, idx) => (
                      <li key={step.id} className="flex gap-3 text-sm">
                        <span
                          className="bg-muted text-muted-foreground flex size-7 shrink-0 items-center justify-center rounded-full text-xs font-medium tabular-nums"
                          aria-hidden="true"
                        >
                          {idx + 1}
                        </span>
                        <p className="text-foreground/90 leading-relaxed pt-1">{step.body}</p>
                      </li>
                    ))}
                  </ol>
                </div>
              )}

              {official.memo && (
                <div className="space-y-2">
                  <Heading level="h3">コツ・ポイント</Heading>
                  <p className="text-foreground/90 leading-relaxed whitespace-pre-wrap text-sm">
                    {official.memo}
                  </p>
                </div>
              )}

              <p>
                <Link
                  href={`/my-cocktails/new?cocktail_id=${cocktail.id}`}
                  className="text-foreground text-sm font-medium underline underline-offset-2"
                >
                  このレシピをアレンジして投稿する
                </Link>
              </p>
            </section>
          )}

          <Separator className="mb-8" />

          <section aria-labelledby="recipes-heading" className="space-y-4">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <Heading level="h2" id="recipes-heading">
                みんなのレシピ ({cocktail.recipeCount}件)
              </Heading>
              <Link
                href={`/my-cocktails/new?cocktail_id=${cocktail.id}`}
                className="text-muted-foreground hover:text-foreground text-sm underline underline-offset-2 transition-colors"
              >
                レシピを投稿する
              </Link>
            </div>

            {cocktail.recipes.length === 0 ? (
              <div className="rounded-lg border border-dashed p-8 text-center">
                <p className="text-muted-foreground text-sm">
                  {recipesOffset > 0
                    ? 'このページにはレシピがありません。'
                    : 'まだレシピがありません。最初のレシピを投稿してみましょう。'}
                </p>
                {recipesOffset > 0 && (
                  <Link
                    href={`/cocktails/${cocktail.slug}`}
                    className="text-foreground mt-3 inline-block text-sm underline underline-offset-2"
                  >
                    最初のページへ戻る
                  </Link>
                )}
              </div>
            ) : (
              <>
                {(cocktail.hasMoreRecipes ||
                  cocktail.recipeCount > cocktail.recipes.length ||
                  recipesOffset > 0) && (
                  <p className="text-muted-foreground text-sm">
                    {recipesOffset + 1}〜{recipesOffset + cocktail.recipes.length} 件を表示（全{' '}
                    {cocktail.recipeCount} 件）
                  </p>
                )}
                <ul className="grid grid-cols-1 gap-4 sm:grid-cols-2" role="list">
                  {cocktail.recipes.map((recipe) => (
                    <li key={recipe.id}>
                      <Link
                        href={`/cocktails/${cocktail.slug}/recipes/${recipe.id}`}
                        className="group block h-full"
                      >
                        <div className="hover:bg-muted/40 flex h-full flex-col overflow-hidden rounded-xl border transition-colors">
                          <div className="bg-muted relative aspect-[4/3] w-full overflow-hidden">
                            {recipe.imageUrl ? (
                              <Image
                                src={recipe.imageUrl}
                                alt={recipe.name}
                                fill
                                sizes="(max-width: 640px) 100vw, 50vw"
                                className="object-cover transition-transform group-hover:scale-[1.02]"
                              />
                            ) : (
                              <div className="from-muted to-muted-foreground/10 flex h-full items-center justify-center bg-gradient-to-br">
                                <Martini
                                  className="text-muted-foreground/40 size-10"
                                  aria-hidden="true"
                                />
                              </div>
                            )}
                          </div>
                          <div className="flex flex-1 flex-col gap-2 p-4">
                            <div className="flex items-start justify-between gap-2">
                              <p className="text-foreground font-medium group-hover:underline">
                                {recipe.name}
                              </p>
                              {recipe.averageRating > 0 && (
                                <StarRatingDisplay
                                  value={recipe.averageRating}
                                  size="sm"
                                  showValue={false}
                                  className="shrink-0 gap-0.5"
                                />
                              )}
                            </div>
                            {recipe.authorName && (
                              <p className="text-muted-foreground text-xs">{recipe.authorName}</p>
                            )}
                            {recipe.memo && (
                              <p className="text-muted-foreground line-clamp-2 text-sm">
                                {recipe.memo}
                              </p>
                            )}
                            <p className="text-muted-foreground mt-auto text-xs">
                              評価 {recipe.totalRatings}件
                              {recipe.averageRating > 0 &&
                                ` ・ 平均 ${recipe.averageRating.toFixed(1)}`}
                            </p>
                          </div>
                        </div>
                      </Link>
                    </li>
                  ))}
                </ul>
                <div className="flex flex-wrap gap-3">
                  {recipesOffset > 0 && (
                    <Link
                      href={
                        prevRecipesOffset === 0
                          ? `/cocktails/${cocktail.slug}`
                          : `/cocktails/${cocktail.slug}?recipes_offset=${prevRecipesOffset}`
                      }
                      className="text-muted-foreground hover:text-foreground text-sm underline underline-offset-2"
                    >
                      前のレシピ
                    </Link>
                  )}
                  {cocktail.hasMoreRecipes && (
                    <Link
                      href={`/cocktails/${cocktail.slug}?recipes_offset=${nextRecipesOffset}`}
                      className="text-foreground text-sm font-medium underline underline-offset-2"
                    >
                      もっと見る
                    </Link>
                  )}
                </div>
              </>
            )}
          </section>
        </article>
      </div>
    </>
  );
}
