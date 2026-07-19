import '../global.css';

import { Stack } from 'expo-router';

import { AppProviders } from '@/components/providers/app-providers';

export default function RootLayout() {
  return (
    <AppProviders>
      <Stack>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="(auth)" options={{ headerShown: false }} />
      </Stack>
    </AppProviders>
  );
}
