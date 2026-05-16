import { NextRequest, NextResponse } from 'next/server';

import { serverFetch } from '@/lib/server-api';

interface ApiDrinkListResponse {
  data: unknown[];
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
    const data = await serverFetch<ApiDrinkListResponse>('/api/drinks', { params });
    return NextResponse.json(data);
  } catch {
    return NextResponse.json({ error: 'Failed to fetch drinks' }, { status: 502 });
  }
}
