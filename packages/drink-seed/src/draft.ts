/**
 * Offline LLM draft generator for drink data files.
 *
 * This is a **development tool**, not part of the production runtime.
 * AGENTS.md's "LLM calls go through the Go API" rule applies to the product;
 * this script is intentionally opt-in and never runs during `supabase db reset`.
 *
 * IMPORTANT — restricted fields:
 * LLMs confidently fabricate facts about sake/whisky (ABV, brewery/distillery,
 * origin prefecture, aging years). This script therefore only asks the model
 * for identity/searchability fields (name, nameEn, category, slug, aliases)
 * and always leaves abv / manufacturer / originCountry / description as null.
 * A human must fill those in from a primary source (official product page,
 * label, etc.) before the file moves from data/drafts/ to data/drinks/.
 *
 * Usage:
 *   OPENAI_API_KEY=... pnpm --filter @sakehub/drink-seed draft
 *
 * Reads data/pending.txt (one drink name per line, "Name|slug" optional,
 * lines starting with "#" ignored — see export-demand.ts), writes drafts to
 * data/drafts/*.json in batches of 10. Move approved + fact-checked files to
 * data/drinks/ after human review, then validate + build.
 */

import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { DRINK_CATEGORIES, SLUG_PATTERN, type DrinkSeed } from './schema.ts';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const PENDING_PATH = path.join(ROOT, 'data', 'pending.txt');
const DRAFTS_DIR = path.join(ROOT, 'data', 'drafts');

const BATCH_SIZE = 10;
const MAX_RETRIES = 4;
const MODEL = process.env.OPENAI_MODEL ?? 'gpt-4o-mini';

interface PendingItem {
  name: string;
  slugHint: string | null;
}

interface DraftIdentity {
  slug: string;
  name: string;
  nameEn: string | null;
  category: string;
  aliases: string[];
}

function parsePending(text: string): PendingItem[] {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'))
    .map((line) => {
      const [namePart, slugPart] = line.split('|').map((s) => s.trim());
      return {
        name: namePart ?? line,
        slugHint: slugPart && SLUG_PATTERN.test(slugPart) ? slugPart : null,
      };
    });
}

function slugify(name: string): string {
  return name
    .normalize('NFKD')
    .replace(/[^\u0020-\u007E]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80);
}

async function sleep(ms: number): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

async function callOpenAI(apiKey: string, items: PendingItem[]): Promise<DraftIdentity[]> {
  const system = `あなたはお酒カタログの編集アシスタントです。実在する市販のお酒について、
「検索で見つけやすくするための識別情報」だけを JSON で出力します。
厳守事項:
- 実在する商品のみ。知らないものは創作せず、その商品を結果から省略する
- category は次のいずれか: ${DRINK_CATEGORIES.join(', ')}
- aliases はかな読み・ローマ字表記・略称など、検索で入力されそうな表記ゆれの配列（空でもよい）
- 度数(abv)・製造元(manufacturer)・産地(originCountry)・説明文(description) は
  **絶対に生成しない**。事実を誤って断定するリスクが高いため、この工程では扱わない
- 出力は JSON 配列のみ。前後に説明文を付けない`;

  const user = `次のお酒について識別情報オブジェクトの配列を返してください。
各要素の形:
{
  "slug": "kebab-case",
  "name": "日本語表記の正式名称（商品名。SKU/expression レベルで区別する。例: 「山崎12年」と「山崎NAS」は別物）",
  "nameEn": "English name or null",
  "category": "${DRINK_CATEGORIES.join('|')}",
  "aliases": ["かな読み", "略称など"]
}

対象:
${items.map((it, i) => `${i + 1}. ${it.name}${it.slugHint ? ` (slug hint: ${it.slugHint})` : ''}`).join('\n')}`;

  const body = {
    model: MODEL,
    temperature: 0.2,
    response_format: { type: 'json_object' },
    messages: [
      { role: 'system', content: system },
      {
        role: 'user',
        content: user + '\n\nReturn a JSON object: { "drinks": [ ... ] }',
      },
    ],
  };

  let lastErr: unknown;
  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (res.status === 429 || res.status >= 500) {
      const backoff = Math.min(30_000, 1000 * 2 ** attempt);
      console.warn(`OpenAI ${res.status}, retry in ${backoff}ms...`);
      await sleep(backoff);
      lastErr = new Error(`HTTP ${res.status}`);
      continue;
    }

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`OpenAI error ${res.status}: ${text}`);
    }

    const json = (await res.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const content = json.choices?.[0]?.message?.content;
    if (!content) throw new Error('empty OpenAI response');

    const parsed = JSON.parse(content) as { drinks?: DraftIdentity[] } | DraftIdentity[];
    const list = Array.isArray(parsed) ? parsed : (parsed.drinks ?? []);
    return list.map((d) => ({
      ...d,
      slug: d.slug && SLUG_PATTERN.test(d.slug) ? d.slug : slugify(d.name),
    }));
  }

  throw lastErr ?? new Error('OpenAI retries exhausted');
}

function toDraftSeed(identity: DraftIdentity): DrinkSeed {
  const category = DRINK_CATEGORIES.includes(identity.category as (typeof DRINK_CATEGORIES)[number])
    ? (identity.category as (typeof DRINK_CATEGORIES)[number])
    : 'other';

  return {
    slug: identity.slug,
    name: identity.name,
    nameEn: identity.nameEn ?? null,
    category,
    subcategory: null,
    // 意図的に空文字のまま。事実系フィールドは人が一次ソースを確認して埋める。
    description: '',
    imageUrl: null,
    abv: null,
    originCountry: null,
    manufacturer: null,
    aliases: identity.aliases ?? [],
  };
}

async function main(): Promise<void> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    console.error('OPENAI_API_KEY is required');
    process.exit(1);
  }

  let pendingText: string;
  try {
    pendingText = await readFile(PENDING_PATH, 'utf8');
  } catch {
    console.error(`Missing ${PENDING_PATH}. Run "pnpm seed:drinks:demand" or add lines manually.`);
    process.exit(1);
  }

  const pending = parsePending(pendingText);
  if (pending.length === 0) {
    console.log('No pending items.');
    return;
  }

  await mkdir(DRAFTS_DIR, { recursive: true });
  console.log(`Drafting ${pending.length} drink(s) in batches of ${BATCH_SIZE}...`);

  for (let i = 0; i < pending.length; i += BATCH_SIZE) {
    const batch = pending.slice(i, i + BATCH_SIZE);
    console.log(`Batch ${i / BATCH_SIZE + 1}: ${batch.map((b) => b.name).join(', ')}`);
    const identities = await callOpenAI(apiKey, batch);
    for (const identity of identities) {
      const draft = toDraftSeed(identity);
      const out = path.join(DRAFTS_DIR, `${draft.slug}.json`);
      await writeFile(out, `${JSON.stringify(draft, null, 2)}\n`, 'utf8');
      console.log(
        `  wrote ${path.relative(ROOT, out)} (abv/manufacturer/originCountry/description are null — fill in manually)`,
      );
    }
  }

  console.log(
    'Done. Fact-check + fill description/abv/manufacturer/originCountry by hand, then move to data/drinks/.',
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
