import 'server-only';

import type {
  AdminSearchMissListParams,
  AdminSearchMissListResult,
  AdminSearchMissRow,
  SearchMissScope,
} from '@sakehub/types';

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

const SEARCH_MISS_SCOPES = new Set<SearchMissScope>(['cocktail', 'drink', 'ingredient']);

function isSearchMissScope(value: unknown): value is SearchMissScope {
  return typeof value === 'string' && SEARCH_MISS_SCOPES.has(value as SearchMissScope);
}

function toAdminSearchMissRow(row: unknown): AdminSearchMissRow | null {
  if (typeof row !== 'object' || row === null) {
    return null;
  }
  const rec = row as Record<string, unknown>;
  if (
    !isSearchMissScope(rec.scope) ||
    typeof rec.query_normalized !== 'string' ||
    typeof rec.sample_query_raw !== 'string' ||
    !isFiniteNumber(rec.miss_count) ||
    !isFiniteNumber(rec.unique_searchers) ||
    typeof rec.last_seen_at !== 'string'
  ) {
    return null;
  }
  return {
    scope: rec.scope,
    queryNormalized: rec.query_normalized,
    sampleQueryRaw: rec.sample_query_raw,
    missCount: rec.miss_count,
    uniqueSearchers: rec.unique_searchers,
    lastSeenAt: rec.last_seen_at,
  };
}

function toAdminSearchMissList(payload: unknown): AdminSearchMissListResult | null {
  if (typeof payload !== 'object' || payload === null) {
    return null;
  }
  const rec = payload as Record<string, unknown>;
  if (
    !Array.isArray(rec.data) ||
    !isFiniteNumber(rec.total) ||
    !isFiniteNumber(rec.limit) ||
    !isFiniteNumber(rec.offset)
  ) {
    return null;
  }
  const data: AdminSearchMissRow[] = [];
  for (const item of rec.data) {
    const row = toAdminSearchMissRow(item);
    if (!row) {
      return null;
    }
    data.push(row);
  }
  return {
    data,
    total: rec.total,
    limit: rec.limit,
    offset: rec.offset,
  };
}

export async function fetchAdminSearchMisses(
  accessToken: string,
  params: AdminSearchMissListParams = {},
): Promise<AuthServerFetchResult<AdminSearchMissListResult>> {
  const query: Record<string, string> = {};
  if (params.scope && params.scope !== 'all') {
    query.scope = params.scope;
  }
  if (params.limit != null) {
    query.limit = String(params.limit);
  }
  if (params.offset != null) {
    query.offset = String(params.offset);
  }

  const result = await authServerFetch<unknown>('/api/admin/search-misses', {
    accessToken,
    cache: 'no-store',
    params: query,
  });
  if (!result.ok) {
    return result;
  }

  const data = toAdminSearchMissList(result.data);
  if (!data) {
    return { ok: false, status: 200, error: 'invalid search-miss payload' };
  }
  return { ok: true, data };
}
