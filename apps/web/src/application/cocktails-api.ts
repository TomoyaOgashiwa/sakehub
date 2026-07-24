import type { Cocktail } from '@sakehub/types';

import { apiClient } from './api-client';
import { toCocktail, type ApiCocktail } from './cocktail-mappers';

interface ApiCocktailListResponse {
  data: ApiCocktail[] | null;
}

export type { ApiCocktail };
export { toCocktail };

export async function fetchCocktails(): Promise<Cocktail[]> {
  const res = await apiClient<ApiCocktailListResponse>('/api/cocktails');
  return (res.data ?? []).map(toCocktail);
}
