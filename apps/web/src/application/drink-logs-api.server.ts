import 'server-only';

import type { DrinkLog, DrinkLogSummary } from '@sakehub/types';

import {
  toDrinkLog,
  toDrinkLogSummary,
  type ApiDrinkLog,
  type ApiDrinkLogSummary,
} from '@/application/drink-log-mappers';
import { authServerFetch } from '@/application/server-api';

export async function fetchMyDrinkLogs(
  accessToken: string,
  options?: { limit?: number; offset?: number; from?: string; to?: string },
): Promise<DrinkLog[]> {
  const params: Record<string, string> = {};
  if (options?.limit != null) params.limit = String(options.limit);
  if (options?.offset != null) params.offset = String(options.offset);
  if (options?.from) params.from = options.from;
  if (options?.to) params.to = options.to;

  const result = await authServerFetch<{ data: ApiDrinkLog[] | null }>(
    '/api/auth/drink-logs',
    { accessToken, params },
  );
  if (!result.ok) return [];
  return (result.data.data ?? []).map(toDrinkLog);
}

export async function fetchDrinkLogSummary(
  accessToken: string,
  from: string,
  to: string,
): Promise<DrinkLogSummary | null> {
  const result = await authServerFetch<ApiDrinkLogSummary>('/api/auth/drink-logs/summary', {
    accessToken,
    params: { from, to },
  });
  if (!result.ok) return null;
  return toDrinkLogSummary(result.data);
}

export async function fetchDrinkLogById(
  accessToken: string,
  id: string,
): Promise<DrinkLog | null> {
  const result = await authServerFetch<ApiDrinkLog>(
    `/api/auth/drink-logs/${encodeURIComponent(id)}`,
    { accessToken },
  );
  if (!result.ok) return null;
  return toDrinkLog(result.data);
}
