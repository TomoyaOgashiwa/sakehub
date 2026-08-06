const STORAGE_KEY = 'sakehub:client-hash';

/**
 * Returns a stable, anonymous per-browser identifier for grouping unread
 * (unauthenticated) search-miss telemetry in `search_miss_ranking.unique_searchers`.
 *
 * Without this, every anonymous visitor's zero-hit searches collapse into a
 * single `NULL` bucket (`COALESCE(user_id, client_hash)` in the ranking view),
 * so demand from non-logged-in users is undercounted. The value never leaves
 * `localStorage` except as an opaque token attached to search-miss logs; it
 * carries no PII and is not derived from any device fingerprint.
 *
 * Returns `undefined` when `localStorage` is unavailable (SSR, privacy mode, etc.).
 */
export function getOrCreateClientHash(): string | undefined {
  if (typeof window === 'undefined') return undefined;

  try {
    const existing = window.localStorage.getItem(STORAGE_KEY);
    if (existing) return existing;

    const id =
      typeof crypto !== 'undefined' && 'randomUUID' in crypto
        ? crypto.randomUUID()
        : `${Date.now()}-${Math.random().toString(36).slice(2)}`;

    window.localStorage.setItem(STORAGE_KEY, id);
    return id;
  } catch {
    // Storage disabled/unavailable; fall back to unattributed logging.
    return undefined;
  }
}
