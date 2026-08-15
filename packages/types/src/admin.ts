import type { SearchMissScope } from './cocktail';
import type { SavedDrinkStatus } from './saved-drink';

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

/** GET /api/admin/provisional-drinks の1行。未マージの仮の印だけ。 */
export interface AdminProvisionalDrinkRow {
  id: string;
  name: string;
  nameNormalized: string;
  submittedBy: string;
  submitterDisplayName: string;
  submitterEmail: string;
  createdAt: string;
  hasSavedDrink: boolean;
  savedStatus: SavedDrinkStatus | null;
}

export interface AdminProvisionalDrinkListParams {
  limit?: number;
  offset?: number;
}

export interface AdminProvisionalDrinkListResult {
  data: AdminProvisionalDrinkRow[];
  total: number;
  limit: number;
  offset: number;
}
