import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

import { fetchCocktailItemsServer } from '@/application/cocktails-api.server';
import { Heading } from '@/components/ui/heading';
import { createClient } from '@/lib/supabase/server';
import { loginHref } from '@/utils/login-href';
import { recipeComposePath } from '@/utils/recipe-compose-href';

import { CocktailRecipeForm } from '../cocktail-recipe-form';
import { createCocktailRecipe } from './actions';

export const metadata: Metadata = {
  title: 'アレンジレシピを投稿',
  description: '公式レシピをアレンジして投稿できます。親カクテルの指定が必要です。',
};

type PageProps = {
  searchParams: Promise<{ cocktail_id?: string }>;
};

export default async function NewCocktailRecipePage({ searchParams }: PageProps) {
  const { cocktail_id: cocktailIdRaw } = await searchParams;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect(loginHref(recipeComposePath(cocktailIdRaw)));
  }

  const cocktails = await fetchCocktailItemsServer({ limit: 200 });
  const defaultCocktailId =
    cocktailIdRaw && cocktails.some((c) => c.id === cocktailIdRaw) ? cocktailIdRaw : undefined;

  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <div className="mb-10 space-y-1">
        <Heading level="h1">
          アレンジレシピを
          <br />
          <span className="text-amber">投稿する</span>
        </Heading>
        <p className="text-muted-foreground text-sm">
          公式レシピをアレンジして投稿できます。親カクテルの指定が必要です。
        </p>
      </div>

      <CocktailRecipeForm
        mode="create"
        action={createCocktailRecipe}
        cocktails={cocktails}
        defaultCocktailId={defaultCocktailId}
      />
    </div>
  );
}
