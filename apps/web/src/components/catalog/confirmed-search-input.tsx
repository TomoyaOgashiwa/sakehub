'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useState, useTransition } from 'react';
import { Search } from 'lucide-react';

import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';

interface ConfirmedSearchInputProps {
  /** 遷移先のパス名（例: `/`, `/cocktails`）。 */
  pathname: string;
  placeholder: string;
  ariaLabel: string;
}

/**
 * 確定検索の入力欄: URL の `q` は submit（Enter / ボタン押下）でのみ更新する。
 *
 * ゼロヒットのミスログ（`SearchMissLogger`）は「確定した検索クエリ」だけを
 * 対象にする契約になっている。debounce で `q` を書き換える実装に戻すと、
 * 入力途中の部分文字列（「だ」「だっ」…）まで `search_misses` に記録されて
 * Phase 3 の需要ランキングが汚染される。DrinkSearch / CocktailSearch は
 * 両方ともこのコンポーネントを使い、個別実装への回帰を防ぐ。
 */
export function ConfirmedSearchInput({
  pathname,
  placeholder,
  ariaLabel,
}: ConfirmedSearchInputProps) {
  const searchParams = useSearchParams();
  const currentQuery = searchParams.get('q') ?? '';

  return (
    <ConfirmedSearchForm
      key={currentQuery}
      pathname={pathname}
      placeholder={placeholder}
      ariaLabel={ariaLabel}
      initialQuery={currentQuery}
    />
  );
}

interface ConfirmedSearchFormProps extends ConfirmedSearchInputProps {
  initialQuery: string;
}

function ConfirmedSearchForm({
  pathname,
  placeholder,
  ariaLabel,
  initialQuery,
}: ConfirmedSearchFormProps) {
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
      router.push(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
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
          placeholder={placeholder}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className="h-10 pl-9"
          aria-label={ariaLabel}
          data-pending={isPending || undefined}
        />
      </div>
      <Button type="submit" variant="secondary" disabled={isPending}>
        検索
      </Button>
    </form>
  );
}
