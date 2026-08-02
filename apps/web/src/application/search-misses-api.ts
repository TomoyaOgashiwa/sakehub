import type { SearchMissCreateInput } from '@sakehub/types';

/**
 * Log a confirmed zero-hit search. Fire-and-forget safe: swallows errors so
 * logging never blocks the UI.
 */
export async function logSearchMiss(input: SearchMissCreateInput): Promise<void> {
  try {
    await fetch('/api/search-misses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        scope: input.scope,
        query_raw: input.queryRaw,
        result_count: input.resultCount,
        ...(input.clientHash ? { client_hash: input.clientHash } : {}),
      }),
    });
  } catch {
    // Best-effort telemetry; ignore failures.
  }
}
