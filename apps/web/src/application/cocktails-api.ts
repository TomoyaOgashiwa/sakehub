import type { Cocktail, CocktailListParams, CocktailListResult } from '@sakehub/types';

import { apiClient } from './api-client';
import { toCocktail, type ApiCocktail } from './cocktail-mappers';

interface ApiCocktailListResponse {
  data: ApiCocktail[] | null;
  total: number;
  limit: number;
  offset: number;
}

export type { ApiCocktail };
export { toCocktail };

function toParams(params: CocktailListParams = {}): Record<string, string> {
  const query: Record<string, string> = {};
  if (params.q) query.q = params.q;
  if (params.baseSpirit) query.base_spirit = params.baseSpirit;
  if (params.limit != null) query.limit = String(params.limit);
  if (params.offset != null) query.offset = String(params.offset);
  return query;
}

export async function fetchCocktails(
  params: CocktailListParams = {},
): Promise<CocktailListResult> {
  const res = await apiClient<ApiCocktailListResponse>('/api/cocktails', {
    params: toParams(params),
  });
  return {
    cocktails: (res.data ?? []).map(toCocktail),
    total: res.total ?? 0,
    limit: res.limit ?? params.limit ?? 0,
    offset: res.offset ?? params.offset ?? 0,
  };
}

/** Convenience for callers that only need the array (e.g. recipe form). */
export async function fetchCocktailItems(params: CocktailListParams = {}): Promise<Cocktail[]> {
  const { cocktails } = await fetchCocktails(params);
  return cocktails;
}
