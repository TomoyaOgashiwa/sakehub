/** Escape a string as a PostgreSQL single-quoted literal (apostrophes doubled). */
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

/** Render a string array as a PostgreSQL `ARRAY[...]::TEXT[]` literal. */
export function quoteTextArrayLiteral(values: string[]): string {
  if (values.length === 0) return "'{}'::TEXT[]";
  return `ARRAY[${values.map(quoteLiteral).join(', ')}]::TEXT[]`;
}
