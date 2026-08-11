/**
 * Upload staged WebP catalog images to Supabase Storage and write imageUrl
 * back into drink/cocktail seed JSON files.
 *
 * Usage:
 *   SUPABASE_URL=https://xxxx.supabase.co SUPABASE_SERVICE_ROLE_KEY=... \
 *     pnpm seed:images:upload
 *
 * Local Storage (127.0.0.1) is refused by default. Pass `--allow-local` only for
 * local experiments — do not commit those imageUrl values into seed.
 */

import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

import { createClient } from '@supabase/supabase-js';
import { isProdSupabaseUrl } from '@sakehub/seed-utils';

import { loadRootEnv } from './load-env.ts';
import {
  BUCKET,
  objectPath,
  publicObjectUrl,
  REPO_ROOT,
  seedJsonPath,
  stagingFile,
  type CatalogKind,
} from './paths.ts';
import { loadPriority } from './priority.ts';

loadRootEnv();

function requireEnv(name: string, aliases: string[] = []): string {
  for (const key of [name, ...aliases]) {
    const value = process.env[key];
    if (value) return value;
  }
  console.error(`${name} is required${aliases.length ? ` (or ${aliases.join(', ')})` : ''}`);
  process.exit(1);
}

/** Merge patch into seed JSON without field whitelists (preserves unknown keys). */
async function patchSeedJson(
  kind: CatalogKind,
  slug: string,
  patch: Record<string, unknown>,
): Promise<void> {
  const file = seedJsonPath(kind, slug);
  const raw = JSON.parse(await readFile(file, 'utf8')) as Record<string, unknown>;
  Object.assign(raw, patch);
  await writeFile(file, `${JSON.stringify(raw, null, 2)}\n`, 'utf8');
}

function contentVersion(bytes: Buffer): string {
  return createHash('sha256').update(bytes).digest('hex').slice(0, 8);
}

async function main(): Promise<void> {
  const allowLocal = process.argv.includes('--allow-local');
  // Public URL base should be the hosted project URL (not localhost) for prod seed imageUrl.
  const supabaseUrl = requireEnv('SUPABASE_URL', ['NEXT_PUBLIC_SUPABASE_URL']);
  const serviceRoleKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY');

  if (!allowLocal && !isProdSupabaseUrl(supabaseUrl)) {
    throw new Error(
      `Refusing non-prod SUPABASE_URL (${supabaseUrl}). ` +
        `Pass a https://*.supabase.co URL, or --allow-local for local-only experiments ` +
        `(do not commit localhost imageUrl into seed).`,
    );
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const items = await loadPriority();
  console.log(`Uploading up to ${items.length} object(s) to bucket ${BUCKET} @ ${supabaseUrl}`);

  let uploaded = 0;
  let missing = 0;

  for (const item of items) {
    const local = stagingFile(item.kind, item.slug);
    let bytes: Buffer;
    try {
      bytes = await readFile(local);
    } catch {
      console.warn(`missing staging file: ${path.relative(REPO_ROOT, local)}`);
      missing += 1;
      continue;
    }

    const remotePath = objectPath(item.kind, item.slug);
    const { error } = await supabase.storage.from(BUCKET).upload(remotePath, bytes, {
      contentType: 'image/webp',
      upsert: true,
      cacheControl: '31536000',
    });

    if (error) {
      throw new Error(`upload failed for ${remotePath}: ${error.message}`);
    }

    const version = contentVersion(bytes);
    const imageUrl = publicObjectUrl(supabaseUrl, item.kind, item.slug, version);
    await patchSeedJson(item.kind, item.slug, {
      imageUrl,
      imageSource: 'generated',
    });
    uploaded += 1;
    console.log(`ok ${remotePath} → ${imageUrl}`);
  }

  console.log(`Done. uploaded=${uploaded} missingStaging=${missing}`);
  console.log('Next: pnpm seed:drinks:validate && pnpm seed:drinks:build');
  console.log('      pnpm seed:cocktails:validate && pnpm seed:cocktails:build');
  console.log('      pnpm supabase:seed:prod');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
