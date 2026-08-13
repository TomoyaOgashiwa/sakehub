'use client';

import { useSyncExternalStore } from 'react';

import { getBrowserTimeZone, localTodayYmd } from '@/utils/time-zone';

function subscribe() {
  return () => {};
}

/** Calendar today in the browser. Empty during SSR so hydration stays stable. */
export function useBrowserTodayYmd(): string {
  return useSyncExternalStore(subscribe, localTodayYmd, () => '');
}

/** IANA time zone of the browser. `serverFallback` is used for SSR / hydration. */
export function useBrowserTimeZone(serverFallback = 'UTC'): string {
  return useSyncExternalStore(subscribe, getBrowserTimeZone, () => serverFallback);
}
