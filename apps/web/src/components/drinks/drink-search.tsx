'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useEffect, useState, useTransition } from 'react';
import { Search } from 'lucide-react';

import { Input } from '@/components/ui/input';
import { useDebounce } from '@/hooks/use-debounce';

export function DrinkSearch() {
  const searchParams = useSearchParams();
  const currentQuery = searchParams.get('q') ?? '';

  return <DrinkSearchInput key={currentQuery} initialQuery={currentQuery} />;
}

interface DrinkSearchInputProps {
  initialQuery: string;
}

function DrinkSearchInput({ initialQuery }: DrinkSearchInputProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [isComposing, setIsComposing] = useState(false);
  const [isPending, startTransition] = useTransition();

  const [query, setQuery] = useState(initialQuery);
  const debouncedQuery = useDebounce(query, 300);

  useEffect(() => {
    if (isComposing) {
      return;
    }

    if (debouncedQuery === initialQuery) {
      return;
    }

    startTransition(() => {
      const params = new URLSearchParams(searchParams.toString());
      if (debouncedQuery) {
        params.set('q', debouncedQuery);
      } else {
        params.delete('q');
      }
      params.delete('offset');
      router.replace(`/?${params.toString()}`, { scroll: false });
    });
  }, [debouncedQuery, isComposing, initialQuery, router, searchParams, startTransition]);

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    setQuery(e.target.value);
  }

  function handleCompositionStart() {
    setIsComposing(true);
  }

  function handleCompositionEnd(e: React.CompositionEvent<HTMLInputElement>) {
    setIsComposing(false);
    setQuery(e.currentTarget.value);
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
        value={query}
        onChange={handleChange}
        onCompositionStart={handleCompositionStart}
        onCompositionEnd={handleCompositionEnd}
        className="h-10 pl-9"
        aria-label="お酒をキーワードで検索"
        data-pending={isPending || undefined}
      />
    </div>
  );
}
