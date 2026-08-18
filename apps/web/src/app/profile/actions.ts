'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';

import { isAccountDeletionBlocked } from '@/lib/auth/account-deletion';
import { getAuthProfile } from '@/lib/auth/app-role';
import { createAdminClient } from '@/lib/supabase/admin';
import { createClient } from '@/lib/supabase/server';
import { DISPLAY_NAME_MAX_LENGTH } from '@/utils/display-label';

export interface ProfileActionState {
  ok: boolean;
  error: string;
}

export async function updateDisplayName(
  _prevState: ProfileActionState,
  formData: FormData,
): Promise<ProfileActionState> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { ok: false, error: 'You must be signed in.' };
  }

  const raw = formData.get('display_name');
  if (typeof raw !== 'string') {
    return { ok: false, error: 'Display name is required.' };
  }

  const displayName = raw.trim();
  // [...s].length はコードポイント数。char_length() と揃える（recipe 名と同じ）。
  const length = [...displayName].length;
  if (length < 1 || length > DISPLAY_NAME_MAX_LENGTH) {
    return {
      ok: false,
      error: `Display name must be 1–${DISPLAY_NAME_MAX_LENGTH} characters.`,
    };
  }

  const { data: updated, error } = await supabase
    .from('users')
    .update({ display_name: displayName })
    .eq('id', user.id)
    .eq('status', 'active')
    .select('id')
    .maybeSingle();

  if (error || !updated) {
    return { ok: false, error: 'Failed to update display name.' };
  }

  revalidatePath('/', 'layout');
  revalidatePath('/profile');
  return { ok: true, error: '' };
}

export async function deleteAccount(
  _prevState: ProfileActionState,
  formData: FormData,
): Promise<ProfileActionState> {
  const confirmed = formData.get('confirm') === '1';
  if (!confirmed) {
    return { ok: false, error: '退会するには確認チェックを入れてください。' };
  }

  const supabase = await createClient();
  const { user, appRole } = await getAuthProfile();
  if (!user) {
    return { ok: false, error: 'You must be signed in.' };
  }

  const blocked = await isAccountDeletionBlocked({ user, appRole, supabase });
  if (blocked) {
    return { ok: false, error: 'このアカウントは退会できません。' };
  }

  // 設定不備で下書きだけ消さないよう、Admin client を先に組み立てる。
  let admin;
  try {
    admin = createAdminClient();
  } catch {
    return {
      ok: false,
      error: '退会処理を開始できませんでした。しばらくしてから再試行してください。',
    };
  }

  const { error: draftError } = await supabase
    .from('cocktail_recipes')
    .delete()
    .eq('user_id', user.id)
    .eq('status', 'draft');

  if (draftError) {
    return { ok: false, error: '下書きの削除に失敗しました。退会を中止しました。' };
  }

  const { error: withdrawError } = await supabase.rpc('withdraw_own_account');
  if (withdrawError) {
    return { ok: false, error: '退会処理に失敗しました。再試行してください。' };
  }

  try {
    const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
    if (deleteError) {
      return {
        ok: false,
        error:
          '退会処理に失敗しました。下書きは既に削除済みの可能性があります。再試行してください。',
      };
    }
  } catch {
    return {
      ok: false,
      error: '退会処理に失敗しました。下書きは既に削除済みの可能性があります。再試行してください。',
    };
  }

  try {
    await supabase.auth.signOut();
  } catch {
    // Cookie 破棄に失敗しても Auth ユーザーは消えているので / へ進む
  }

  redirect('/');
}
