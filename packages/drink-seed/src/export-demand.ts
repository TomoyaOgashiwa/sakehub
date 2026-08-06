/**
 * drink 検索のゼロヒット需要（search_misses, scope='drink'）上位を
 * draft.ts 向けの data/pending.txt へ出力する。既存ドリンクとの重複候補も
 * 注記し、検索しづらいだけで再登録してしまうのを防ぐ。
 *
 * カタログ拡充フロー（Phase 3）の入口:
 *   search_misses（ゼロヒット需要）
 *     → export-demand.ts（本ファイル）→ data/pending.txt
 *     → draft.ts（AI 識別情報下書き。事実の捏造なし）→ data/drafts/*.json
 *     → 人手レビュー + 事実確認 → data/drinks/*.json
 *     → validate.ts → build-seed.ts → supabase/seeds/drinks.sql
 *
 * DATABASE_URL が必要（AGENTS.md 参照。ローカル Supabase Postgres では
 * `?sslmode=disable` 必須）。自動実行はせず、人が週次などで次バッチを
 * 取り込むときに動かす。
 *
 * 使い方:
 *   DATABASE_URL=postgresql://... pnpm --filter @sakehub/drink-seed demand [limit]
 */

import { readFile, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { Client } from 'pg';

import { normalizeJa } from './normalize.ts';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const DATA_DIR = path.join(ROOT, 'data', 'drinks');
const PENDING_PATH = path.join(ROOT, 'data', 'pending.txt');

const DEFAULT_LIMIT = 20;
/** similarity()（pg_trgm, 0–1）の閾値。これを超えると重複候補としてフラグする。 */
const SIMILARITY_THRESHOLD = 0.3;
const MAX_DUPLICATE_CANDIDATES = 3;

interface DemandRow {
  queryNormalized: string;
  sampleQueryRaw: string;
  missCount: number;
  uniqueSearchers: number;
  lastSeenAt: string;
}

interface DuplicateCandidate {
  slug: string;
  name: string;
  similarity: number;
}

async function fetchDemand(client: Client, limit: number): Promise<DemandRow[]> {
  const { rows } = await client.query<{
    query_normalized: string;
    sample_query_raw: string;
    miss_count: string;
    unique_searchers: string;
    last_seen_at: string;
  }>(
    `SELECT
       sm.query_normalized,
       (ARRAY_AGG(sm.query_raw ORDER BY sm.created_at DESC))[1] AS sample_query_raw,
       COUNT(*)::int AS miss_count,
       COUNT(DISTINCT COALESCE(sm.user_id::text, sm.client_hash))::int AS unique_searchers,
       MAX(sm.created_at) AS last_seen_at
     FROM search_misses sm
     WHERE sm.scope = 'drink' AND sm.result_count = 0
     GROUP BY sm.query_normalized
     ORDER BY miss_count DESC, unique_searchers DESC
     LIMIT $1`,
    [limit],
  );

  return rows.map((r) => ({
    queryNormalized: r.query_normalized,
    sampleQueryRaw: r.sample_query_raw,
    missCount: Number(r.miss_count),
    uniqueSearchers: Number(r.unique_searchers),
    lastSeenAt: r.last_seen_at,
  }));
}

/**
 * drinks.name と aliases に対する pg_trgm similarity() による DB 側の
 * 重複候補チェック。name だけを見ると、「だっさい」のようなかなクエリは
 * 「獺祭」という漢字表記との類似度が低く出て、既に aliases に
 * かな読みが登録済みでも「要確認」に落ちない。aliases の各要素との
 * 類似度も取り、より高い方を採用する。
 *
 * `queries` は demand 行ごとにまとめて渡す。以前は行ごとに個別クエリを
 * 発行していた（N+1）が、`unnest(...) WITH ORDINALITY` + `LATERAL` で
 * 1 回のラウンドトリップに集約する。返り値は入力 `queries` と同じ順序の
 * 配列（各要素がその queries[i] に対する重複候補リスト）。
 */
async function fetchDbDuplicatesBatch(
  client: Client,
  queries: string[],
): Promise<DuplicateCandidate[][]> {
  if (queries.length === 0) return [];

  const { rows } = await client.query<{
    idx: string;
    slug: string;
    name: string;
    similarity: number;
  }>(
    `SELECT t.idx, d.slug, d.name, d.similarity
     FROM unnest($1::text[]) WITH ORDINALITY AS t(term, idx)
     JOIN LATERAL (
       SELECT slug, name,
         GREATEST(
           similarity(name, t.term),
           COALESCE((SELECT max(similarity(a, t.term)) FROM unnest(aliases) a), 0)
         ) AS similarity
       FROM drinks
       WHERE similarity(name, t.term) > $2
          OR EXISTS (SELECT 1 FROM unnest(aliases) a WHERE similarity(a, t.term) > $2)
       ORDER BY similarity DESC
       LIMIT $3
     ) d ON true
     ORDER BY t.idx, d.similarity DESC`,
    [queries, SIMILARITY_THRESHOLD, MAX_DUPLICATE_CANDIDATES],
  );

  const byIdx = new Map<number, DuplicateCandidate[]>();
  for (const row of rows) {
    const idx = Number(row.idx) - 1; // WITH ORDINALITY is 1-indexed
    const list = byIdx.get(idx) ?? [];
    list.push({ slug: row.slug, name: row.name, similarity: row.similarity });
    byIdx.set(idx, list);
  }

  return queries.map((_, i) => byIdx.get(i) ?? []);
}

interface LocalDrinkTerm {
  slug: string;
  name: string;
  terms: string[];
}

/**
 * data/drinks/*.json から、かな畳み込み後の完全一致チェック用用語を読む。
 * DB のみのチェック（drinks テーブル）では拾えない
 * 「JSON にはあるがまだ build/deploy されていない」ケースを拾う。
 */
async function loadLocalDrinkTerms(): Promise<LocalDrinkTerm[]> {
  let entries: string[];
  try {
    entries = (await readdir(DATA_DIR)).filter((f) => f.endsWith('.json'));
  } catch {
    return [];
  }

  const result: LocalDrinkTerm[] = [];
  for (const entry of entries) {
    try {
      const raw = JSON.parse(await readFile(path.join(DATA_DIR, entry), 'utf8')) as {
        slug?: unknown;
        name?: unknown;
        nameEn?: unknown;
        aliases?: unknown;
      };
      const slug = typeof raw.slug === 'string' ? raw.slug : entry;
      const name = typeof raw.name === 'string' ? raw.name : entry;
      const terms = [raw.name, raw.nameEn, ...(Array.isArray(raw.aliases) ? raw.aliases : [])]
        .filter((v): v is string => typeof v === 'string')
        .map(normalizeJa);
      result.push({ slug, name, terms });
    } catch {
      // パース不能なファイルはスキップ。正しさの検証は validate.ts が担う。
    }
  }
  return result;
}

function findLocalMatch(normalized: string, local: LocalDrinkTerm[]): LocalDrinkTerm | null {
  return local.find((d) => d.terms.includes(normalized)) ?? null;
}

async function main(): Promise<void> {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    console.error(
      'DATABASE_URL is required (see AGENTS.md, must include ?sslmode=disable locally).',
    );
    process.exit(1);
  }

  const limitArg = process.argv[2];
  const limit = limitArg ? Number(limitArg) : DEFAULT_LIMIT;
  if (!Number.isInteger(limit) || limit <= 0) {
    console.error('limit must be a positive integer');
    process.exit(1);
  }

  const client = new Client({ connectionString });
  await client.connect();

  try {
    // pg_trgm は migrations/20260806110000_enable_pg_trgm.sql で有効化済み。
    // 権限の弱い DATABASE_URL 接続で DDL を発行しないよう、本ツールでは触らない。
    const demand = await fetchDemand(client, limit);
    if (demand.length === 0) {
      console.log('No drink search-miss demand found.');
      return;
    }

    const localTerms = await loadLocalDrinkTerms();

    const lines: string[] = [];
    lines.push(`# "pnpm seed:drinks:demand" が ${new Date().toISOString()} に生成`);
    lines.push(`# scope=drink のゼロヒット需要。miss_count 上位 ${demand.length} 件。`);
    lines.push(
      `# "#" で始まる行は draft.ts が無視する。draft 実行前にコメント解除 / 編集すること。`,
    );
    lines.push('');

    // ローカル完全一致でスキップ確定な行は DB 側の類似度チェックが不要。
    // 残りだけをまとめて1回のクエリで引く（N+1 回避）。
    const localMatches = demand.map((row) => findLocalMatch(row.queryNormalized, localTerms));
    const needsDbCheckIndexes = demand
      .map((_, i) => i)
      .filter((i) => localMatches[i] === null);
    const dbDuplicatesBatch = await fetchDbDuplicatesBatch(
      client,
      needsDbCheckIndexes.map((i) => demand[i].sampleQueryRaw),
    );
    const dbDuplicatesByIndex = new Map<number, DuplicateCandidate[]>();
    needsDbCheckIndexes.forEach((originalIdx, batchIdx) => {
      dbDuplicatesByIndex.set(originalIdx, dbDuplicatesBatch[batchIdx]);
    });

    let actionable = 0;
    demand.forEach((row, i) => {
      const stats = `miss=${row.missCount} unique=${row.uniqueSearchers} last_seen=${row.lastSeenAt}`;
      const localMatch = localMatches[i];

      if (localMatch) {
        lines.push(
          `# スキップ "${row.sampleQueryRaw}" (${stats}) — data/drinks/${localMatch.slug}.json（「${localMatch.name}」）で既にカバー済みの可能性が高い。再追加する前に aliases を確認すること。`,
        );
        return;
      }

      const dbDuplicates = dbDuplicatesByIndex.get(i) ?? [];
      if (dbDuplicates.length > 0) {
        const candidateList = dbDuplicates
          .map((d) => `${d.slug}（「${d.name}」, sim=${d.similarity.toFixed(2)}）`)
          .join(', ');
        lines.push(
          `# 要確認 "${row.sampleQueryRaw}" (${stats}) — 既存候補: ${candidateList}。重複なら新規レコードではなくその drinks に alias を追加すること。`,
        );
        return;
      }

      lines.push(`# ${stats}`);
      lines.push(row.sampleQueryRaw);
      actionable++;
    });

    await writeFile(PENDING_PATH, lines.join('\n') + '\n', 'utf8');
    console.log(
      `Wrote ${path.relative(ROOT, PENDING_PATH)}: ${actionable} actionable, ${demand.length - actionable} flagged as possible duplicates.`,
    );
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
