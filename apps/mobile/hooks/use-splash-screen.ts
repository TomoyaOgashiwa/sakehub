import { useEffect } from 'react';

import * as SplashScreen from 'expo-splash-screen';

void SplashScreen.preventAutoHideAsync().catch(() => {
  // Already prevented or unavailable (e.g. web) — safe to ignore.
});

/**
 * Keeps the native splash visible until `isReady` becomes true, then hides it once.
 */
export function useSplashScreen(isReady: boolean): void {
  useEffect(() => {
    if (!isReady) return;

    void SplashScreen.hideAsync().catch(() => {
      // Already hidden — ignore.
    });
  }, [isReady]);
}
