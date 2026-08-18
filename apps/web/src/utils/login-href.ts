import { safeNextPath } from '@/utils/safe-next-path';

/** Login URL with `next` always encoded so nested query (e.g. cocktail_id) stays on next, not on login. */
export function loginHref(next: string): string {
  return `/login?next=${encodeURIComponent(safeNextPath(next))}`;
}
