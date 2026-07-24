import 'server-only';

import type { CocktailRecipeRating } from '@sakehub/types';

import { toRecipeRating, type ApiRecipeRating } from './cocktail-mappers';
import { serverFetch } from './server-api';

interface ApiRatingListResponse {
  data: ApiRecipeRating[] | null;
  has_more?: boolean;
}

export interface RecipeRatingListResult {
  ratings: CocktailRecipeRating[];
  hasMore: boolean;
}

interface FetchRatingsOptions {
  limit?: number;
  offset?: number;
}

/** Fetch a page of ratings for a cocktail recipe (public, no auth required). */
export async function fetchRatingsByRecipeId(
  recipeId: string,
  options: FetchRatingsOptions = {},
): Promise<RecipeRatingListResult> {
  const params: Record<string, string> = { recipe_id: recipeId };
  if (options.limit != null) params.limit = String(options.limit);
  if (options.offset != null) params.offset = String(options.offset);

  const body = await serverFetch<ApiRatingListResponse>('/api/public/cocktail-recipe-ratings', {
    params,
    next: { revalidate: 0 },
  });
  return {
    ratings: (body.data ?? []).map(toRecipeRating),
    hasMore: Boolean(body.has_more),
  };
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
