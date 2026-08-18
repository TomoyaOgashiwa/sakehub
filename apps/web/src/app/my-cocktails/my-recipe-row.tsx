import Image from 'next/image';
import Link from 'next/link';
import { Martini } from 'lucide-react';
import type { MyCocktailRecipeSummary } from '@sakehub/types';

import { Badge } from '@/components/ui/badge';

interface MyRecipeRowProps {
  recipe: MyCocktailRecipeSummary;
}

function RecipeThumb({ name, imageUrl }: { name: string; imageUrl?: string }) {
  return (
    <div className="bg-muted relative size-16 shrink-0 overflow-hidden rounded-md">
      {imageUrl ? (
        <Image src={imageUrl} alt={name} fill sizes="64px" className="object-cover" />
      ) : (
        <span className="flex size-full items-center justify-center">
          <Martini className="text-muted-foreground/40 size-7" aria-hidden="true" />
        </span>
      )}
    </div>
  );
}

function RecipeMeta({ recipe, isDraft }: { recipe: MyCocktailRecipeSummary; isDraft: boolean }) {
  return (
    <div className="min-w-0 flex-1">
      <div className="flex flex-wrap items-baseline gap-x-2 gap-y-0.5">
        {isDraft ? (
          <span className="font-medium">{recipe.name}</span>
        ) : (
          <span className="font-medium group-hover:underline">{recipe.name}</span>
        )}
        {isDraft ? <Badge variant="secondary">下書き</Badge> : null}
      </div>
      <p className="text-muted-foreground mt-0.5 text-xs">{recipe.cocktailName}</p>
    </div>
  );
}

export function MyRecipeRow({ recipe }: MyRecipeRowProps) {
  const isDraft = recipe.status !== 'published';
  // Published without slug is fail-closed: not a link (public GET would 404).
  const href =
    !isDraft && recipe.cocktailSlug
      ? `/cocktails/${recipe.cocktailSlug}/recipes/${recipe.id}`
      : null;

  const body = (
    <>
      <RecipeThumb name={recipe.name} imageUrl={recipe.imageUrl} />
      <RecipeMeta recipe={recipe} isDraft={isDraft} />
    </>
  );

  if (href) {
    return (
      <li>
        <Link
          href={href}
          className="group focus-visible:ring-ring/50 flex items-start gap-3 rounded-lg border p-3 outline-none focus-visible:ring-3"
        >
          {body}
        </Link>
      </li>
    );
  }

  return <li className="flex items-start gap-3 rounded-lg border p-3">{body}</li>;
}
