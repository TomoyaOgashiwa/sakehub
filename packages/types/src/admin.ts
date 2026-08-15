import type { SearchMissScope } from './cocktail';

/** GET /api/admin/search-misses の集計行。需要ログであり公開マスタではない。 */
export interface AdminSearchMissRow {
  scope: SearchMissScope;
  queryNormalized: string;
  sampleQueryRaw: string;
  missCount: number;
  uniqueSearchers: number;
  lastSeenAt: string;
}

export interface AdminSearchMissListParams {
  scope?: SearchMissScope | 'all';
  limit?: number;
  offset?: number;
}

export interface AdminSearchMissListResult {
  data: AdminSearchMissRow[];
  total: number;
  limit: number;
  offset: number;
}
