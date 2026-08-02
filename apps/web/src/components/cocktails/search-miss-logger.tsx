'use client';

import { useEffect, useRef } from 'react';

import { logSearchMiss } from '@/application/search-misses-api';

interface SearchMissLoggerProps {
  query: string;
  total: number;
}

/**
 * Logs a zero-hit cocktail search once per confirmed query (URL `q`).
 * Only runs when the RSC-fetched result set is empty.
 */
export function SearchMissLogger({ query, total }: SearchMissLoggerProps) {
  const loggedKey = useRef<string | null>(null);

  useEffect(() => {
    const q = query.trim();
    if (!q || total > 0) return;

    const key = q.toLowerCase();
    if (loggedKey.current === key) return;
    loggedKey.current = key;

    void logSearchMiss({
      scope: 'cocktail',
      queryRaw: q,
      resultCount: 0,
    });
  }, [query, total]);

  return null;
}
