/**
 * TypeScript mirror of apps/api/internal/searchmiss/normalize.go's NormalizeQuery.
 * Duplicated intentionally (see packages/cocktail-seed's "zero shared deps"
 * convention) so this offline dev tool has no runtime dependency on the Go
 * module. Keep in sync if the Go implementation changes.
 */

const KATAKANA_TO_HIRAGANA_OFFSET = 0x60;
const KATAKANA_RANGE_START = 0x30a1;
const KATAKANA_RANGE_END = 0x30f6;

export function normalizeJa(raw: string): string {
  const nfkc = raw.normalize('NFKC').toLowerCase();

  let out = '';
  for (const ch of nfkc) {
    const code = ch.codePointAt(0)!;

    if (ch === '・' || ch === '･' || ch === '·') continue;
    if (ch === 'ー' || ch === 'ｰ') continue;
    if (/\s/.test(ch)) continue;

    if (code >= KATAKANA_RANGE_START && code <= KATAKANA_RANGE_END) {
      out += String.fromCodePoint(code - KATAKANA_TO_HIRAGANA_OFFSET);
      continue;
    }

    out += ch;
  }
  return out;
}
