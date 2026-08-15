import 'server-only';

const API_URL = process.env.API_URL ?? 'http://localhost:8080';

type ServerFetchOptions = Omit<RequestInit, 'method' | 'headers'> & {
  params?: Record<string, string>;
  headers?: HeadersInit;
  /** When true, skip JSON parsing (e.g. 204 No Content). */
  emptyResponse?: boolean;
  method?: RequestInit['method'];
};

function buildUrl(endpoint: string, params?: Record<string, string>): string {
  const url = new URL(`${API_URL}${endpoint}`);
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      url.searchParams.set(key, value);
    });
  }
  return url.toString();
}

export async function serverFetch<T>(
  endpoint: string,
  options: ServerFetchOptions = {},
): Promise<T> {
  const { params, headers, emptyResponse, ...fetchOptions } = options;

  const response = await fetch(buildUrl(endpoint, params), {
    ...fetchOptions,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
  });

  if (!response.ok) {
    throw new Error(`API Error: ${response.status} ${response.statusText}`);
  }

  if (emptyResponse || response.status === 204) {
    return undefined as T;
  }

  return response.json() as Promise<T>;
}

export type AuthServerFetchResult<T> =
  { ok: true; data: T } | { ok: false; status: number; error: string };

type AuthServerFetchOptions = {
  accessToken: string;
  method?: RequestInit['method'];
  body?: unknown;
  params?: Record<string, string>;
  cache?: RequestCache;
  /** When true, skip JSON parsing (e.g. 204 No Content). */
  emptyResponse?: boolean;
};

/**
 * Authenticated mutation/fetch helper for Server Actions.
 * Returns a Result instead of throwing so callers can map UX errors safely.
 */
export async function authServerFetch<T = undefined>(
  endpoint: string,
  options: AuthServerFetchOptions,
): Promise<AuthServerFetchResult<T>> {
  const { accessToken, method = 'GET', body, params, cache, emptyResponse } = options;

  let response: Response;
  try {
    response = await fetch(buildUrl(endpoint, params), {
      method,
      cache,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  } catch {
    return {
      ok: false,
      status: 0,
      error: 'サーバーへの接続に失敗しました。しばらくしてから再試行してください。',
    };
  }

  if (!response.ok) {
    const payload = (await response.json().catch(() => ({}))) as {
      error?: string;
      message?: string;
    };
    return {
      ok: false,
      status: response.status,
      error: payload.message || payload.error || `API Error: ${response.status}`,
    };
  }

  if (emptyResponse || response.status === 204) {
    return { ok: true, data: undefined as T };
  }

  return { ok: true, data: (await response.json()) as T };
}
