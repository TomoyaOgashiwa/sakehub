import { NextResponse } from 'next/server';

import { serverFetch } from '@/application/server-api';

interface ApiCocktailListResponse {
  data: unknown[] | null;
}

export async function GET() {
  try {
    const data = await serverFetch<ApiCocktailListResponse>('/api/cocktails');
    return NextResponse.json(data);
  } catch {
    return NextResponse.json({ error: 'Failed to fetch cocktails' }, { status: 502 });
  }
}
