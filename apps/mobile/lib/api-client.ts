import { env } from '@/lib/env';
import { supabase } from '@/lib/supabase';

type AuthMode = boolean | 'required' | 'optional';

type FetchOptions = RequestInit & {
  params?: Record<string, string>;
  /**
   * Auth mode for the Go API:
   * - `true` / `'required'` (default): attach Bearer token; throw if missing
   * - `'optional'`: attach Bearer token when a session exists
   * - `false`: never attach Authorization
   */
  auth?: AuthMode;
};

function isAuthRequired(auth: AuthMode): boolean {
  return auth === true || auth === 'required';
}

function shouldAttachAuth(auth: AuthMode): boolean {
  return auth !== false;
}

export async function apiClient<T>(endpoint: string, options: FetchOptions = {}): Promise<T> {
  const { params, auth = 'required', headers: initHeaders, ...fetchOptions } = options;

  const url = new URL(`${env.apiUrl}${endpoint}`);
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      url.searchParams.set(key, value);
    });
  }

  const headers = new Headers(initHeaders);
  if (!headers.has('Content-Type') && fetchOptions.body != null) {
    headers.set('Content-Type', 'application/json');
  }

  if (shouldAttachAuth(auth)) {
    const {
      data: { session },
    } = await supabase.auth.getSession();
    const accessToken = session?.access_token;

    if (accessToken) {
      headers.set('Authorization', `Bearer ${accessToken}`);
    } else if (isAuthRequired(auth)) {
      throw new Error('Not authenticated');
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
