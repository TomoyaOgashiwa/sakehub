import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { ArrowLeft, Martini } from 'lucide-react';

import { Badge } from '@/components/ui/badge';
import { Heading } from '@/components/ui/heading';
import { Separator } from '@/components/ui/separator';
import { StarRatingDisplay } from '@/components/ui/star-rating';
import { fetchCocktailBySlugServer } from '@/application/cocktails-api.server';

type PageProps = {
  params: Promise<{ slug: string }>;
};

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;

  try {
    const cocktail = await fetchCocktailBySlugServer(slug);
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

export default async function CocktailDetailPage({ params }: PageProps) {
  const { slug } = await params;

  let cocktail;
  try {
    cocktail = await fetchCocktailBySlugServer(slug);
  } catch {
    notFound();
  }

  return (
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

        <Separator className="mb-8" />

        <section aria-labelledby="recipes-heading" className="space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <Heading level="h2" id="recipes-heading">
              みんなのレシピ ({cocktail.recipeCount}件)
            </Heading>
            <Link
              href="/my-cocktails/new"
              className="text-muted-foreground hover:text-foreground text-sm underline underline-offset-2 transition-colors"
            >
              レシピを投稿する
            </Link>
          </div>

          {cocktail.recipes.length === 0 ? (
            <div className="rounded-lg border border-dashed p-8 text-center">
              <p className="text-muted-foreground text-sm">
                まだレシピがありません。最初のレシピを投稿してみましょう。
              </p>
            </div>
          ) : (
            <ul className="grid grid-cols-1 gap-4 sm:grid-cols-2" role="list">
              {cocktail.recipes.map((recipe) => (
                <li key={recipe.id}>
                  <Link
                    href={`/cocktails/${cocktail.slug}/recipes/${recipe.id}`}
                    className="group block h-full"
                  >
                    <div className="hover:bg-muted/40 flex h-full flex-col gap-2 rounded-xl border p-4 transition-colors">
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
                      {recipe.memo && (
                        <p className="text-muted-foreground line-clamp-2 text-sm">{recipe.memo}</p>
                      )}
                      <p className="text-muted-foreground mt-auto text-xs">
                        評価 {recipe.totalRatings}件
                        {recipe.averageRating > 0 && ` ・ 平均 ${recipe.averageRating.toFixed(1)}`}
                      </p>
                    </div>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </section>
      </article>
    </div>
  );
}
