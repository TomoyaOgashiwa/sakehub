import type { ReactNode } from 'react';

import { SafeAreaProvider } from 'react-native-safe-area-context';
import { SWRConfig } from 'swr';

import { AuthProvider } from '@/hooks/use-auth';

interface AppProvidersProps {
  children: ReactNode;
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
        <AuthProvider>{children}</AuthProvider>
      </SWRConfig>
    </SafeAreaProvider>
  );
}
