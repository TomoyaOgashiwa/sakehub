'use client';

import { useEffect, useRef } from 'react';

import type { SearchMissScope } from '@sakehub/types';

import { logSearchMiss } from '@/application/search-misses-api';
import { getOrCreateClientHash } from '@/utils/client-hash';

interface SearchMissLoggerProps {
  scope: SearchMissScope;
  query: string;
  total: number;
  /**
   * category / base_spirit などの絞り込みが有効かどうか。true の間は
   * 何もログしない。フィルタ付きのゼロヒットは「未登録」ではなく
   * 「フィルタ不一致」の可能性が高く、需要計測（Phase 3 の export-demand
   * → draft パイプライン）を歪めるため。呼び出し側の条件分岐だけに頼ると
   * 新しい一覧を追加したときに漏れやすいので、契約としてここに内蔵する。
   */
  filtersActive?: boolean;
}

/**
 * 確定した検索クエリ（URL の `q`）がフィルタなしでゼロヒットだったとき、
 * 1回だけログする。drink / cocktail / ingredient のいずれのカタログでも
 * 共通で使い、search_miss_ranking が検索対象によらず一貫して需要を
 * 拾えるようにする。
 *
 * 注意: ここでの「確定」は呼び出し側の入力コンポーネントが
 * debounce ではなく submit 確定で `q` を更新することが前提
 * （`ConfirmedSearchInput` 参照）。キー入力ごとに `q` が変わる実装と
 * 組み合わせると、入力途中の部分文字列まで記録されてしまう。
 */
export function SearchMissLogger({
  scope,
  query,
  total,
  filtersActive = false,
}: SearchMissLoggerProps) {
  const loggedKey = useRef<string | null>(null);

  useEffect(() => {
    const q = query.trim();
    if (!q || total > 0 || filtersActive) return;

    const key = `${scope}:${q.toLowerCase()}`;
    if (loggedKey.current === key) return;
    loggedKey.current = key;

    void logSearchMiss({
      scope,
      queryRaw: q,
      resultCount: 0,
      clientHash: getOrCreateClientHash(),
    });
  }, [scope, query, total, filtersActive]);

  return null;
}
