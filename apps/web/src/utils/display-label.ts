export const DISPLAY_NAME_MAX_LENGTH = 50;

/**
 * 公開面の表示名。空の display_name は出さない。
 * trim して非空の display_name → email local-part → 'User'
 */
export function resolveDisplayLabel(
  displayName: string | null | undefined,
  email: string | null | undefined,
): string {
  const trimmedName = displayName?.trim();
  if (trimmedName) return trimmedName;

  const localPart = email?.split('@')[0]?.trim();
  if (localPart) return localPart;

  return 'User';
}
