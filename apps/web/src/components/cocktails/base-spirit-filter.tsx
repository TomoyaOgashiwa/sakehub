'use client';

import { useRouter, useSearchParams } from 'next/navigation';

import { cn } from '@/utils/utils';
import { BASE_SPIRIT_FILTERS } from '@/config/cocktails';

export function BaseSpiritFilter() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const active = searchParams.get('base_spirit') ?? '';

  function handleSelect(value: string) {
    const params = new URLSearchParams(searchParams.toString());
    if (!value) {
      params.delete('base_spirit');
    } else {
      params.set('base_spirit', value);
    }
    params.delete('offset');
    const qs = params.toString();
    router.push(qs ? `/cocktails?${qs}` : '/cocktails', { scroll: false });
  }

  return (
    <nav aria-label="ベーススピリットフィルタ">
      <ul className="flex flex-wrap gap-2" role="list">
        {BASE_SPIRIT_FILTERS.map(({ value, label }) => (
          <li key={value || 'all'}>
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
