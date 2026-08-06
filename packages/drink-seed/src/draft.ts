/**
 * drinks データファイル向けのオフライン LLM 下書き生成。
 *
 * これは **開発ツール** であり、本番ランタイムの一部ではない。
 * AGENTS.md の「LLM 呼び出しは Go API 経由」はプロダクト向けの規約で、
 * 本スクリプトは意図的にオプトインであり `supabase db reset` では動かない。
 *
 * 重要 — 生成フィールドの制限:
 * LLM は日本酒・ウイスキーの事実（ABV、蔵元・蒸留所、産地、熟成年数）を
 * 自信満々に捏造しやすい。そのため本スクリプトは識別・検索性に関わる
 * フィールド（name, nameEn, category, slug, aliases）だけをモデルに依頼し、
 * abv / manufacturer / originCountry / description は常に null のままにする。
 * data/drafts/ から data/drinks/ へ移す前に、人が一次ソース（公式商品ページ、
 * ラベル等）からこれらを埋めること。
 *
 * 使い方:
 *   OPENAI_API_KEY=... pnpm --filter @sakehub/drink-seed draft
 *
 * data/pending.txt を読む（1行1ドリンク名。"Name|slug" 可。`#` 始まりは無視。
 * 詳細は export-demand.ts）。10件バッチで data/drafts/*.json に書き出す。
 * 人手レビューと事実確認のあと、承認済みファイルを data/drinks/ へ移し、
 * validate → build する。
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
