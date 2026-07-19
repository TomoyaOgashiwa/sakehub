import type { ReactNode } from 'react';

import { View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { cn } from '@/lib/cn';

interface ScreenProps {
  children: ReactNode;
  /** Extra className applied to the inner content container. */
  className?: string;
  /** When false, skip SafeAreaView (e.g. full-bleed media screens). Default true. */
  safe?: boolean;
}

/**
 * Edge-to-edge screen shell. Prefer this over hard-coded status-bar padding.
 */
export function Screen({ children, className, safe = true }: Readonly<ScreenProps>) {
  const content = <View className={cn('flex-1', className)}>{children}</View>;

  if (!safe) {
    return content;
  }

  return (
    <SafeAreaView className="flex-1 bg-white dark:bg-neutral-950" edges={['top', 'left', 'right']}>
      {content}
    </SafeAreaView>
  );
}
