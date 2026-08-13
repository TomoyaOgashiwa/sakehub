import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { ArrowLeft } from 'lucide-react';

import { fetchDrinkLogById } from '@/application/drink-logs-api.server';
import { getRequestTimeZone } from '@/application/request-time-zone';
import { getOptionalAccessToken } from '@/application/require-access-token';
import { Heading } from '@/components/ui/heading';

import { EditLogForm } from './edit-log-form';

export const metadata: Metadata = {
  title: '記録を編集',
};

type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function EditDrinkLogPage({ params }: PageProps) {
  const { id } = await params;
  const { user, accessToken } = await getOptionalAccessToken();
  if (!user || !accessToken) {
    redirect('/login');
  }

  const log = await fetchDrinkLogById(accessToken, id);
  if (!log) {
    notFound();
  }

  const timeZone = await getRequestTimeZone();

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <nav className="mb-6">
        <Link
          href="/my-logs"
          className="text-muted-foreground hover:text-foreground inline-flex items-center gap-1 text-sm transition-colors"
        >
          <ArrowLeft className="size-4" aria-hidden="true" />
          記録一覧に戻る
        </Link>
      </nav>

      <Heading level="h1" className="mb-2">
        記録を編集
      </Heading>
      <p className="text-muted-foreground mb-8 text-sm">銘柄・量・日時・場所を修正できます。</p>

      <EditLogForm log={log} timeZone={timeZone} />
    </div>
  );
}
