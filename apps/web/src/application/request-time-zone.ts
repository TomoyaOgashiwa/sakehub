import 'server-only';

import { cookies } from 'next/headers';

import { resolveTimeZone, TIME_ZONE_COOKIE } from '@/utils/time-zone';

export async function getRequestTimeZone(): Promise<string> {
  const jar = await cookies();
  const raw = jar.get(TIME_ZONE_COOKIE)?.value;
  const decoded = raw ? decodeURIComponent(raw) : '';
  return resolveTimeZone(decoded);
}
