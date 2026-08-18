import 'server-only';

import type { SupabaseClient, User } from '@supabase/supabase-js';

import type { AppRole } from '@/lib/auth/app-role';

export const OFFICIAL_ACCOUNT_EMAIL = 'official@sakehub.app';

interface DeletionBlockInput {
  user: User;
  appRole: AppRole | null;
  supabase: SupabaseClient;
}

/**
 * 運営セルフ退会を塞ぐ。判定不能（公式レシピ照会失敗）もブロックする。
 */
export async function isAccountDeletionBlocked({
  user,
  appRole,
  supabase,
}: DeletionBlockInput): Promise<boolean> {
  if (appRole === 'admin') return true;
  if (user.email === OFFICIAL_ACCOUNT_EMAIL) return true;

  const { data, error } = await supabase
    .from('cocktail_recipes')
    .select('id')
    .eq('user_id', user.id)
    .eq('is_official', true)
    .limit(1)
    .maybeSingle();

  if (error) return true;
  return data != null;
}
