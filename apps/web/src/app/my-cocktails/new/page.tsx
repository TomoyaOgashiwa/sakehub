import type { Metadata } from 'next';
import { redirect } from 'next/navigation';

import { Heading } from '@/components/ui/heading';
import { createClient } from '@/lib/supabase/server';
import { fetchCocktailItemsServer } from '@/application/cocktails-api.server';

import { CocktailRecipeForm } from './cocktail-recipe-form';

export const metadata: Metadata = {
  title: '新しいレシピを登録する',
  description: 'あなたのオリジナルカクテルをライブラリに追加しましょう',
};

type PageProps = {
  searchParams: Promise<{ cocktail_id?: string }>;
};

export default async function NewCocktailRecipePage({ searchParams }: PageProps) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login');
  }

  const { cocktail_id: cocktailIdRaw } = await searchParams;
  const cocktails = await fetchCocktailItemsServer({ limit: 200 });
  const defaultCocktailId =
    cocktailIdRaw && cocktails.some((c) => c.id === cocktailIdRaw) ? cocktailIdRaw : undefined;

  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <div className="mb-10 space-y-1">
        <Heading level="h1">
          新しいレシピを
          <br />
          <span className="text-amber">登録する</span>
        </Heading>
        <p className="text-muted-foreground text-sm">
          あなたのオリジナルカクテルをライブラリに追加しましょう
        </p>
      </div>

      <CocktailRecipeForm cocktails={cocktails} defaultCocktailId={defaultCocktailId} />
    </div>
  );
}
