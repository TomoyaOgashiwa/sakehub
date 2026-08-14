import 'server-only';

import type { ListDepth, SavedDrink } from '@sakehub/types';

import {
  toListDepth,
  toSavedDrink,
  type ApiListDepth,
  type ApiSavedDrink,
} from '@/application/saved-drink-mappers';
import { authServerFetch } from '@/application/server-api';

export async function fetchMySavedDrinks(
  accessToken: string,
  options?: { limit?: number; offset?: number },
): Promise<SavedDrink[]> {
  const params: Record<string, string> = {};
  if (options?.limit != null) params.limit = String(options.limit);
  if (options?.offset != null) params.offset = String(options.offset);

  const result = await authServerFetch<{ data: ApiSavedDrink[] | null }>('/api/auth/saved-drinks', {
    accessToken,
    params,
  });
  if (!result.ok) return [];
  return (result.data.data ?? []).map(toSavedDrink);
}

export async function fetchMySavedDrink(
  drinkId: string,
  accessToken: string,
): Promise<SavedDrink | null> {
  const result = await authServerFetch<{ data: ApiSavedDrink | null }>(
    '/api/auth/saved-drinks/mine',
    { accessToken, params: { drink_id: drinkId } },
  );
  if (!result.ok) return null;
  return result.data.data ? toSavedDrink(result.data.data) : null;
}

export async function fetchMyListDepth(accessToken: string): Promise<ListDepth> {
  const result = await authServerFetch<{ data: ApiListDepth | null }>(
    '/api/auth/saved-drinks/depth',
    {
      accessToken,
    },
  );
  if (!result.ok || !result.data.data) {
    return { specialty: null, categories: [], makers: [], makerScope: 'all' };
  }
  return toListDepth(result.data.data);
}
