/**
 * Exports top drink search-miss demand (search_misses, scope='drink') into
 * data/pending.txt for draft.ts, annotated with possible existing-drink
 * duplicates so reviewers don't re-register something that's just hard to find.
 *
 * This is the Phase 3 entry point of the catalog-expansion flow:
 *   search_misses (zero-hit demand)
 *     → export-demand.ts (this file) → data/pending.txt
 *     → draft.ts (AI identity draft, no fabricated facts) → data/drafts/*.json
 *     → human review + fact-check → data/drinks/*.json
 *     → validate.ts → build-seed.ts → supabase/seeds/drinks.sql
 *
 * Requires DATABASE_URL (see AGENTS.md — must include `?sslmode=disable`
 * for local Supabase Postgres). Not run automatically; a human runs this
 * periodically (e.g. weekly) to pull the next batch of candidates.
 *
 * Usage:
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
/** similarity() threshold (pg_trgm, 0–1) above which a drink is flagged as a possible duplicate. */
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

/** DB-side duplicate check via pg_trgm similarity() against drinks.name. */
async function fetchDbDuplicates(client: Client, query: string): Promise<DuplicateCandidate[]> {
  const { rows } = await client.query<{ slug: string; name: string; similarity: number }>(
    `SELECT slug, name, similarity(name, $1) AS similarity
     FROM drinks
     WHERE similarity(name, $1) > $2
     ORDER BY similarity DESC
     LIMIT $3`,
    [query, SIMILARITY_THRESHOLD, MAX_DUPLICATE_CANDIDATES],
  );
  return rows;
}

interface LocalDrinkTerm {
  slug: string;
  name: string;
  terms: string[];
}

/**
 * Loads not-yet-seeded candidates from data/drinks/*.json for a same-script
 * (kana-folded) exact-token check. This catches "already covered but not
 * built/deployed yet" cases that a DB-only check (drinks table) would miss.
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
      // Skip unparseable files; validate.ts is the source of truth for correctness.
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
    // pg_trgm is enabled via migrations/20260806110000_enable_pg_trgm.sql;
    // this tool intentionally avoids issuing DDL over a possibly
    // least-privileged DATABASE_URL connection.
    const demand = await fetchDemand(client, limit);
    if (demand.length === 0) {
      console.log('No drink search-miss demand found.');
      return;
    }

    const localTerms = await loadLocalDrinkTerms();

    const lines: string[] = [];
    lines.push(`# Generated by "pnpm seed:drinks:demand" at ${new Date().toISOString()}`);
    lines.push(`# scope=drink zero-hit demand, top ${demand.length} by miss_count.`);
    lines.push(
      `# Lines starting with "#" are ignored by draft.ts. Uncomment / edit before running draft.`,
    );
    lines.push('');

    let actionable = 0;
    for (const row of demand) {
      const stats = `miss=${row.missCount} unique=${row.uniqueSearchers} last_seen=${row.lastSeenAt}`;
      const localMatch = findLocalMatch(row.queryNormalized, localTerms);
      const dbDuplicates = await fetchDbDuplicates(client, row.sampleQueryRaw);

      if (localMatch) {
        lines.push(
          `# SKIP "${row.sampleQueryRaw}" (${stats}) — likely already covered by data/drinks/${localMatch.slug}.json ("${localMatch.name}"); check aliases before re-adding.`,
        );
        continue;
      }

      if (dbDuplicates.length > 0) {
        const candidateList = dbDuplicates
          .map((d) => `${d.slug} ("${d.name}", sim=${d.similarity.toFixed(2)})`)
          .join(', ');
        lines.push(
          `# REVIEW "${row.sampleQueryRaw}" (${stats}) — possible existing match(es): ${candidateList}. If it's a real duplicate, add an alias to that drink instead of a new record.`,
        );
        continue;
      }

      lines.push(`# ${stats}`);
      lines.push(row.sampleQueryRaw);
      actionable++;
    }

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
