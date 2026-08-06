'use client';

import { useEffect, useRef } from 'react';

import type { SearchMissScope } from '@sakehub/types';

import { logSearchMiss } from '@/application/search-misses-api';

interface SearchMissLoggerProps {
  scope: SearchMissScope;
  query: string;
  total: number;
}

/**
 * Logs a zero-hit catalog search once per confirmed query (URL `q`).
 * Only runs when the fetched result set is empty. Shared across scopes
 * (drink / cocktail / ingredient) so search_miss_ranking captures demand
 * consistently regardless of which catalog was searched.
 */
export function SearchMissLogger({ scope, query, total }: SearchMissLoggerProps) {
  const loggedKey = useRef<string | null>(null);

  useEffect(() => {
    const q = query.trim();
    if (!q || total > 0) return;

    const key = `${scope}:${q.toLowerCase()}`;
    if (loggedKey.current === key) return;
    loggedKey.current = key;

    void logSearchMiss({
      scope,
      queryRaw: q,
      resultCount: 0,
    });
  }, [scope, query, total]);

  return null;
}
