/**
 * normalizeJa の契約テスト。
 *
 * apps/api/internal/searchmiss/normalize.go の NormalizeQuery と
 * normalize.ts の normalizeJa は「ランタイム共有依存ゼロ」方針のため
 * 意図的に二重実装している。同期ずれを検知するため、両方とも
 * testdata/normalize-cases.json（リポジトリルート）に対してテストする。
 *
 * Go 側: cd apps/api && go test ./internal/searchmiss/...
 * TS 側（このファイル）: pnpm --filter @sakehub/drink-seed test
 */

import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { normalizeJa } from './normalize.ts';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const REPO_ROOT = path.resolve(ROOT, '../..');
const FIXTURE_PATH = path.join(REPO_ROOT, 'testdata', 'normalize-cases.json');

interface Fixture {
  cases: Array<{ in: string; want: string }>;
}

async function main(): Promise<void> {
  const raw = await readFile(FIXTURE_PATH, 'utf8');
  const fixture = JSON.parse(raw) as Fixture;

  if (fixture.cases.length === 0) {
    console.error(`No cases found in ${path.relative(REPO_ROOT, FIXTURE_PATH)}`);
    process.exit(1);
  }

  let failures = 0;
  for (const { in: input, want } of fixture.cases) {
    const got = normalizeJa(input);
    if (got !== want) {
      failures++;
      console.error(`normalizeJa(${JSON.stringify(input)}) = ${JSON.stringify(got)}, want ${JSON.stringify(want)}`);
    }
  }

  if (failures > 0) {
    console.error(`${failures}/${fixture.cases.length} case(s) failed.`);
    process.exit(1);
  }
  console.log(`OK: ${fixture.cases.length} normalizeJa case(s) matched NormalizeQuery (Go).`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
