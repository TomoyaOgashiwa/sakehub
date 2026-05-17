import { NextRequest, NextResponse } from 'next/server';

import { serverFetch } from '@/application/server-api';

type RouteParams = {
  params: Promise<{ slug: string }>;
};

export async function GET(_request: NextRequest, { params }: RouteParams) {
  const { slug } = await params;

  try {
    const data = await serverFetch<unknown>(`/api/drinks/by-slug/${encodeURIComponent(slug)}`);
    return NextResponse.json(data);
  } catch (error) {
    if (error instanceof Error && error.message.includes('404')) {
      return NextResponse.json({ error: 'Drink not found' }, { status: 404 });
    }
    return NextResponse.json({ error: 'Failed to fetch drink' }, { status: 502 });
  }
}
