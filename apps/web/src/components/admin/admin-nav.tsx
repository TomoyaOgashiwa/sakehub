'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

import { cn } from '@/utils/utils';

const items = [
  { href: '/admin', label: '概要', exact: true },
  { href: '/admin/search-misses', label: '需要' },
  { href: '/admin/provisional', label: '図鑑待ち' },
] as const;

export function AdminNav() {
  const pathname = usePathname();

  return (
    <nav aria-label="運営" className="mb-8 flex flex-wrap gap-4 text-sm font-medium">
      {items.map((item) => {
        const active = item.exact ? pathname === item.href : pathname.startsWith(item.href);
        return (
          <Link
            key={item.href}
            href={item.href}
            aria-current={active ? 'page' : undefined}
            className={cn(
              'transition-colors',
              active ? 'text-foreground' : 'text-muted-foreground hover:text-foreground',
            )}
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
