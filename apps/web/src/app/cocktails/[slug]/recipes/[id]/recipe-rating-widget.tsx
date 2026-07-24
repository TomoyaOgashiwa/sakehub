'use client';

import type { CocktailRecipeRating } from '@sakehub/types';

import { EntityRatingWidget } from '@/components/ratings/entity-rating-widget';

import { deleteRecipeRating, submitRecipeRating } from './actions';
import type { RecipeRatingState } from './actions';

interface RecipeRatingWidgetProps {
  recipeId: string;
  cocktailSlug: string;
  initialRating: CocktailRecipeRating | null;
}

const emptyState: RecipeRatingState = { ok: false, error: '' };

export function RecipeRatingWidget({
  recipeId,
  cocktailSlug,
  initialRating,
}: RecipeRatingWidgetProps) {
  return (
    <EntityRatingWidget
      initialRating={initialRating}
      commentPlaceholder="このレシピの感想を書いてください…"
      buildOptimistic={({ previous, rating, comment }) => ({
        id: previous?.id ?? '',
        recipeId,
        userId: previous?.userId ?? '',
        rating,
        comment,
        createdAt: previous?.createdAt ?? new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      })}
      onSubmit={async (rating, comment) => {
        const fd = new FormData();
        fd.set('recipe_id', recipeId);
        fd.set('cocktail_slug', cocktailSlug);
        fd.set('rating', String(rating));
        fd.set('comment', comment);
        return submitRecipeRating(emptyState, fd);
      }}
      onDelete={(id) => deleteRecipeRating(id, cocktailSlug, recipeId)}
    />
  );
}
