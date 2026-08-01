import { NextRequest, NextResponse } from 'next/server';

import { createClient } from '@/lib/supabase/server';

const API_URL = process.env.API_URL ?? 'http://localhost:8080';

export async function POST(request: NextRequest) {
  let body: string;
  try {
    body = await request.text();
    JSON.parse(body);
  } catch {
    return NextResponse.json({ error: 'invalid json' }, { status: 400 });
  }

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (user) {
      const {
        data: { session },
      } = await supabase.auth.getSession();
      if (session?.access_token) {
        headers.Authorization = `Bearer ${session.access_token}`;
      }
    }
  } catch {
    // Optional auth; proceed without token.
  }

  try {
    const res = await fetch(`${API_URL}/api/search-misses`, {
      method: 'POST',
      headers,
      body,
    });

    if (res.status === 204) {
      return new NextResponse(null, { status: 204 });
    }

    const text = await res.text();
    if (!text) {
      return new NextResponse(null, { status: res.status });
    }

    return new NextResponse(text, {
      status: res.status,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch {
    return NextResponse.json({ error: 'Failed to log search miss' }, { status: 502 });
  }
}
