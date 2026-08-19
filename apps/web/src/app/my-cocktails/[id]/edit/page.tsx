import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { ArrowLeft } from 'lucide-react';

import {
  fetchCocktailItemsServer,
  fetchMyCocktailRecipe,
} from '@/application/cocktails-api.server';
import { getOptionalAccessToken } from '@/application/require-access-token';
import { Heading } from '@/components/ui/heading';
import { loginHref } from '@/utils/login-href';

import { CocktailRecipeForm } from '../../cocktail-recipe-form';
import { updateCocktailRecipe } from './actions';
import { DeleteDraftDialog } from './delete-draft-dialog';

export const metadata: Metadata = {
  title: 'アレンジレシピを編集',
  description: '下書きのアレンジレシピを直して投稿できます。',
};

type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function EditCocktailRecipePage({ params }: PageProps) {
  const { id } = await params;
  const { user, accessToken } = await getOptionalAccessToken();
  if (!user || !accessToken) {
    redirect(loginHref(`/my-cocktails/${id}/edit`));
  }

  const result = await fetchMyCocktailRecipe(accessToken, id);
  if (!result.ok) {
    if (result.status === 401) {
      redirect(loginHref(`/my-cocktails/${id}/edit`));
    }
    notFound();
  }

  const recipe = result.recipe;
  if (recipe.status === 'published') {
    const slug = recipe.cocktailSlug.trim();
    if (slug) {
      redirect(`/cocktails/${slug}/recipes/${recipe.id}`);
    }
    redirect('/my-cocktails');
  }

  const cocktails = await fetchCocktailItemsServer({ limit: 200 });

  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <nav aria-label="パンくずリスト" className="mb-6">
        <Link
          href="/my-cocktails"
          className="text-muted-foreground hover:text-foreground inline-flex items-center gap-1 text-sm transition-colors"
        >
          <ArrowLeft className="size-4" aria-hidden="true" />
          レシピ一覧に戻る
        </Link>
      </nav>

      <div className="mb-10 space-y-1">
        <Heading level="h1">
          アレンジレシピを
          <br />
          <span className="text-amber">編集する</span>
        </Heading>
        <p className="text-muted-foreground text-sm">
          下書きを直して投稿できます。投稿すると材料・作り方・親カクテルは変えられません。
        </p>
      </div>

      <CocktailRecipeForm
        mode="draft"
        action={updateCocktailRecipe}
        cocktails={cocktails}
        recipe={recipe}
      />

      <DeleteDraftDialog recipeId={recipe.id} />
    </div>
  );
}
