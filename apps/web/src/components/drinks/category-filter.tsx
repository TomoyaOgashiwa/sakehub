'use client';

import { useRouter, useSearchParams } from 'next/navigation';

import { cn } from '@/utils/utils';
import { MAIN_FILTER_CATEGORIES } from '@/config/drinks';

export function CategoryFilter() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const active = searchParams.get('category') ?? 'all';

  function handleSelect(value: string) {
    const params = new URLSearchParams(searchParams.toString());
    if (value === 'all') {
      params.delete('category');
    } else {
      params.set('category', value);
    }
    params.delete('offset');
    router.push(`/?${params.toString()}`, { scroll: false });
  }

  return (
    <nav aria-label="カテゴリフィルタ">
      <ul className="flex flex-wrap gap-2" role="list">
        {MAIN_FILTER_CATEGORIES.map(({ value, label }) => (
          <li key={value}>
            <button
              type="button"
              onClick={() => handleSelect(value)}
              className={cn(
                'rounded-full px-4 py-1.5 text-sm font-medium transition-colors',
                active === value
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-muted text-muted-foreground hover:bg-muted/80 hover:text-foreground',
              )}
              aria-pressed={active === value}
            >
              {label}
            </button>
          </li>
        ))}
      </ul>
    </nav>
  );
}
