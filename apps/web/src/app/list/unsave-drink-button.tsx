'use client';

import { useRouter } from 'next/navigation';
import { useState, useTransition } from 'react';

import { unsaveDrink } from '@/application/saved-drink-actions';
import { Button } from '@/components/ui/button';

interface UnsaveDrinkButtonProps {
  drinkId: string;
  drinkSlug: string;
}

export function UnsaveDrinkButton({ drinkId, drinkSlug }: UnsaveDrinkButtonProps) {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  return (
    <div className="flex flex-col items-end gap-1">
      <Button
        type="button"
        variant="ghost"
        size="sm"
        disabled={isPending}
        onClick={() => {
          setError(null);
          startTransition(async () => {
            const result = await unsaveDrink(drinkId, drinkSlug);
            if (!result.ok) {
              setError(result.error);
              return;
            }
            router.refresh();
          });
        }}
      >
        {isPending ? '外しています…' : 'リストから外す'}
      </Button>
      {error && (
        <p className="text-destructive text-xs" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
