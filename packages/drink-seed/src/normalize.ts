/**
 * apps/api/internal/searchmiss/normalize.go の NormalizeQuery の TypeScript 実装。
 * packages/cocktail-seed の「ランタイム共有依存ゼロ」方針に合わせ、意図的に
 * 複製している（Go モジュールへの実行時依存を持たせない）。Go 側の実装を
 * 変えた場合はここも同期すること。
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
