import 'server-only';

import { cache } from 'react';
import { notFound, redirect } from 'next/navigation';
import type { User } from '@supabase/supabase-js';

import { createClient } from '@/lib/supabase/server';

export type AppRole = 'member' | 'admin';

export interface AuthProfile {
  user: User | null;
  appRole: AppRole | null;
  displayName: string | null;
}

interface UserProfileRow {
  app_role: string;
  display_name: string | null;
}

export const getAuthProfile = cache(async (): Promise<AuthProfile> => {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { user: null, appRole: null, displayName: null };

  const { data, error } = await supabase
    .from('users')
    .select('app_role, display_name')
    .eq('id', user.id)
    .maybeSingle();

  // Header を 500 にしない。読めなければ member 扱い（運営リンクを出さない）
  const row = data as UserProfileRow | null;
  const displayName = row?.display_name ?? null;
  if (error || row?.app_role !== 'admin') {
    return { user, appRole: 'member', displayName };
  }
  return { user, appRole: 'admin', displayName };
});

export async function requireAdminPage(): Promise<void> {
  const { user, appRole } = await getAuthProfile();
  if (!user) {
    redirect('/login?next=/admin');
  }
  if (appRole !== 'admin') {
    notFound();
  }
}
