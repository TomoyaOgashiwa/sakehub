import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';

import { Heading } from '@/components/ui/heading';
import { getAuthProfile } from '@/lib/auth/app-role';
import { createClient } from '@/lib/supabase/server';
import { loginHref } from '@/utils/login-href';

import { DisplayNameForm } from '../display-name-form';

export const metadata: Metadata = {
  title: '表示名を変更',
};

export default async function ProfileDisplayNamePage() {
  const { user, displayName } = await getAuthProfile();

  if (!user) {
    redirect(loginHref('/profile/display-name'));
  }

  const supabase = await createClient();
  const { data: profile } = await supabase
    .from('users')
    .select('login_type')
    .eq('id', user.id)
    .maybeSingle();

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <p className="mb-2">
        <Link href="/profile" className="text-muted-foreground text-sm hover:underline">
          プロフィールへ
        </Link>
      </p>
      <Heading level="h1" className="mb-8">
        表示名を変更
      </Heading>

      <div className="flex flex-col gap-8">
        <DisplayNameForm defaultDisplayName={displayName?.trim() ?? ''} />

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
      </div>
    </div>
  );
}
