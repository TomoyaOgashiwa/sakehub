import Image from 'next/image';
import Link from 'next/link';
import { redirect } from 'next/navigation';

import { Heading } from '@/components/ui/heading';
import { isAccountDeletionBlocked } from '@/lib/auth/account-deletion';
import { getAuthProfile } from '@/lib/auth/app-role';
import { createClient } from '@/lib/supabase/server';
import { resolveDisplayLabel } from '@/utils/display-label';

import { DeleteAccountSection } from './delete-account-section';
import { DisplayNameForm } from './display-name-form';
import { SignOutButton } from './sign-out-button';

export const metadata = {
  title: 'Profile',
};

export default async function ProfilePage() {
  const { user, appRole, displayName } = await getAuthProfile();

  if (!user) {
    redirect('/login');
  }

  const supabase = await createClient();
  const { data: profile } = await supabase
    .from('users')
    .select('login_type')
    .eq('id', user.id)
    .maybeSingle();

  const label = resolveDisplayLabel(displayName, user.email);
  const avatarUrl = `https://ui-avatars.com/api/?name=${encodeURIComponent(label)}&background=random&size=96`;
  const showDeletion = !(await isAccountDeletionBlocked({ user, appRole, supabase }));

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <Heading level="h1" className="mb-8">
        Profile
      </Heading>

      <div className="flex flex-col gap-6">
        <div className="flex items-center gap-4">
          <Image src={avatarUrl} alt={label} className="rounded-full" width={96} height={96} />
          <div>
            <p className="text-xl font-semibold">{label}</p>
            <p className="text-muted-foreground text-sm">{user.email}</p>
          </div>
        </div>

        <div className="border-t pt-6">
          <dl className="flex flex-col gap-4">
            <div>
              <dt className="text-muted-foreground text-sm font-medium">Email</dt>
              <dd>{user.email}</dd>
            </div>
            <div>
              <dt className="text-muted-foreground text-sm font-medium">Login Type</dt>
              <dd className="capitalize">{profile?.login_type || 'email'}</dd>
            </div>
            <div>
              <dt className="text-muted-foreground text-sm font-medium">Member Since</dt>
              <dd>
                {new Date(user.created_at).toLocaleDateString('ja-JP', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                })}
              </dd>
            </div>
          </dl>
        </div>

        <div className="border-t pt-6">
          <DisplayNameForm defaultDisplayName={displayName?.trim() ?? ''} />
        </div>

        <div className="border-t pt-6">
          <Link
            href="/list"
            className="text-foreground text-sm font-medium underline-offset-4 hover:underline"
          >
            リスト
          </Link>
        </div>

        <div className="border-t pt-6">
          <SignOutButton />
        </div>

        {showDeletion ? (
          <div className="border-t pt-6">
            <DeleteAccountSection />
          </div>
        ) : null}
      </div>
    </div>
  );
}
