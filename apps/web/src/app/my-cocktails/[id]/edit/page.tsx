import type { CocktailRecipe } from '@sakehub/types';
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
import { updateCocktailRecipe, updatePublishedCocktailRecipe } from './actions';
import { DeleteDraftDialog } from './delete-draft-dialog';

type PageProps = {
  params: Promise<{ id: string }>;
};

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { id } = await params;
  const { accessToken } = await getOptionalAccessToken();
  if (!accessToken) {
    return { title: 'アレンジレシピを編集' };
  }

  const result = await fetchMyCocktailRecipe(accessToken, id);
  if (result.ok && result.recipe.status === 'published') {
    return {
      title: '名前・画像を編集',
      description: '公開したレシピの名前・写真・コツを直せます。',
    };
  }

  return {
    title: 'アレンジレシピを編集',
    description: '下書きのアレンジレシピを直して投稿できます。',
  };
}

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
  const published = recipe.status === 'published';

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
          {published ? '名前・画像を' : 'アレンジレシピを'}
          <br />
          <span className="text-amber">編集する</span>
        </Heading>
        <p className="text-muted-foreground text-sm">
          {published
            ? '名前・写真・コツを直せます。材料と作り方は公開後は変更できません。'
            : '下書きを直して投稿できます。投稿すると材料・作り方・親カクテルは変えられません。'}
        </p>
      </div>

      {published ? (
        <CocktailRecipeForm
          key={recipe.id}
          mode="published"
          action={updatePublishedCocktailRecipe}
          recipe={recipe}
        />
      ) : (
        <DraftEditForm recipe={recipe} />
      )}
    </div>
  );
}

async function DraftEditForm({ recipe }: { recipe: CocktailRecipe }) {
  const cocktails = await fetchCocktailItemsServer({ limit: 200 });

  return (
    <>
      <CocktailRecipeForm
        key={recipe.id}
        mode="draft"
        action={updateCocktailRecipe}
        cocktails={cocktails}
        recipe={recipe}
      />
      <DeleteDraftDialog recipeId={recipe.id} />
    </>
  );
}
