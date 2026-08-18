import 'server-only';

import type {
  Cocktail,
  CocktailDetail,
  CocktailListParams,
  CocktailListResult,
  CocktailRecipe,
  MyCocktailRecipeListResult,
} from '@sakehub/types';

import { BRIDGE_PREVIEW_LIMIT } from '@/config/drink-cocktail-bridge';

import {
  toCocktail,
  toCocktailRecipe,
  toMyRecipeSummary,
  toRecipeSummary,
  type ApiCocktail,
  type ApiCocktailDetail,
  type ApiMyRecipeListResponse,
  type ApiRecipe,
} from './cocktail-mappers';
import { authServerFetch, serverFetch } from './server-api';

interface ApiCocktailListResponse {
  data: ApiCocktail[] | null;
  total: number;
  limit: number;
  offset: number;
}

function toParams(params: CocktailListParams = {}): Record<string, string> | undefined {
  const query: Record<string, string> = {};
  if (params.q) query.q = params.q;
  if (params.baseSpirit) query.base_spirit = params.baseSpirit;
  if (params.limit != null) query.limit = String(params.limit);
  if (params.offset != null) query.offset = String(params.offset);
  return Object.keys(query).length > 0 ? query : undefined;
}

export async function fetchCocktailsServer(
  params: CocktailListParams = {},
): Promise<CocktailListResult> {
  const res = await serverFetch<ApiCocktailListResponse>('/api/cocktails', {
    params: toParams(params),
  });
  return {
    cocktails: (res.data ?? []).map(toCocktail),
    total: res.total ?? 0,
    limit: res.limit ?? params.limit ?? 0,
    offset: res.offset ?? params.offset ?? 0,
  };
}

/** Flat list helper for sitemap / form options. */
export async function fetchCocktailItemsServer(
  params: CocktailListParams = {},
): Promise<Cocktail[]> {
  const { cocktails } = await fetchCocktailsServer(params);
  return cocktails;
}

/** Drink / list bridge preview. Fail closed so a cocktail API error does not drop the page. */
export async function fetchCocktailBridgePreview(baseSpirit: string): Promise<Cocktail[]> {
  try {
    const { cocktails } = await fetchCocktailsServer({
      baseSpirit,
      limit: BRIDGE_PREVIEW_LIMIT,
    });
    return cocktails;
  } catch {
    return [];
  }
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
    officialRecipe: res.official_recipe ? toCocktailRecipe(res.official_recipe) : undefined,
    recipes: (res.recipes ?? []).map(toRecipeSummary),
    hasMoreRecipes: Boolean(res.has_more_recipes),
  };
}

/** published レシピ詳細（材料 + 評価集計つき）。 */
export async function fetchCocktailRecipeServer(id: string): Promise<CocktailRecipe> {
  const res = await serverFetch<ApiRecipe>(`/api/cocktail-recipes/${encodeURIComponent(id)}`);
  return toCocktailRecipe(res);
}

/** Authenticated owner's draft + published recipes. Fail closed to null. */
export async function fetchMyCocktailRecipes(
  accessToken: string,
  options?: { limit?: number; offset?: number },
): Promise<MyCocktailRecipeListResult | null> {
  const params: Record<string, string> = {};
  if (options?.limit != null) params.limit = String(options.limit);
  if (options?.offset != null) params.offset = String(options.offset);

  const result = await authServerFetch<ApiMyRecipeListResponse>('/api/auth/cocktail-recipes/mine', {
    accessToken,
    params,
  });
  if (!result.ok) return null;

  return {
    recipes: (result.data.data ?? []).map(toMyRecipeSummary),
    total: result.data.total ?? 0,
    limit: result.data.limit ?? options?.limit ?? 0,
    offset: result.data.offset ?? options?.offset ?? 0,
  };
}
