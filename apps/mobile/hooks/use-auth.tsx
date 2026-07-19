import { createContext, useContext, useEffect, useState } from 'react';
import type { ReactNode } from 'react';

import type { Session } from '@supabase/supabase-js';
import { useRouter, useSegments } from 'expo-router';

import { useSplashScreen } from '@/hooks/use-splash-screen';
import { supabase } from '@/lib/supabase';

interface UseAuthResult {
  session: Session | null;
  isLoading: boolean;
}

const AuthContext = createContext<UseAuthResult | null>(null);

/**
 * Single auth subscription + route gate. Mount once under AppProviders.
 */
export function AuthProvider({ children }: Readonly<{ children: ReactNode }>) {
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

  // Keep Stack mounted so route segments resolve while splash covers the first paint.
  useSplashScreen(!isLoading);

  return (
    <AuthContext.Provider value={{ session, isLoading }}>{children}</AuthContext.Provider>
  );
}

/**
 * Reads the shared auth session from AuthProvider.
 * Do not subscribe to Supabase auth here — that lives in AuthProvider only.
 */
export function useAuth(): UseAuthResult {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
