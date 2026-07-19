import { Text } from 'react-native';

import { Screen } from '@/components/ui/screen';

export default function HomeScreen() {
  return (
    <Screen className="items-center justify-center px-6">
      <Text className="text-2xl font-bold text-neutral-900 dark:text-neutral-50">SakeHub</Text>
      <Text className="mt-2 text-center text-neutral-500 dark:text-neutral-400">
        Discover & Share Your Favorite Spirits
      </Text>
    </Screen>
  );
}
