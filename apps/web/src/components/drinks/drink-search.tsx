'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useState, useTransition } from 'react';
import { Search } from 'lucide-react';

import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';

/**
 * 確定検索の入力欄: `q` は submit（Enter / ボタン押下）でのみ更新する。
 * （ゼロヒットのミスログは1キー入力ごとに発火してはならない。CocktailSearch と同じ方針）
 */
export function DrinkSearch() {
  const searchParams = useSearchParams();
  const currentQuery = searchParams.get('q') ?? '';

  return <DrinkSearchForm key={currentQuery} initialQuery={currentQuery} />;
}

interface DrinkSearchFormProps {
  initialQuery: string;
}

function DrinkSearchForm({ initialQuery }: DrinkSearchFormProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [query, setQuery] = useState(initialQuery);
  const [isPending, startTransition] = useTransition();

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const next = query.trim();

    startTransition(() => {
      const params = new URLSearchParams(searchParams.toString());
      if (next) {
        params.set('q', next);
      } else {
        params.delete('q');
      }
      params.delete('offset');
      const qs = params.toString();
      router.push(qs ? `/?${qs}` : '/', { scroll: false });
    });
  }

  return (
    <form onSubmit={handleSubmit} className="flex w-full gap-2" role="search">
      <div className="relative min-w-0 flex-1">
        <Search
          className="text-muted-foreground pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2"
          aria-hidden="true"
        />
        <Input
          type="search"
          name="q"
          placeholder="お酒を検索..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className="h-10 pl-9"
          aria-label="お酒をキーワードで検索"
          data-pending={isPending || undefined}
        />
      </div>
      <Button type="submit" variant="secondary" disabled={isPending}>
        検索
      </Button>
    </form>
  );
}
