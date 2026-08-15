import 'server-only';

import { authServerFetch, type AuthServerFetchResult } from '@/application/server-api';

export interface AdminOverview {
  drinkMissRows: number;
  drinkMissQueries: number;
  provisionalDrinks: number;
  publishedDrinks: number;
}

function isFiniteNumber(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}

function toAdminOverview(row: unknown): AdminOverview | null {
  if (typeof row !== 'object' || row === null) {
    return null;
  }
  const rec = row as Record<string, unknown>;
  if (
    !isFiniteNumber(rec.drink_miss_rows) ||
    !isFiniteNumber(rec.drink_miss_queries) ||
    !isFiniteNumber(rec.provisional_drinks) ||
    !isFiniteNumber(rec.published_drinks)
  ) {
    return null;
  }
  return {
    drinkMissRows: rec.drink_miss_rows,
    drinkMissQueries: rec.drink_miss_queries,
    provisionalDrinks: rec.provisional_drinks,
    publishedDrinks: rec.published_drinks,
  };
}

export async function fetchAdminOverview(
  accessToken: string,
): Promise<AuthServerFetchResult<AdminOverview>> {
  const result = await authServerFetch<unknown>('/api/admin/overview', {
    accessToken,
    cache: 'no-store',
  });
  if (!result.ok) {
    return result;
  }

  const data = toAdminOverview(result.data);
  if (!data) {
    return { ok: false, status: 200, error: 'invalid overview payload' };
  }
  return { ok: true, data };
}
