import type { Metadata } from 'next';
import type { AdminProvisionalDrinkRow } from '@sakehub/types';
import { Hourglass } from 'lucide-react';

import { fetchAdminProvisionalDrinks } from '@/application/admin-api';
import { getOptionalAccessToken } from '@/application/require-access-token';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Heading } from '@/components/ui/heading';
import { savedDrinkStatusLabel } from '@/utils/saved-drink-status';

export const metadata: Metadata = {
  title: '図鑑待ち',
};

function formatCreatedAt(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString('ja-JP', { timeZone: 'UTC' });
}

function submitterLabel(row: AdminProvisionalDrinkRow): {
  primary: string;
  secondary: string | null;
} {
  const name = row.submitterDisplayName.trim();
  const email = row.submitterEmail.trim();
  if (name && email) {
    return { primary: name, secondary: email };
  }
  if (name) {
    return { primary: name, secondary: null };
  }
  if (email) {
    return { primary: email, secondary: null };
  }
  return { primary: row.submittedBy, secondary: null };
}

function countByNormalized(rows: readonly AdminProvisionalDrinkRow[]): Map<string, number> {
  const counts = new Map<string, number>();
  for (const row of rows) {
    counts.set(row.nameNormalized, (counts.get(row.nameNormalized) ?? 0) + 1);
  }
  return counts;
}

export default async function AdminProvisionalPage() {
  const { accessToken } = await getOptionalAccessToken();
  const list = accessToken ? await fetchAdminProvisionalDrinks(accessToken) : null;
  const rows = list?.ok ? list.data : null;
  const sameNameCounts = rows ? countByNormalized(rows.data) : null;
  const uniqueNormalized = sameNameCounts?.size ?? 0;

  return (
    <div>
      <Heading level="h1" className="flex items-center gap-3">
        <span
          className="bg-drink-pending text-drink-pending-foreground flex size-8 items-center justify-center rounded-lg [&>svg]:size-4"
          aria-hidden="true"
        >
          <Hourglass />
        </span>
        図鑑待ち
      </Heading>
      <p className="text-muted-foreground mt-2">
        全ユーザーの仮の印。<code>/list?pending=1</code>{' '}
        は本人の図鑑待ちのまま。運営キューではない。
      </p>

      <Card className="border-border mt-6 border-dashed">
        <CardHeader>
          <CardTitle>この画面からは実行しない</CardTitle>
          <CardDescription>
            公開化は drink-seed PR。付け替えは <code>pnpm seed:drinks:merge</code>
            。この画面からは実行しない。
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-3 text-sm">
          <p>
            正本は <code>packages/drink-seed/data/drinks/*.json</code>。画面から{' '}
            <code>published</code> にしない。付け替えは正規化名の完全一致だけ（曖昧寄せなし）。
          </p>
          <pre className="bg-muted overflow-x-auto rounded-lg p-3 text-xs">
            <code>pnpm seed:drinks:merge</code>
          </pre>
        </CardContent>
      </Card>

      <Card className="mt-6">
        <CardHeader>
          <CardTitle>未マージの仮の印</CardTitle>
          <CardDescription>
            visibility=provisional かつ merged_into_id が空。slug にはリンクしない（所有者でも詳細は
            404）。
          </CardDescription>
        </CardHeader>
        <CardContent>
          {rows === null ? (
            <p className="text-muted-foreground text-sm">
              一覧を取得できませんでした。付け替えは上の CLI のままです。
            </p>
          ) : rows.data.length === 0 ? (
            <p className="text-muted-foreground text-sm">未マージの仮の印はありません。</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-max border-collapse text-left text-sm">
                <thead>
                  <tr className="border-border border-b">
                    <th className="py-2 pr-3 font-medium">name</th>
                    <th className="py-2 pr-3 font-medium">name_normalized</th>
                    <th className="py-2 pr-3 font-medium">submitted_by</th>
                    <th className="py-2 pr-3 font-medium">created_at</th>
                    <th className="py-2 font-medium">saved_drinks</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.data.map((row) => {
                    const submitter = submitterLabel(row);
                    const sameName = sameNameCounts?.get(row.nameNormalized) ?? 1;
                    return (
                      <tr key={row.id} className="border-border border-b last:border-0">
                        <td className="py-2 pr-3">
                          <span className="font-medium">{row.name}</span>
                          {sameName > 1 ? (
                            <Badge variant="outline" className="mt-1 block w-fit">
                              同じ正規化名 {sameName}
                            </Badge>
                          ) : null}
                        </td>
                        <td className="py-2 pr-3 font-mono text-xs">{row.nameNormalized}</td>
                        <td className="py-2 pr-3">
                          <div>{submitter.primary}</div>
                          {submitter.secondary ? (
                            <div className="text-muted-foreground text-xs">
                              {submitter.secondary}
                            </div>
                          ) : null}
                        </td>
                        <td className="text-muted-foreground py-2 pr-3 whitespace-nowrap">
                          {formatCreatedAt(row.createdAt)}
                        </td>
                        <td className="py-2">
                          {row.hasSavedDrink ? (
                            <Badge variant="secondary">
                              あり
                              {row.savedStatus
                                ? ` · ${savedDrinkStatusLabel(row.savedStatus)}`
                                : ''}
                            </Badge>
                          ) : (
                            <Badge variant="outline">なし</Badge>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
              <p className="text-muted-foreground mt-3 text-xs">
                {rows.total.toLocaleString('ja-JP')} 件中 {rows.data.length.toLocaleString('ja-JP')}{' '}
                件 · 正規化名 {uniqueNormalized.toLocaleString('ja-JP')} 種類
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
