import Image from 'next/image';
import Link from 'next/link';
import { redirect } from 'next/navigation';

import { Heading } from '@/components/ui/heading';
import { createClient } from '@/lib/supabase/server';

import { SignOutButton } from './sign-out-button';

export const metadata = {
  title: 'Profile',
};

export default async function ProfilePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login');
  }

  const { data: profile } = await supabase.from('users').select('*').eq('id', user.id).single();

  const displayName = profile?.display_name || user.email?.split('@')[0] || 'User';
  const avatarUrl = `https://ui-avatars.com/api/?name=${encodeURIComponent(displayName)}&background=random&size=96`;

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <Heading level="h1" className="mb-8">
        Profile
      </Heading>

      <div className="space-y-6">
        <div className="flex items-center gap-4">
          <Image
            src={avatarUrl}
            alt={displayName}
            className="rounded-full"
            width={96}
            height={96}
          />
          <div>
            <p className="text-xl font-semibold">{displayName}</p>
            <p className="text-muted-foreground text-sm">{user.email}</p>
          </div>
        </div>

        <div className="border-t pt-6">
          <dl className="space-y-4">
            <div>
              <dt className="text-muted-foreground text-sm font-medium">Email</dt>
              <dd>{user.email}</dd>
            </div>
            <div>
              <dt className="text-muted-foreground text-sm font-medium">Display Name</dt>
              <dd>{profile?.display_name || '-'}</dd>
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
      </div>
    </div>
  );
}
