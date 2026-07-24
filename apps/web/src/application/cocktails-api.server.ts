import 'server-only';

import type { Cocktail, CocktailDetail, CocktailRecipe } from '@sakehub/types';

import {
  toCocktail,
  toCocktailRecipe,
  toRecipeSummary,
  type ApiCocktail,
  type ApiCocktailDetail,
  type ApiRecipe,
} from './cocktail-mappers';
import { serverFetch } from './server-api';

interface ApiCocktailListResponse {
  data: ApiCocktail[] | null;
}

export async function fetchCocktailsServer(): Promise<Cocktail[]> {
  const res = await serverFetch<ApiCocktailListResponse>('/api/cocktails');
  return (res.data ?? []).map(toCocktail);
}

interface FetchCocktailBySlugOptions {
  limit?: number;
  offset?: number;
}

/** マスタ詳細 + published レシピ一覧（1 API コールで取得）。 */
export async function fetchCocktailBySlugServer(
  slug: string,
  options: FetchCocktailBySlugOptions = {},
): Promise<CocktailDetail> {
  const params: Record<string, string> = {};
  if (options.limit != null) params.limit = String(options.limit);
  if (options.offset != null) params.offset = String(options.offset);

  const res = await serverFetch<ApiCocktailDetail>(
    `/api/cocktails/by-slug/${encodeURIComponent(slug)}`,
    Object.keys(params).length > 0 ? { params } : undefined,
  );
  return {
    ...toCocktail(res),
    recipes: (res.recipes ?? []).map(toRecipeSummary),
    hasMoreRecipes: Boolean(res.has_more_recipes),
  };
}

/** published レシピ詳細（材料 + 評価集計つき）。 */
export async function fetchCocktailRecipeServer(id: string): Promise<CocktailRecipe> {
  const res = await serverFetch<ApiRecipe>(`/api/cocktail-recipes/${encodeURIComponent(id)}`);
  return toCocktailRecipe(res);
}
