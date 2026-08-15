import Link from 'next/link';

interface AdminNavItem {
  href?: string;
  label: string;
  phase?: string;
}

const items: readonly AdminNavItem[] = [
  { href: '/admin', label: '概要' },
  { href: '/admin/search-misses', label: '需要' },
  { label: '図鑑待ち', phase: 'Phase 4' },
];

export function AdminNav() {
  return (
    <nav aria-label="運営" className="mb-8 flex flex-wrap gap-4 text-sm font-medium">
      {items.map((item) =>
        item.href ? (
          <Link
            key={item.label}
            href={item.href}
            className="text-muted-foreground hover:text-foreground transition-colors"
          >
            {item.label}
          </Link>
        ) : (
          <span key={item.label} className="text-muted-foreground/70">
            {item.label}
            {item.phase ? <span className="ml-1 text-xs font-normal">({item.phase})</span> : null}
          </span>
        ),
      )}
    </nav>
  );
}
