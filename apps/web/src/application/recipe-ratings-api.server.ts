import 'server-only';

import type { CocktailRecipeRating } from '@sakehub/types';

const API_URL = process.env.API_URL ?? 'http://localhost:8080';

interface ApiRating {
  id: string;
  recipe_id: string;
  user_id: string;
  rating: number;
  comment: string;
  created_at: string;
  updated_at: string;
}

interface ApiRatingListResponse {
  data: ApiRating[] | null;
}

function toRating(api: ApiRating): CocktailRecipeRating {
  return {
    id: api.id,
    recipeId: api.recipe_id,
    userId: api.user_id,
    rating: api.rating,
    comment: api.comment,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

/** Fetch all ratings for a cocktail recipe (public, no auth required). */
export async function fetchRatingsByRecipeId(recipeId: string): Promise<CocktailRecipeRating[]> {
  try {
    const url = new URL(`${API_URL}/api/public/cocktail-recipe-ratings`);
    url.searchParams.set('recipe_id', recipeId);

    const res = await fetch(url.toString(), {
      headers: { 'Content-Type': 'application/json' },
      next: { revalidate: 0 },
    });
    if (!res.ok) return [];

    const body = (await res.json()) as ApiRatingListResponse;
    return (body.data ?? []).map(toRating);
  } catch {
    return [];
  }
}

/** Fetch the authenticated user's rating for a recipe. Returns null if none. */
export async function fetchMyRecipeRating(
  recipeId: string,
  accessToken: string,
): Promise<CocktailRecipeRating | null> {
  try {
    const url = new URL(`${API_URL}/api/auth/cocktail-recipe-ratings/mine`);
    url.searchParams.set('recipe_id', recipeId);

    const res = await fetch(url.toString(), {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      next: { revalidate: 0 },
    });
    if (!res.ok) return null;

    const body = (await res.json()) as { data: ApiRating | null };
    return body.data ? toRating(body.data) : null;
  } catch {
    return null;
  }
}
