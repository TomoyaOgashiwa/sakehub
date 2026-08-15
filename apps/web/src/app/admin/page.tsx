import Link from 'next/link';

import { fetchAdminOverview } from '@/application/admin-api';
import { getOptionalAccessToken } from '@/application/require-access-token';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Heading } from '@/components/ui/heading';

function formatCount(value: number | null): string {
  if (value === null) return '取得できない';
  return value.toLocaleString('ja-JP');
}

export default async function AdminPage() {
  const { accessToken } = await getOptionalAccessToken();
  const overview = accessToken ? await fetchAdminOverview(accessToken) : null;
  const counts = overview?.ok ? overview.data : null;

  return (
    <div>
      <Heading level="h1">運営</Heading>
      <p className="text-muted-foreground mt-2">
        需要が溜まる → 仮の印がある → 公開カタログは人手。画面から公開しない。
      </p>

      <ol className="mt-8 grid gap-4">
        <li>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Badge variant="secondary">1</Badge>
                ゼロヒット需要
              </CardTitle>
              <CardDescription>
                search_misses のゼロ件ログ数（drink・全期間）。drinklog 経由も含む。
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="font-heading text-3xl font-bold tabular-nums">
                {formatCount(counts?.drinkMissRows ?? null)}
              </p>
              <p>溜まったクエリは CLI で pending に出す。この画面から実行しない。</p>
              <pre className="bg-muted overflow-x-auto rounded-lg p-3 text-xs">
                <code>DATABASE_URL=... pnpm seed:drinks:demand</code>
              </pre>
              <p>
                <Link href="/admin/search-misses" className="underline underline-offset-4">
                  需要一覧
                </Link>
                は Phase 3。
              </p>
            </CardContent>
          </Card>
        </li>
        <li>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Badge variant="secondary">2</Badge>
                ユニーク需要クエリ
              </CardTitle>
              <CardDescription>
                search_miss_ranking 相当の行数（scope=drink・result_count=0）。
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="font-heading text-3xl font-bold tabular-nums">
                {formatCount(counts?.drinkMissQueries ?? null)}
              </p>
              <p>同じ正規化クエリは1行。fact-check して drink-seed JSON を足す対象になる。</p>
              <pre className="bg-muted overflow-x-auto rounded-lg p-3 text-xs">
                <code>DATABASE_URL=... pnpm seed:drinks:demand</code>
              </pre>
            </CardContent>
          </Card>
        </li>
        <li>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Badge variant="secondary">3</Badge>
                図鑑待ち（全ユーザー）
              </CardTitle>
              <CardDescription>
                drinks.visibility=provisional かつ merged_into_id が空。本人リストとは別。
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="font-heading text-3xl font-bold tabular-nums">
                {formatCount(counts?.provisionalDrinks ?? null)}
              </p>
              <p>
                <code className="text-sm">/list?pending=1</code>{' '}
                は本人の図鑑待ちのまま。運営キューではない。公開カタログ投入後に CLI
                で杭を付け替える。
              </p>
              <pre className="bg-muted overflow-x-auto rounded-lg p-3 text-xs">
                <code>pnpm seed:drinks:merge</code>
              </pre>
              <p>
                <Link href="/admin/provisional" className="underline underline-offset-4">
                  図鑑待ち一覧
                </Link>
                は Phase 4。
              </p>
            </CardContent>
          </Card>
        </li>
        <li>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Badge variant="secondary">4</Badge>
                公開カタログ
              </CardTitle>
              <CardDescription>
                drinks.visibility=published。正本は packages/drink-seed の JSON。承認は PR。
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="font-heading text-3xl font-bold tabular-nums">
                {formatCount(counts?.publishedDrinks ?? null)}
              </p>
              <p>
                fact-check して <code>packages/drink-seed/data/drinks/*.json</code> を足し、validate
                → build のあと PR する。画面から published にしない。
              </p>
            </CardContent>
          </Card>
        </li>
      </ol>
    </div>
  );
}
