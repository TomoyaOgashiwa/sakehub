import path from 'node:path';
import { fileURLToPath } from 'node:url';

export type CatalogKind = 'drink' | 'cocktail';

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const REPO_ROOT = path.resolve(ROOT, '../..');
export const PRIORITY_PATH = path.join(ROOT, 'data', 'priority.txt');
export const STAGING_DIR = path.join(ROOT, 'data', 'staging');

export const BUCKET = 'catalog-images';

export function objectPath(kind: CatalogKind, slug: string): string {
  return `${kind === 'drink' ? 'drinks' : 'cocktails'}/${slug}.webp`;
}

export function stagingFile(kind: CatalogKind, slug: string): string {
  return path.join(STAGING_DIR, kind === 'drink' ? 'drinks' : 'cocktails', `${slug}.webp`);
}

export function seedJsonPath(kind: CatalogKind, slug: string): string {
  if (kind === 'drink') {
    return path.join(REPO_ROOT, 'packages', 'drink-seed', 'data', 'drinks', `${slug}.json`);
  }
  return path.join(REPO_ROOT, 'packages', 'cocktail-seed', 'data', 'cocktails', `${slug}.json`);
}

export function publicObjectUrl(supabaseUrl: string, kind: CatalogKind, slug: string): string {
  const base = supabaseUrl.replace(/\/$/, '');
  return `${base}/storage/v1/object/public/${BUCKET}/${objectPath(kind, slug)}`;
}
