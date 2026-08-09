/**
 * Generate Phase 1 catalog WebP images via OpenAI Images API.
 *
 * Usage:
 *   OPENAI_API_KEY=... pnpm seed:images:generate
 *   OPENAI_API_KEY=... pnpm seed:images:generate -- --force
 *
 * Writes to data/staging/{drinks|cocktails}/{slug}.webp (gitignored).
 * Skips existing staging files unless --force is passed.
 */

import { access, mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';

import { loadRootEnv } from './load-env.ts';
import { STAGING_DIR, stagingFile } from './paths.ts';
import { loadPriority } from './priority.ts';
import { buildPrompt } from './prompts.ts';

loadRootEnv();

const MODEL = process.env.OPENAI_IMAGE_MODEL ?? 'gpt-image-1.5';
const QUALITY = 'medium' as const;
const SIZE = '1024x1024' as const;
const OUTPUT_FORMAT = 'webp' as const;
const OUTPUT_COMPRESSION = 80;
const MAX_RETRIES = 4;
const API_URL = 'https://api.openai.com/v1/images/generations';

function hasFlag(flag: string): boolean {
  return process.argv.includes(flag);
}

async function exists(filePath: string): Promise<boolean> {
  try {
    await access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function sleep(ms: number): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

async function generateOne(apiKey: string, prompt: string): Promise<Buffer> {
  let lastError: unknown;
  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    const res = await fetch(API_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: MODEL,
        prompt,
        n: 1,
        size: SIZE,
        quality: QUALITY,
        output_format: OUTPUT_FORMAT,
        output_compression: OUTPUT_COMPRESSION,
      }),
    });

    if (res.status === 429 || res.status >= 500) {
      const backoff = Math.min(30_000, 1_000 * 2 ** attempt);
      console.warn(`  retryable ${res.status}, waiting ${backoff}ms...`);
      await sleep(backoff);
      lastError = new Error(`HTTP ${res.status}: ${await res.text()}`);
      continue;
    }

    if (!res.ok) {
      throw new Error(`OpenAI images error ${res.status}: ${await res.text()}`);
    }

    const json = (await res.json()) as {
      data?: Array<{ b64_json?: string }>;
    };
    const b64 = json.data?.[0]?.b64_json;
    if (!b64) {
      throw new Error('OpenAI response missing data[0].b64_json');
    }
    return Buffer.from(b64, 'base64');
  }

  throw lastError instanceof Error ? lastError : new Error(String(lastError));
}

async function main(): Promise<void> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    console.error('OPENAI_API_KEY is required');
    process.exit(1);
  }

  const force = hasFlag('--force');
  const items = await loadPriority();
  await mkdir(path.join(STAGING_DIR, 'drinks'), { recursive: true });
  await mkdir(path.join(STAGING_DIR, 'cocktails'), { recursive: true });

  console.log(
    `Generating ${items.length} image(s) with ${MODEL} quality=${QUALITY} size=${SIZE} format=${OUTPUT_FORMAT}`,
  );

  let generated = 0;
  let skipped = 0;

  for (const item of items) {
    const out = stagingFile(item.kind, item.slug);
    if (!force && (await exists(out))) {
      console.log(`skip ${item.kind}/${item.slug} (exists)`);
      skipped += 1;
      continue;
    }

    const prompt = await buildPrompt(item.kind, item.slug);
    console.log(`generate ${item.kind}/${item.slug}`);
    const buf = await generateOne(apiKey, prompt);
    await mkdir(path.dirname(out), { recursive: true });
    await writeFile(out, buf);
    generated += 1;
    console.log(`  wrote ${path.relative(process.cwd(), out)} (${buf.byteLength} bytes)`);
  }

  console.log(`Done. generated=${generated} skipped=${skipped}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
