import { env } from '@/lib/env';
import { supabase } from '@/lib/supabase';

type FetchOptions = RequestInit & {
  params?: Record<string, string>;
  /** When true (default), attach the current Supabase access token if present. */
  auth?: boolean;
};

export async function apiClient<T>(endpoint: string, options: FetchOptions = {}): Promise<T> {
  const { params, auth = true, headers: initHeaders, ...fetchOptions } = options;

  const url = new URL(`${env.apiUrl}${endpoint}`);
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      url.searchParams.set(key, value);
    });
  }

  const headers = new Headers(initHeaders);
  if (!headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }

  if (auth) {
    const {
      data: { session },
    } = await supabase.auth.getSession();
    if (session?.access_token) {
      headers.set('Authorization', `Bearer ${session.access_token}`);
    }
  }

  const response = await fetch(url.toString(), {
    ...fetchOptions,
    headers,
  });

  if (!response.ok) {
    throw new Error(`API Error: ${response.status} ${response.statusText}`);
  }

  return response.json() as Promise<T>;
}
