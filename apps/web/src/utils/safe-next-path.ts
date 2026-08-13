/** Allow only same-origin relative paths for post-login redirects. */
export function safeNextPath(raw: string | null | undefined): string {
  if (!raw) return '/';
  const next = raw.trim();
  if (!next.startsWith('/')) return '/';
  if (next.startsWith('//') || next.startsWith('/\\')) return '/';
  if (next.includes('://') || next.includes('\\')) return '/';
  return next;
}
