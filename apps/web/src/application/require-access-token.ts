import 'server-only';

import { createClient } from '@/lib/supabase/server';

export async function requireAccessToken(): Promise<
  { ok: true; accessToken: string } | { ok: false; error: string }
> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { ok: false, error: '評価するにはログインが必要です。' };
  }

  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session) {
    return { ok: false, error: 'セッションが見つかりません。再ログインしてください。' };
  }

  return { ok: true, accessToken: session.access_token };
}
