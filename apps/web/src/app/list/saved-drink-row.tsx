'use client';

import Image from 'next/image';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState, useTransition } from 'react';
import { Wine } from 'lucide-react';
import type { SavedDrink, SavedDrinkStatus } from '@sakehub/types';

import { updateSavedDrink } from '@/application/saved-drink-actions';
import { Button } from '@/components/ui/button';
import { StarRatingDisplay } from '@/components/ui/star-rating';
import { oppositeSavedDrinkStatus, savedDrinkStatusLabel } from '@/utils/saved-drink-status';

import { UnsaveDrinkButton } from './unsave-drink-button';

interface SavedDrinkRowProps {
  item: SavedDrink;
}

export function SavedDrinkRow({ item }: SavedDrinkRowProps) {
  const drink = item.drink;
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  if (!drink) return null;

  const handleToggle = () => {
    const next: SavedDrinkStatus = oppositeSavedDrinkStatus(item.status);
    setError(null);
    startTransition(async () => {
      const result = await updateSavedDrink(item.drinkId, drink.slug, { status: next });
      if (!result.ok) {
        setError(result.error);
        return;
      }
      router.refresh();
    });
  };

  return (
    <li className="flex items-start gap-3 rounded-lg border p-3">
      <Link
        href={`/drinks/${drink.slug}`}
        className="bg-muted relative size-16 shrink-0 overflow-hidden rounded-md"
      >
        {drink.imageUrl ? (
          <Image src={drink.imageUrl} alt={drink.name} fill sizes="64px" className="object-cover" />
        ) : (
          <span className="flex size-full items-center justify-center">
            <Wine className="text-muted-foreground/40 size-7" aria-hidden="true" />
          </span>
        )}
      </Link>

      <div className="min-w-0 flex-1 space-y-1">
        <div className="flex flex-wrap items-baseline gap-x-2 gap-y-0.5">
          <Link href={`/drinks/${drink.slug}`} className="font-medium hover:underline">
            {drink.name}
          </Link>
          <span className="text-muted-foreground text-xs">
            {savedDrinkStatusLabel(item.status)}
          </span>
        </div>
        {item.rating != null && (
          <StarRatingDisplay value={item.rating} size="sm" showValue={false} />
        )}
        {item.note ? (
          <p className="text-muted-foreground line-clamp-1 text-sm">{item.note}</p>
        ) : null}
        {error && (
          <p className="text-destructive text-xs" role="alert">
            {error}
          </p>
        )}
      </div>

      <div className="flex shrink-0 flex-col items-end gap-1">
        <Button
          type="button"
          variant="outline"
          size="sm"
          disabled={isPending}
          onClick={handleToggle}
        >
          {item.status === 'drank' ? '飲みたいにする' : '飲んだにする'}
        </Button>
        <UnsaveDrinkButton drinkId={item.drinkId} drinkSlug={drink.slug} />
      </div>
    </li>
  );
}
