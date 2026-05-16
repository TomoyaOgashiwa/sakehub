'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useRef, useTransition } from 'react';
import { Search } from 'lucide-react';

import { Input } from '@/components/ui/input';

export function DrinkSearch() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const timerRef = useRef<ReturnType<typeof setTimeout>>(null);
  const [isPending, startTransition] = useTransition();

  const defaultValue = searchParams.get('q') ?? '';

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
    }

    const value = e.target.value;
    timerRef.current = setTimeout(() => {
      startTransition(() => {
        const params = new URLSearchParams(searchParams.toString());
        if (value) {
          params.set('q', value);
        } else {
          params.delete('q');
        }
        params.delete('offset');
        router.push(`/?${params.toString()}`, { scroll: false });
      });
    }, 300);
  }

  return (
    <div className="relative">
      <Search
        className="text-muted-foreground pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2"
        aria-hidden="true"
      />
      <Input
        type="search"
        placeholder="お酒を検索..."
        defaultValue={defaultValue}
        onChange={handleChange}
        className="h-10 pl-9"
        aria-label="お酒をキーワードで検索"
        data-pending={isPending || undefined}
      />
    </div>
  );
}
