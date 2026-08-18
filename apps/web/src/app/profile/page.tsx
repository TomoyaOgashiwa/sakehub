import Image from 'next/image';
import { redirect } from 'next/navigation';

import { Heading } from '@/components/ui/heading';
import { isAccountDeletionBlocked } from '@/lib/auth/account-deletion';
import { getAuthProfile } from '@/lib/auth/app-role';
import { createClient } from '@/lib/supabase/server';
import { resolveDisplayLabel } from '@/utils/display-label';
import { loginHref } from '@/utils/login-href';

import { ProfileHubLink } from './profile-hub-row';
import { SignOutButton } from './sign-out-button';

export const metadata = {
  title: 'Profile',
};

export default async function ProfilePage() {
  const { user, appRole, displayName } = await getAuthProfile();

  if (!user) {
    redirect(loginHref('/profile'));
  }

  const supabase = await createClient();
  const label = resolveDisplayLabel(displayName, user.email);
  const avatarUrl = `https://ui-avatars.com/api/?name=${encodeURIComponent(label)}&background=random&size=96`;
  const showDeletion = !(await isAccountDeletionBlocked({ user, appRole, supabase }));

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <Heading level="h1" className="mb-8">
        Profile
      </Heading>

      <div className="flex flex-col gap-8">
        <div className="flex items-center gap-4">
          <Image src={avatarUrl} alt={label} className="rounded-full" width={96} height={96} />
          <div>
            <p className="text-xl font-semibold">{label}</p>
            <p className="text-muted-foreground text-sm">{user.email}</p>
          </div>
        </div>

        <section aria-labelledby="profile-my-content">
          <h2
            id="profile-my-content"
            className="text-muted-foreground mb-1 px-3 text-sm font-medium"
          >
            マイコンテンツ
          </h2>
          <ul>
            <li>
              <ProfileHubLink href="/list">リスト</ProfileHubLink>
            </li>
            <li>
              <ProfileHubLink href="/my-cocktails">カクテルレシピ</ProfileHubLink>
            </li>
          </ul>
        </section>

        <section aria-labelledby="profile-account">
          <h2 id="profile-account" className="text-muted-foreground mb-1 px-3 text-sm font-medium">
            アカウント
          </h2>
          <ul>
            <li>
              <ProfileHubLink href="/profile/display-name">表示名を変更</ProfileHubLink>
            </li>
            <li>
              <SignOutButton />
            </li>
            {showDeletion ? (
              <li>
                <ProfileHubLink
                  href="/profile/delete"
                  className="text-destructive hover:bg-destructive/10"
                >
                  退会
                </ProfileHubLink>
              </li>
            ) : null}
          </ul>
        </section>
      </div>
    </div>
  );
}
