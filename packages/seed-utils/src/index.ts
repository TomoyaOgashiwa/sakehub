/**
 * drink-seed / cocktail-seed で共有する純粋ユーティリティ。
 *
 * どちらのパッケージも「ランタイム共有依存ゼロ」を志向していたため
 * quoteLiteral 系 / assertAliases / slugify がバイト一致で二重管理されて
 * いた（Bugbot 指摘）。ここに寄せることで更新漏れを防ぐ。
 *
 * `DRINK_CATEGORIES` は `@sakehub/types`（→ Web/Mobile バンドラ経由）からも
 * import されるため、このファイルは Node 組み込みモジュール（`node:*`）に
 * 依存しない。React Native の Metro バンドラは `node:crypto` 等をポリフィル
 * せずビルド不能にするため、slug のフォールバックハッシュも
 * 依存ゼロの軽量ハッシュ（FNV-1a）で実装している。
 * Node の `--experimental-strip-types` 生実行（drink-seed/cocktail-seed）
 * からも、バンドラ経由（apps/web/apps/mobile）からも問題なく import できる。
 */

// ---------------------------------------------------------------------------
// SQL literal quoting
// ---------------------------------------------------------------------------

/** 文字列を PostgreSQL のシングルクォートリテラルとしてエスケープする（' は二重化）。 */
export function quoteLiteral(value: string): string {
  return `'${value.replace(/'/g, "''")}'`;
}

export function quoteNullableLiteral(value: string | null | undefined): string {
  if (value == null) return 'NULL';
  return quoteLiteral(value);
}

export function quoteNullableNumber(value: number | null | undefined): string {
  if (value == null) return 'NULL';
  if (!Number.isFinite(value)) {
    throw new Error(`non-finite number: ${value}`);
  }
  return String(value);
}

/** 文字列配列を PostgreSQL の `ARRAY[...]::TEXT[]` リテラルとして出力する。 */
export function quoteTextArrayLiteral(values: string[]): string {
  if (values.length === 0) return "'{}'::TEXT[]";
  return `ARRAY[${values.map(quoteLiteral).join(', ')}]::TEXT[]`;
}

// ---------------------------------------------------------------------------
// aliases quality validation
// ---------------------------------------------------------------------------

export interface ValidationIssue {
  file: string;
  field: string;
  message: string;
}

/** 個々の alias の最大長。かな読み・ローマ字表記・略称を想定した緩めの上限。 */
const MAX_ALIAS_LENGTH = 100;

function runeLength(s: string): number {
  return [...s].length;
}

/**
 * aliases の品質チェック。空文字・空白のみ・要素ごとの最大長・重複
 * （大小文字を無視）・件数上限（DB の `chk_*_aliases_length` と同期させた
 * `max`）を検出する。
 */
export function assertAliases(
  file: string,
  aliases: unknown,
  max: number,
  issues: ValidationIssue[],
): void {
  if (!Array.isArray(aliases) || !aliases.every((a) => typeof a === 'string')) {
    issues.push({ file, field: 'aliases', message: 'must be an array of strings' });
    return;
  }

  if (aliases.length > max) {
    issues.push({
      file,
      field: 'aliases',
      message: `must have at most ${max} entries`,
    });
  }

  const seen = new Set<string>();
  aliases.forEach((alias, i) => {
    const trimmed = alias.trim();
    if (trimmed === '') {
      issues.push({
        file,
        field: `aliases[${i}]`,
        message: 'must not be empty or whitespace-only',
      });
      return;
    }
    if (runeLength(trimmed) > MAX_ALIAS_LENGTH) {
      issues.push({
        file,
        field: `aliases[${i}]`,
        message: `must be at most ${MAX_ALIAS_LENGTH} characters`,
      });
    }
    const key = trimmed.toLowerCase();
    if (seen.has(key)) {
      issues.push({ file, field: `aliases[${i}]`, message: `duplicate alias "${trimmed}"` });
    } else {
      seen.add(key);
    }
  });
}

// ---------------------------------------------------------------------------
// slug generation
// ---------------------------------------------------------------------------

/** これ未満の ASCII 文字数、または英字を1つも含まない slug は弱い（衝突・可読性リスク）とみなす。 */
const MIN_USABLE_SLUG_LENGTH = 3;

/**
 * 依存ゼロの決定的ハッシュ（FNV-1a, 32bit）。暗号強度は不要（フォールバック
 * slug の一意性確保が目的）で、`node:crypto` を避けるためだけに使う。
 */
function fnv1aHex(input: string): string {
  let hash = 0x811c9dc5;
  for (let i = 0; i < input.length; i++) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193);
  }
  return (hash >>> 0).toString(16).padStart(8, '0');
}

/**
 * 商品名から ASCII kebab-case slug を作る。CJK 専用の名前（「獺祭」等）は
 * ASCII 除去で空文字になり、「山崎12年」のような英数混在名は数字だけの
 * 弱い slug（"12"）になりやすい。どちらも `SLUG_PATTERN` は満たすが
 * 衝突しやすく可読性もないため、決定的なフォールバック
 * （name の FNV-1a ハッシュ, `${fallbackPrefix}-<hash>`）に切り替える。
 */
export function slugifyAsciiOrFallback(name: string, fallbackPrefix: string): string {
  const base = name
    .normalize('NFKD')
    .replace(/[^\u0020-\u007E]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80);

  const isUsable = base.length >= MIN_USABLE_SLUG_LENGTH && /[a-z]/.test(base);
  if (isUsable) return base;

  const hash = fnv1aHex(name);
  const reason = base ? `a weak ASCII slug ("${base}")` : 'an empty ASCII slug';
  console.warn(`slugify: "${name}" produced ${reason}; falling back to ${fallbackPrefix}-${hash}`);
  return `${fallbackPrefix}-${hash}`;
}

// ---------------------------------------------------------------------------
// category taxonomy
// ---------------------------------------------------------------------------

/**
 * drinks.category の CHECK 制約
 * （supabase/migrations/20260515210611_create_drinks.sql）と一致させる。
 * `@sakehub/types` の `DRINK_CATEGORIES`（'all' を含む UI 向け一覧）は
 * ここから `['all', ...DRINK_CATEGORIES]` として導出する（single source）。
 */
export const DRINK_CATEGORIES = [
  'beer',
  'wine',
  'whisky',
  'sake',
  'shochu',
  'vodka',
  'gin',
  'rum',
  'tequila',
  'brandy',
  'liqueur',
  'other',
] as const;

export type DrinkCategory = (typeof DRINK_CATEGORIES)[number];
