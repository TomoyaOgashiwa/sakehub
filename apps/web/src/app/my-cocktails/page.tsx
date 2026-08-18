import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';

import { fetchMyCocktailRecipes } from '@/application/cocktails-api.server';
import { getOptionalAccessToken } from '@/application/require-access-token';
import { buttonVariants } from '@/components/ui/button';
import { Heading } from '@/components/ui/heading';
import { MY_COCKTAIL_RECIPE_PAGE_SIZE } from '@/config/cocktails';

import { MyRecipeRow } from './my-recipe-row';

export const metadata: Metadata = {
  title: 'カクテルレシピ',
};

type PageProps = {
  searchParams: Promise<{ offset?: string }>;
};

function parseOffset(raw: string | undefined): number {
  const n = Number(raw);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}

function myCocktailsHref(offset: number): string {
  if (offset <= 0) return '/my-cocktails';
  return `/my-cocktails?offset=${offset}`;
}

function ComposeRecipeLink() {
  return (
    <Link href="/my-cocktails/new" className={buttonVariants()}>
      レシピを投稿
    </Link>
  );
}

export default async function MyCocktailsPage({ searchParams }: PageProps) {
  const { user, accessToken } = await getOptionalAccessToken();
  if (!user || !accessToken) {
    redirect('/login?next=/my-cocktails');
  }

  const sp = await searchParams;
  const offset = parseOffset(sp.offset);
  const result = await fetchMyCocktailRecipes(accessToken, {
    limit: MY_COCKTAIL_RECIPE_PAGE_SIZE,
    offset,
  });

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <div className="mb-8 flex flex-wrap items-start justify-between gap-4">
        <div>
          <Heading level="h1">カクテルレシピ</Heading>
          <p className="text-muted-foreground mt-2 text-sm">下書きと公開したアレンジ</p>
        </div>
        {result && result.total > 0 ? <ComposeRecipeLink /> : null}
      </div>

      {result == null ? (
        <div className="rounded-lg border border-dashed p-8 text-center" role="alert">
          <p className="text-muted-foreground mb-3 text-sm">レシピを読み込めませんでした</p>
          <Link href="/my-cocktails" className="text-foreground text-sm font-medium underline">
            再試行
          </Link>
        </div>
      ) : result.total === 0 ? (
        <div className="rounded-lg border border-dashed p-8 text-center">
          <p className="text-muted-foreground mb-3 text-sm">
            アレンジレシピを投稿できます。親カクテルの指定が必要です。
          </p>
          <ComposeRecipeLink />
        </div>
      ) : (
        <div className="flex flex-col gap-6">
          <ul className="flex flex-col gap-3">
            {result.recipes.map((recipe) => (
              <MyRecipeRow key={recipe.id} recipe={recipe} />
            ))}
          </ul>
          <MyRecipePagination
            total={result.total}
            offset={offset}
            count={result.recipes.length}
            pageSize={result.limit || MY_COCKTAIL_RECIPE_PAGE_SIZE}
          />
        </div>
      )}
    </div>
  );
}

function MyRecipePagination({
  total,
  offset,
  count,
  pageSize,
}: {
  total: number;
  offset: number;
  count: number;
  pageSize: number;
}) {
  if (total <= pageSize) return null;

  const nextOffset = offset + count;
  const prevOffset = Math.max(0, offset - pageSize);
  const hasPrev = offset > 0;
  const hasNext = nextOffset < total;

  return (
    <nav aria-label="ページネーション" className="flex justify-center gap-4">
      {hasPrev ? (
        <Link
          href={myCocktailsHref(prevOffset)}
          className="text-sm font-medium underline-offset-4 hover:underline"
        >
          前へ
        </Link>
      ) : (
        <span className="text-muted-foreground text-sm">前へ</span>
      )}
      {hasNext ? (
        <Link
          href={myCocktailsHref(nextOffset)}
          className="text-sm font-medium underline-offset-4 hover:underline"
        >
          次へ
        </Link>
      ) : (
        <span className="text-muted-foreground text-sm">次へ</span>
      )}
    </nav>
  );
}
