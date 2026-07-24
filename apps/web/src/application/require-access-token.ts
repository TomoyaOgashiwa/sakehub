import 'server-only';

import type { User } from '@supabase/supabase-js';

import { createClient } from '@/lib/supabase/server';

export async function getOptionalAccessToken(): Promise<{
  user: User | null;
  accessToken: string | null;
}> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { user: null, accessToken: null };
  }

  const {
    data: { session },
  } = await supabase.auth.getSession();

  return { user, accessToken: session?.access_token ?? null };
}

export async function requireAccessToken(): Promise<
  { ok: true; accessToken: string } | { ok: false; error: string }
> {
  const { user, accessToken } = await getOptionalAccessToken();
  if (!user) {
    return { ok: false, error: '評価するにはログインが必要です。' };
  }
  if (!accessToken) {
    return { ok: false, error: 'セッションが見つかりません。再ログインしてください。' };
  }

  return { ok: true, accessToken };
}
