'use server';

import type { CocktailRecipeRating } from '@sakehub/types';

import { toRecipeRating, type ApiRecipeRating } from '@/application/cocktail-mappers';
import {
  cocktailRecipeRevalidatePath,
  deleteEntityRating,
  upsertEntityRating,
  type RatingActionState,
} from '@/application/rating-action-helpers';

export type RecipeRatingState = RatingActionState<CocktailRecipeRating>;

export async function submitRecipeRating(
  _prevState: RecipeRatingState,
  formData: FormData,
): Promise<RecipeRatingState> {
  return upsertEntityRating<ApiRecipeRating, CocktailRecipeRating>({
    formData,
    entityIdField: 'recipe_id',
    missingIdError: 'recipe_id が見つかりません。',
    upsertPath: '/api/auth/cocktail-recipe-ratings',
    bodyKey: 'recipe_id',
    resolveRevalidatePath: (recipeId, fd) => {
      const slug = ((fd.get('cocktail_slug') as string | null) ?? '').trim();
      return cocktailRecipeRevalidatePath(slug, recipeId);
    },
    mapResponse: toRecipeRating,
  });
}

export async function deleteRecipeRating(
  ratingId: string,
  cocktailSlug: string,
  recipeId: string,
): Promise<RecipeRatingState> {
  return deleteEntityRating<CocktailRecipeRating>({
    ratingId,
    deletePath: `/api/auth/cocktail-recipe-ratings/${encodeURIComponent(ratingId)}`,
    pathToRevalidate: cocktailRecipeRevalidatePath(cocktailSlug, recipeId),
  });
}
