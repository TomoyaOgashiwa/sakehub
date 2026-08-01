import { NextRequest, NextResponse } from 'next/server';

import { serverFetch } from '@/application/server-api';

interface ApiCocktailListResponse {
  data: unknown[] | null;
  total: number;
  limit: number;
  offset: number;
}

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;

  const params: Record<string, string> = {};
  for (const [key, value] of searchParams.entries()) {
    params[key] = value;
  }

  try {
    const data = await serverFetch<ApiCocktailListResponse>('/api/cocktails', {
      params: Object.keys(params).length > 0 ? params : undefined,
    });
    return NextResponse.json(data);
  } catch {
    return NextResponse.json({ error: 'Failed to fetch cocktails' }, { status: 502 });
  }
}
