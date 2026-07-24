import 'server-only';

const API_URL = process.env.API_URL ?? 'http://localhost:8080';

type ServerFetchOptions = Omit<RequestInit, 'method' | 'headers'> & {
  params?: Record<string, string>;
  headers?: HeadersInit;
  /** When true, skip JSON parsing (e.g. 204 No Content). */
  emptyResponse?: boolean;
  method?: RequestInit['method'];
};

export async function serverFetch<T>(
  endpoint: string,
  options: ServerFetchOptions = {},
): Promise<T> {
  const { params, headers, emptyResponse, ...fetchOptions } = options;

  const url = new URL(`${API_URL}${endpoint}`);
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      url.searchParams.set(key, value);
    });
  }

  const response = await fetch(url.toString(), {
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
