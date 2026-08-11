import { readFile } from 'node:fs/promises';

import { PRIORITY_PATH, type CatalogKind } from './paths.ts';

export interface PriorityItem {
  kind: CatalogKind;
  slug: string;
}

export async function loadPriority(filePath: string = PRIORITY_PATH): Promise<PriorityItem[]> {
  const text = await readFile(filePath, 'utf8');
  const items: PriorityItem[] = [];
  const seen = new Set<string>();

  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;

    const [kindRaw, slugRaw] = line.split('|').map((s) => s.trim());
    if (kindRaw !== 'drink' && kindRaw !== 'cocktail') {
      throw new Error(`Invalid kind in priority list: ${rawLine}`);
    }
    if (!slugRaw || !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slugRaw)) {
      throw new Error(`Invalid slug in priority list: ${rawLine}`);
    }

    const key = `${kindRaw}:${slugRaw}`;
    if (seen.has(key)) {
      throw new Error(`Duplicate priority entry: ${key}`);
    }
    seen.add(key);
    items.push({ kind: kindRaw, slug: slugRaw });
  }

  return items;
}
