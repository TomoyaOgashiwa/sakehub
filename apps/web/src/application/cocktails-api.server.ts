import 'server-only';

import type { Cocktail, CocktailDetail, CocktailRecipe, CocktailRecipeSummary } from '@sakehub/types';

import { serverFetch } from './server-api';

interface ApiCocktail {
  id: string;
  slug: string;
  name: string;
  name_en?: string;
  description: string;
  image_url?: string;
  base_spirit?: string;
  abv?: number;
  origin_country?: string;
  recipe_count: number;
  created_at: string;
  updated_at: string;
}

interface ApiRecipeSummary {
  id: string;
  cocktail_id: string;
  user_id: string;
  name: string;
  memo?: string;
  image_url?: string;
  status: 'draft' | 'published';
  average_rating: number;
  total_ratings: number;
  created_at: string;
  updated_at: string;
}

interface ApiRecipeIngredient {
  id: string;
  recipe_id: string;
  name: string;
  amount?: number;
  unit?: string;
  sort_order: number;
  created_at: string;
}

interface ApiRecipe extends ApiRecipeSummary {
  ingredients: ApiRecipeIngredient[];
}

interface ApiCocktailDetail extends ApiCocktail {
  recipes: ApiRecipeSummary[];
}

interface ApiCocktailListResponse {
  data: ApiCocktail[] | null;
}

function toCocktail(api: ApiCocktail): Cocktail {
  return {
    id: api.id,
    slug: api.slug,
    name: api.name,
    nameEn: api.name_en,
    description: api.description,
    imageUrl: api.image_url,
    baseSpirit: api.base_spirit,
    abv: api.abv,
    originCountry: api.origin_country,
    recipeCount: api.recipe_count,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

function toRecipeSummary(api: ApiRecipeSummary): CocktailRecipeSummary {
  return {
    id: api.id,
    cocktailId: api.cocktail_id,
    userId: api.user_id,
    name: api.name,
    memo: api.memo,
    imageUrl: api.image_url,
    status: api.status,
    averageRating: api.average_rating,
    totalRatings: api.total_ratings,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

export async function fetchCocktailsServer(): Promise<Cocktail[]> {
  const res = await serverFetch<ApiCocktailListResponse>('/api/cocktails');
  return (res.data ?? []).map(toCocktail);
}

/** マスタ詳細 + published レシピ一覧（1 API コールで取得）。 */
export async function fetchCocktailBySlugServer(slug: string): Promise<CocktailDetail> {
  const res = await serverFetch<ApiCocktailDetail>(
    `/api/cocktails/by-slug/${encodeURIComponent(slug)}`,
  );
  return {
    ...toCocktail(res),
    recipes: (res.recipes ?? []).map(toRecipeSummary),
  };
}

/** published レシピ詳細（材料 + 評価集計つき）。 */
export async function fetchCocktailRecipeServer(id: string): Promise<CocktailRecipe> {
  const res = await serverFetch<ApiRecipe>(`/api/cocktail-recipes/${encodeURIComponent(id)}`);
  return {
    ...toRecipeSummary(res),
    ingredients: (res.ingredients ?? []).map((ing) => ({
      id: ing.id,
      recipeId: ing.recipe_id,
      name: ing.name,
      amount: ing.amount,
      unit: ing.unit as CocktailRecipe['ingredients'][number]['unit'],
      sortOrder: ing.sort_order,
      createdAt: ing.created_at,
    })),
  };
}
