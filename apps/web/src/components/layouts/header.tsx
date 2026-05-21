import Image from 'next/image';
import Link from 'next/link';

import { createClient } from '@/lib/supabase/server';

export async function Header() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const displayName = user?.email?.split('@')[0] || 'User';
  const avatarUrl = `https://ui-avatars.com/api/?name=${encodeURIComponent(displayName)}&background=random&size=32`;

  return (
    <header className="border-b">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4">
        <Link href="/" className="text-xl font-bold">
          SakeHub
        </Link>
        <nav className="flex items-center gap-6">
          {user ? (
            <Link href="/profile" className="flex items-center">
              <Image
                src={avatarUrl}
                alt={displayName}
                className="rounded-full"
                width={32}
                height={32}
              />
            </Link>
          ) : (
            <Link
              href="/login"
              className="bg-primary text-primary-foreground hover:bg-primary/90 inline-flex h-9 items-center rounded-md px-4 text-sm font-medium"
            >
              Login
            </Link>
          )}
        </nav>
      </div>
    </header>
  );
}
