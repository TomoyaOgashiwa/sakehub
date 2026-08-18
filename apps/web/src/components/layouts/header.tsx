import Image from 'next/image';
import Link from 'next/link';

import { Button } from '@/components/ui/button';
import { getAuthProfile } from '@/lib/auth/app-role';
import { resolveDisplayLabel } from '@/utils/display-label';
import { recipeComposeHref } from '@/utils/recipe-compose-href';

export async function Header() {
  const { user, appRole, displayName } = await getAuthProfile();
  const loggedIn = user != null;
  const composeHref = recipeComposeHref({ loggedIn });

  const label = resolveDisplayLabel(displayName, user?.email);
  const avatarUrl = `https://ui-avatars.com/api/?name=${encodeURIComponent(label)}&background=random&size=32`;

  return (
    <header className="border-b">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4">
        <div className="flex items-center gap-6">
          <Link href="/" className="text-xl font-bold">
            SakeHub
          </Link>
          <nav
            className="hidden items-center gap-4 text-sm font-medium sm:flex"
            aria-label="メイン"
          >
            <Link
              href="/"
              className="text-muted-foreground hover:text-foreground transition-colors"
            >
              お酒
            </Link>
            <Link
              href="/cocktails"
              className="text-muted-foreground hover:text-foreground transition-colors"
            >
              カクテル
            </Link>
            {user && (
              <Link
                href="/list"
                className="text-muted-foreground hover:text-foreground transition-colors"
              >
                リスト
              </Link>
            )}
            {appRole === 'admin' && (
              <Link
                href="/admin"
                className="text-muted-foreground hover:text-foreground transition-colors"
              >
                運営
              </Link>
            )}
          </nav>
        </div>
        <nav className="flex shrink-0 items-center gap-2 sm:gap-4">
          <Button
            variant={loggedIn ? 'default' : 'outline'}
            size="sm"
            render={<Link href={composeHref} />}
            nativeButton={false}
          >
            レシピを投稿
          </Button>
          {user ? (
            <Link href="/profile" className="flex items-center">
              <Image src={avatarUrl} alt={label} className="rounded-full" width={32} height={32} />
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
