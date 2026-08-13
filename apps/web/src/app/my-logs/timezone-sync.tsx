'use client';

import { useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';

import { getBrowserTimeZone, TIME_ZONE_COOKIE } from '@/utils/time-zone';

export function TimezoneSync() {
  const router = useRouter();
  const didRefresh = useRef(false);

  useEffect(() => {
    const tz = getBrowserTimeZone();
    const encoded = encodeURIComponent(tz);
    const existing = document.cookie
      .split('; ')
      .find((part) => part.startsWith(`${TIME_ZONE_COOKIE}=`));
    const current = existing?.slice(TIME_ZONE_COOKIE.length + 1);

    if (current === encoded || current === tz) {
      return;
    }

    document.cookie = `${TIME_ZONE_COOKIE}=${encoded}; path=/; max-age=31536000; samesite=lax`;
    if (!didRefresh.current) {
      didRefresh.current = true;
      router.refresh();
    }
  }, [router]);

  return null;
}
