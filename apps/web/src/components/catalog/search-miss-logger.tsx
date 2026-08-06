'use client';

import { useEffect, useRef } from 'react';

import type { SearchMissScope } from '@sakehub/types';

import { logSearchMiss } from '@/application/search-misses-api';
import { getOrCreateClientHash } from '@/utils/client-hash';

interface SearchMissLoggerProps {
  scope: SearchMissScope;
  query: string;
  total: number;
}

/**
 * 確定した検索クエリ（URL の `q`）がゼロヒットだったとき、1回だけログする。
 * drink / cocktail / ingredient のいずれのカタログでも共通で使い、
 * search_miss_ranking が検索対象によらず一貫して需要を拾えるようにする。
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
      clientHash: getOrCreateClientHash(),
    });
  }, [scope, query, total]);

  return null;
}
