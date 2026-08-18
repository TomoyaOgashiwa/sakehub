'use server';

import { redirect } from 'next/navigation';

import { createClient } from '@/lib/supabase/server';
import { safeNextPath } from '@/utils/safe-next-path';

export interface AuthState {
  ok: boolean;
  error: string;
}

export async function signIn(_prevState: AuthState, formData: FormData): Promise<AuthState> {
  const email = formData.get('email') as string;
  const password = formData.get('password') as string;

  if (!email || !password) {
    return { ok: false, error: 'Email and password are required.' };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    return { ok: false, error: error.message };
  }

  redirect(safeNextPath(formData.get('next') as string | null));
}

export async function signUp(_prevState: AuthState, formData: FormData): Promise<AuthState> {
  const email = formData.get('email') as string;
  const password = formData.get('password') as string;
  const confirmPassword = formData.get('confirmPassword') as string;

  if (!email || !password) {
    return { ok: false, error: 'Email and password are required.' };
  }

  if (password !== confirmPassword) {
    return { ok: false, error: 'Passwords do not match.' };
  }

  if (password.length < 6) {
    return { ok: false, error: 'Password must be at least 6 characters.' };
  }

  const supabase = await createClient();
  const { data: registrationBlocked, error: blockCheckError } = await supabase.rpc(
    'email_registration_blocked',
    { p_email: email },
  );
  if (blockCheckError) {
    return { ok: false, error: '登録を確認できませんでした。しばらくしてから再試行してください。' };
  }
  if (registrationBlocked === true) {
    return { ok: false, error: 'このメールアドレスでは登録できません。' };
  }

  const { error } = await supabase.auth.signUp({ email, password });

  if (error) {
    if (error.message.includes('EMAIL_FORCE_WITHDRAWN')) {
      return { ok: false, error: 'このメールアドレスでは登録できません。' };
    }
    return { ok: false, error: error.message };
  }

  redirect(safeNextPath(formData.get('next') as string | null));
}

export async function signOut(): Promise<void> {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect('/login');
}
