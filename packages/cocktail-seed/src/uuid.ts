import { createHash } from 'node:crypto';

/**
 * Fixed namespace for deterministic cocktail / official-recipe IDs.
 * Same slug always yields the same UUID across regenerations and environments.
 */
export const SAKEHUB_NAMESPACE = '6f1e8c2a-4b9d-5e70-a1c3-8d2f0b7e5a91';

function parseUuidBytes(uuid: string): Buffer {
  const hex = uuid.replace(/-/g, '');
  if (!/^[0-9a-fA-F]{32}$/.test(hex)) {
    throw new Error(`invalid uuid: ${uuid}`);
  }
  return Buffer.from(hex, 'hex');
}

function formatUuid(bytes: Buffer): string {
  const h = bytes.toString('hex');
  return [
    h.slice(0, 8),
    h.slice(8, 12),
    h.slice(12, 16),
    h.slice(16, 20),
    h.slice(20, 32),
  ].join('-');
}

/** RFC 4122 UUIDv5 from name + namespace (SHA-1). Zero runtime deps. */
export function uuidv5(name: string, namespace: string = SAKEHUB_NAMESPACE): string {
  const nsBytes = parseUuidBytes(namespace);
  const hash = createHash('sha1').update(nsBytes).update(name, 'utf8').digest();

  const bytes = Buffer.from(hash.subarray(0, 16));
  // version 5
  bytes[6] = (bytes[6]! & 0x0f) | 0x50;
  // RFC 4122 variant
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;

  return formatUuid(bytes);
}

export function cocktailIdFromSlug(slug: string): string {
  return uuidv5(slug);
}

export function officialRecipeIdFromSlug(slug: string): string {
  return uuidv5(`${slug}:official`);
}

/** Prefer explicit data-file id; otherwise derive from slug. */
export function resolveCocktailId(slug: string, explicitId: string | null): string {
  if (explicitId != null && explicitId !== '') {
    return explicitId;
  }
  return cocktailIdFromSlug(slug);
}
