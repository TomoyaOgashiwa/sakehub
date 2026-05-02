import Link from 'next/link';

export function Header() {
  return (
    <header className="border-b">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4">
        <Link href="/" className="text-xl font-bold">
          SakeHub
        </Link>
        <nav className="flex items-center gap-6">{/* Navigation items will be added later */}</nav>
      </div>
    </header>
  );
}
