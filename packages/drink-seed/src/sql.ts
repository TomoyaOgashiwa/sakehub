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
