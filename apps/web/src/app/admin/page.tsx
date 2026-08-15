import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Heading } from '@/components/ui/heading';

export default function AdminPage() {
  return (
    <div className="mx-auto max-w-3xl px-4 py-8">
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
                需要（search_misses）
              </CardTitle>
              <CardDescription>
                フィルタなしのゼロ件検索が需要ログになる。一覧は準備中。
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-2">
              <p>溜まったクエリは CLI で pending に出す。この画面から実行しない。</p>
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
                <Badge variant="secondary">2</Badge>
                仮の印（本人リスト）
              </CardTitle>
              <CardDescription>
                ログイン済みのゼロ件から付く仮の印。全ユーザー横断の一覧は準備中。
              </CardDescription>
            </CardHeader>
            <CardContent>
              <p>
                <code className="text-sm">/list?pending=1</code>{' '}
                は本人の図鑑待ちのまま。運営キューではない。
              </p>
            </CardContent>
          </Card>
        </li>
        <li>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Badge variant="secondary">3</Badge>
                公開は drink-seed PR
              </CardTitle>
              <CardDescription>
                正本は <code>packages/drink-seed/data/drinks/*.json</code>。承認は PR。
              </CardDescription>
            </CardHeader>
            <CardContent>
              <p>
                fact-check して JSON を足し、validate → build のあと PR する。画面から published
                にしない。
              </p>
            </CardContent>
          </Card>
        </li>
        <li>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Badge variant="secondary">4</Badge>
                マージは CLI
              </CardTitle>
              <CardDescription>公開カタログ投入後、仮の印を正規化名で付け替える。</CardDescription>
            </CardHeader>
            <CardContent className="space-y-2">
              <p>公開 HTTP はない。Web から呼ばない。</p>
              <pre className="bg-muted overflow-x-auto rounded-lg p-3 text-xs">
                <code>pnpm seed:drinks:merge</code>
              </pre>
            </CardContent>
          </Card>
        </li>
      </ol>
    </div>
  );
}
