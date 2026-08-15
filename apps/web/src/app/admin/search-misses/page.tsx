import type { Metadata } from 'next';
import Link from 'next/link';
import type { AdminSearchMissListParams } from '@sakehub/types';

import { fetchAdminSearchMisses } from '@/application/admin-api';
import { getOptionalAccessToken } from '@/application/require-access-token';
import { Badge } from '@/components/ui/badge';
import { buttonVariants } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Heading } from '@/components/ui/heading';
import { cn } from '@/utils/utils';

export const metadata: Metadata = {
  title: '需要',
};

type PageProps = {
  searchParams: Promise<{ scope?: string; limit?: string; offset?: string }>;
};

type ScopeFilter = NonNullable<AdminSearchMissListParams['scope']>;

const SCOPE_FILTERS: readonly { value: ScopeFilter; label: string }[] = [
  { value: 'all', label: '全部' },
  { value: 'drink', label: 'drink' },
  { value: 'cocktail', label: 'cocktail' },
];

function parseScope(raw: string | undefined): ScopeFilter {
  if (raw === 'drink' || raw === 'cocktail' || raw === 'ingredient') {
    return raw;
  }
  return 'all';
}

function parseOffset(raw: string | undefined): number {
  const n = Number(raw);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.floor(n);
}

function scopeHref(scope: ScopeFilter): string {
  if (scope === 'all') return '/admin/search-misses';
  return `/admin/search-misses?scope=${scope}`;
}

function formatLastSeen(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString('ja-JP', { timeZone: 'UTC' });
}

export default async function AdminSearchMissesPage({ searchParams }: PageProps) {
  const sp = await searchParams;
  const scope = parseScope(sp.scope);
  const offset = parseOffset(sp.offset);
  const { accessToken } = await getOptionalAccessToken();
  const list = accessToken ? await fetchAdminSearchMisses(accessToken, { scope, offset }) : null;
  const rows = list?.ok ? list.data : null;

  return (
    <div>
      <Heading level="h1">需要</Heading>
      <p className="text-muted-foreground mt-2">
        これは需要ログ。公開マスタ化は <code>pnpm seed:drinks:demand</code> → 人手 JSON → PR。
      </p>
      <p className="text-muted-foreground mt-2 text-sm">
        Studio の <code>search_miss_ranking</code> 相当。並べ替えは <code>miss_count DESC</code>、
        <code>unique_searchers DESC</code>。この画面から公開しない。
      </p>

      <nav aria-label="対象" className="mt-6 flex flex-wrap gap-2">
        {SCOPE_FILTERS.map((item) => {
          const active = scope === item.value;
          return (
            <Link
              key={item.value}
              href={scopeHref(item.value)}
              aria-current={active ? 'page' : undefined}
              className={cn(
                buttonVariants({ variant: active ? 'default' : 'outline', size: 'sm' }),
              )}
            >
              {item.label}
            </Link>
          );
        })}
      </nav>

      <Card className="mt-6">
        <CardHeader>
          <CardTitle>ゼロヒット需要</CardTitle>
          <CardDescription>
            scope / 正規化クエリ / 最新の元クエリ / 回数 / 検索者数 / 最終。user_id は出さない。
          </CardDescription>
        </CardHeader>
        <CardContent>
          {rows === null ? (
            <p className="text-muted-foreground text-sm">
              一覧を取得できませんでした。需要の見方は上の手順のままです。
            </p>
          ) : rows.data.length === 0 ? (
            <p className="text-muted-foreground text-sm">この条件の需要ログはありません。</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-max border-collapse text-left text-sm">
                <thead>
                  <tr className="border-border border-b">
                    <th className="py-2 pr-3 font-medium">scope</th>
                    <th className="py-2 pr-3 font-medium">query_normalized</th>
                    <th className="py-2 pr-3 font-medium">query_raw（最新）</th>
                    <th className="py-2 pr-3 text-right font-medium">miss_count</th>
                    <th className="py-2 pr-3 text-right font-medium">unique_searchers</th>
                    <th className="py-2 font-medium">last_seen_at</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.data.map((row) => (
                    <tr
                      key={`${row.scope}:${row.queryNormalized}`}
                      className="border-border border-b last:border-0"
                    >
                      <td className="py-2 pr-3">
                        <Badge variant="secondary">{row.scope}</Badge>
                      </td>
                      <td className="py-2 pr-3 font-mono text-xs">{row.queryNormalized}</td>
                      <td className="py-2 pr-3">{row.sampleQueryRaw}</td>
                      <td className="py-2 pr-3 text-right tabular-nums">
                        {row.missCount.toLocaleString('ja-JP')}
                      </td>
                      <td className="py-2 pr-3 text-right tabular-nums">
                        {row.uniqueSearchers.toLocaleString('ja-JP')}
                      </td>
                      <td className="text-muted-foreground py-2 whitespace-nowrap">
                        {formatLastSeen(row.lastSeenAt)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <p className="text-muted-foreground mt-3 text-xs">
                {rows.total.toLocaleString('ja-JP')} 件中 {rows.data.length.toLocaleString('ja-JP')}{' '}
                件{offset > 0 ? `（offset ${offset}）` : ''}
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
