import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';

import { Heading } from '@/components/ui/heading';
import { isAccountDeletionBlocked } from '@/lib/auth/account-deletion';
import { getAuthProfile } from '@/lib/auth/app-role';
import { createClient } from '@/lib/supabase/server';
import { loginHref } from '@/utils/login-href';

import { DeleteAccountSection } from '../delete-account-section';

export const metadata: Metadata = {
  title: '退会',
};

export default async function ProfileDeletePage() {
  const { user, appRole } = await getAuthProfile();

  if (!user) {
    redirect(loginHref('/profile/delete'));
  }

  const supabase = await createClient();
  const blocked = await isAccountDeletionBlocked({ user, appRole, supabase });
  if (blocked) {
    redirect('/profile');
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <p className="mb-2">
        <Link href="/profile" className="text-muted-foreground text-sm hover:underline">
          プロフィールへ
        </Link>
      </p>
      <Heading level="h1" className="mb-8">
        退会
      </Heading>
      <DeleteAccountSection />
    </div>
  );
}
