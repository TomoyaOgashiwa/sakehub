'use client';

import Link from 'next/link';
import { useState, useTransition } from 'react';
import type { Drink, SavedDrinkStatus } from '@sakehub/types';

import { saveProvisionalDrink } from '@/application/saved-drink-actions';
import { Button, buttonVariants } from '@/components/ui/button';
import { cn } from '@/utils/utils';

import { DrinkCard } from './drink-card';

interface SearchZeroExitProps {
  query: string;
  suggestions: Drink[];
  isAuthenticated: boolean;
}

export function SearchZeroExit({ query, suggestions, isAuthenticated }: SearchZeroExitProps) {
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const loginHref = `/login?next=${encodeURIComponent(`/?q=${query}`)}`;

  const handleSave = (status: SavedDrinkStatus) => {
    setError(null);
    startTransition(async () => {
      const result = await saveProvisionalDrink(query, status);
      if (!result.ok) {
        setError(result.error);
      }
    });
  };

  return (
    <div className="flex flex-col items-center py-10 text-center">
      <p className="text-lg">「{query}」は見つかりませんでした</p>

      {suggestions.length > 0 && (
        <section aria-label="もしかして" className="mt-8 w-full text-left">
          <h2 className="mb-4 text-center text-sm font-medium">もしかして</h2>
          <ul
            className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
            role="list"
          >
            {suggestions.map((drink) => (
              <li key={drink.id}>
                <DrinkCard drink={drink} />
              </li>
            ))}
          </ul>
        </section>
      )}

      <div className="mt-8 max-w-md space-y-3">
        {suggestions.length > 0 && (
          <p className="text-muted-foreground text-sm">
            どれでもない場合は、この名前でリストに残せます
          </p>
        )}
        <p className="text-muted-foreground text-sm">
          カタログにはまだありません。リストにだけ残します
        </p>

        {isAuthenticated ? (
          <div className="flex flex-wrap justify-center gap-2">
            <Button type="button" disabled={isPending} onClick={() => handleSave('drank')}>
              飲んだ
            </Button>
            <Button
              type="button"
              variant="outline"
              disabled={isPending}
              onClick={() => handleSave('want')}
            >
              飲みたい
            </Button>
          </div>
        ) : (
          <Link href={loginHref} className={cn(buttonVariants())}>
            ログインしてこの名前で残す
          </Link>
        )}

        {error && (
          <p className="text-destructive text-sm" role="alert">
            {error}
          </p>
        )}
      </div>
    </div>
  );
}
