import 'server-only';

import type { CocktailRecipeRating } from '@sakehub/types';

import { toRecipeRating, type ApiRecipeRating } from './cocktail-mappers';
import { serverFetch } from './server-api';

interface ApiRatingListResponse {
  data: ApiRecipeRating[] | null;
}

/** Fetch all ratings for a cocktail recipe (public, no auth required). */
export async function fetchRatingsByRecipeId(recipeId: string): Promise<CocktailRecipeRating[]> {
  const body = await serverFetch<ApiRatingListResponse>('/api/public/cocktail-recipe-ratings', {
    params: { recipe_id: recipeId },
    next: { revalidate: 0 },
  });
  return (body.data ?? []).map(toRecipeRating);
}

/** Fetch the authenticated user's rating for a recipe. Returns null if none. */
export async function fetchMyRecipeRating(
  recipeId: string,
  accessToken: string,
): Promise<CocktailRecipeRating | null> {
  const body = await serverFetch<{ data: ApiRecipeRating | null }>(
    '/api/auth/cocktail-recipe-ratings/mine',
    {
      params: { recipe_id: recipeId },
      headers: { Authorization: `Bearer ${accessToken}` },
      next: { revalidate: 0 },
    },
  );
  return body.data ? toRecipeRating(body.data) : null;
}
