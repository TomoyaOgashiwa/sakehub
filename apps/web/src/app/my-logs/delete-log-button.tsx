'use client';

import { useRouter } from 'next/navigation';
import { useState, useTransition } from 'react';

import { deleteDrinkLog } from '@/application/drink-log-actions';
import { Button } from '@/components/ui/button';

interface DeleteLogButtonProps {
  logId: string;
}

export function DeleteLogButton({ logId }: DeleteLogButtonProps) {
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
            const result = await deleteDrinkLog(logId);
            if (!result.ok) {
              setError(result.error);
              return;
            }
            router.refresh();
          });
        }}
      >
        {isPending ? '削除中…' : '削除'}
      </Button>
      {error && (
        <p className="text-destructive text-xs" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
