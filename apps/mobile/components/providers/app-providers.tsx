import type { ReactNode } from 'react';

import { SafeAreaProvider } from 'react-native-safe-area-context';
import { SWRConfig } from 'swr';

import { useAuth } from '@/hooks/use-auth';
import { useSplashScreen } from '@/hooks/use-splash-screen';

interface AppProvidersProps {
  children: ReactNode;
}

function AuthGate({ children }: Readonly<{ children: ReactNode }>) {
  const { isLoading } = useAuth();
  // Keep Stack mounted so route segments resolve while splash covers the first paint.
  useSplashScreen(!isLoading);
  return children;
}

export function AppProviders({ children }: Readonly<AppProvidersProps>) {
  return (
    <SafeAreaProvider>
      <SWRConfig
        value={{
          revalidateOnFocus: false,
          shouldRetryOnError: false,
        }}
      >
        <AuthGate>{children}</AuthGate>
      </SWRConfig>
    </SafeAreaProvider>
  );
}
