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
