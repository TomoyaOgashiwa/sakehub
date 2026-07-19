import { useEffect, useState } from 'react';

import type { Session } from '@supabase/supabase-js';
import { useRouter, useSegments } from 'expo-router';

import { supabase } from '@/lib/supabase';

interface UseAuthResult {
  session: Session | null;
  isLoading: boolean;
}

/**
 * Subscribes to Supabase auth and redirects between `(auth)` / `(tabs)`.
 * Returns loading state so splash can wait until the first session resolve.
 */
export function useAuth(): UseAuthResult {
  const router = useRouter();
  const segments = useSegments();
  const [session, setSession] = useState<Session | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    void supabase.auth
      .getSession()
      .then(({ data }) => {
        if (!isMounted) return;
        setSession(data.session);
        setIsLoading(false);
      })
      .catch(() => {
        if (!isMounted) return;
        setSession(null);
        setIsLoading(false);
      });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession);
      setIsLoading(false);
    });

    return () => {
      isMounted = false;
      subscription.unsubscribe();
    };
  }, []);

  useEffect(() => {
    if (isLoading) return;

    const inAuthGroup = segments[0] === '(auth)';

    if (!session && !inAuthGroup) {
      router.replace('/(auth)/login');
      return;
    }

    if (session && inAuthGroup) {
      router.replace('/(tabs)');
    }
  }, [session, segments, isLoading, router]);

  return { session, isLoading };
}
