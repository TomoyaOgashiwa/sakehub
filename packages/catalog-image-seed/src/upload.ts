/**
 * Upload staged WebP catalog images to Supabase Storage and write imageUrl
 * back into drink/cocktail seed JSON files.
 *
 * Usage:
 *   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... pnpm seed:images:upload
 *
 * Prefer the linked (prod) project URL. Local Storage sync is out of scope.
 */

import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

import { createClient } from '@supabase/supabase-js';

import { loadRootEnv } from './load-env.ts';
import {
  BUCKET,
  objectPath,
  publicObjectUrl,
  REPO_ROOT,
  seedJsonPath,
  stagingFile,
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

async function setImageUrl(kind: 'drink' | 'cocktail', slug: string, imageUrl: string): Promise<void> {
  const file = seedJsonPath(kind, slug);
  const raw = JSON.parse(await readFile(file, 'utf8')) as Record<string, unknown>;
  raw.imageUrl = imageUrl;
  raw.imageSource = 'generated';

  // Keep a stable-ish key order for drinks (existing shape) and cocktails.
  if (kind === 'cocktail') {
    const ordered: Record<string, unknown> = {
      slug: raw.slug,
      id: raw.id ?? null,
      name: raw.name,
      nameEn: raw.nameEn ?? null,
      description: raw.description,
      baseSpirit: raw.baseSpirit ?? null,
      abv: raw.abv ?? null,
      originCountry: raw.originCountry ?? null,
      imageUrl,
      imageSource: 'generated',
      aliases: raw.aliases ?? [],
      officialRecipe: raw.officialRecipe,
    };
    await writeFile(file, `${JSON.stringify(ordered, null, 2)}\n`, 'utf8');
    return;
  }

  await writeFile(file, `${JSON.stringify(raw, null, 2)}\n`, 'utf8');
}

async function main(): Promise<void> {
  // Public URL base should be the hosted project URL (not localhost) for prod seed imageUrl.
  const supabaseUrl = requireEnv('SUPABASE_URL', ['NEXT_PUBLIC_SUPABASE_URL']);
  const serviceRoleKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY');

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

    const imageUrl = publicObjectUrl(supabaseUrl, item.kind, item.slug);
    await setImageUrl(item.kind, item.slug, imageUrl);
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
