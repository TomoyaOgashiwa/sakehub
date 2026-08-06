/**
 * Offline LLM draft generator for official cocktail data files.
 *
 * This is a **development tool**, not part of the production runtime.
 * AGENTS.md's "LLM calls go through the Go API" rule applies to the product;
 * this script is intentionally opt-in and never runs during `supabase db reset`.
 *
 * Usage:
 *   OPENAI_API_KEY=... pnpm --filter @sakehub/cocktail-seed draft
 *
 * Reads data/pending.txt (one cocktail name or "Name|slug" per line),
 * writes reviewed-ready drafts to data/drafts/*.json in batches of 10.
 * Move approved files to data/cocktails/ after human review, then validate + build.
 */

import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { slugifyAsciiOrFallback } from '@sakehub/seed-utils';

import { INGREDIENT_UNITS, SLUG_PATTERN, type CocktailSeed } from './schema.ts';

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

async function sleep(ms: number): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

async function callOpenAI(apiKey: string, items: PendingItem[]): Promise<CocktailSeed[]> {
  const system = `あなたはカクテル百科の編集者です。実在するクラシック／定番カクテルの公式レシピ下書きを JSON で出力します。
厳守事項:
- 実在するレシピのみ。知らないものは創作せず、そのカクテルを結果から省略する
- 分量は標準的なバーレシピに従う。単位は ml に統一（IBA の cl 表記は使わない）
- 手順は 3〜5 ステップの日本語。各ステップ 1〜500 文字
- description は日本語で 1〜3 文。空にしない
- aliases は日本語・英語の別名配列（空でもよい）
- officialRecipe.name は「{カクテル名}（基本レシピ）」形式
- amount は正の数、適量は amount/unit を null
- unit は次のいずれか: ${INGREDIENT_UNITS.join(', ')}
- id は常に null
- abv はおおよその提供時度数（0–100）または null
出力は JSON 配列のみ。前後に説明文を付けない。`;

  const user = `次のカクテルについて CocktailSeed オブジェクトの配列を返してください。
各要素の形:
{
  "slug": "kebab-case",
  "id": null,
  "name": "日本語名",
  "nameEn": "English name or null",
  "description": "...",
  "baseSpirit": "Gin|Rum|Whisky|Vodka|Tequila|... or null",
  "abv": 12.0,
  "originCountry": "Country or null",
  "aliases": ["別名"],
  "officialRecipe": {
    "name": "名前（基本レシピ）",
    "memo": "コツ（なければ null）",
    "ingredients": [{ "name": "材料", "amount": 45, "unit": "ml" }],
    "steps": ["手順1", "手順2"]
  }
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
        content:
          user +
          '\n\nReturn a JSON object: { "cocktails": [ ... ] }',
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

    const parsed = JSON.parse(content) as { cocktails?: CocktailSeed[] } | CocktailSeed[];
    const list = Array.isArray(parsed) ? parsed : (parsed.cocktails ?? []);
    return list.map((c) => ({
      ...c,
      id: null,
      slug: c.slug && SLUG_PATTERN.test(c.slug) ? c.slug : slugifyAsciiOrFallback(c.name, 'cocktail'),
    }));
  }

  throw lastErr ?? new Error('OpenAI retries exhausted');
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
    console.error(`Missing ${PENDING_PATH}. Add one cocktail name per line.`);
    process.exit(1);
  }

  const pending = parsePending(pendingText);
  if (pending.length === 0) {
    console.log('No pending items.');
    return;
  }

  await mkdir(DRAFTS_DIR, { recursive: true });
  console.log(`Drafting ${pending.length} cocktail(s) in batches of ${BATCH_SIZE}...`);

  for (let i = 0; i < pending.length; i += BATCH_SIZE) {
    const batch = pending.slice(i, i + BATCH_SIZE);
    console.log(`Batch ${i / BATCH_SIZE + 1}: ${batch.map((b) => b.name).join(', ')}`);
    const drafts = await callOpenAI(apiKey, batch);
    for (const draft of drafts) {
      const out = path.join(DRAFTS_DIR, `${draft.slug}.json`);
      await writeFile(out, `${JSON.stringify(draft, null, 2)}\n`, 'utf8');
      console.log(`  wrote ${path.relative(ROOT, out)}`);
    }
  }

  console.log('Done. Review data/drafts/*.json, then move approved files to data/cocktails/.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
