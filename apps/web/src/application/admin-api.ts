import 'server-only';

import { authServerFetch, type AuthServerFetchResult } from '@/application/server-api';

export interface AdminOverview {
  drinkMissRows: number;
  drinkMissQueries: number;
  provisionalDrinks: number;
  publishedDrinks: number;
}

interface ApiAdminOverview {
  drink_miss_rows: number;
  drink_miss_queries: number;
  provisional_drinks: number;
  published_drinks: number;
}

export async function fetchAdminOverview(
  accessToken: string,
): Promise<AuthServerFetchResult<AdminOverview>> {
  const result = await authServerFetch<ApiAdminOverview>('/api/admin/overview', { accessToken });
  if (!result.ok) {
    return result;
  }

  const row = result.data;
  return {
    ok: true,
    data: {
      drinkMissRows: row.drink_miss_rows,
      drinkMissQueries: row.drink_miss_queries,
      provisionalDrinks: row.provisional_drinks,
      publishedDrinks: row.published_drinks,
    },
  };
}
