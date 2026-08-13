import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { ArrowLeft } from 'lucide-react';
import type { DrinkLog } from '@sakehub/types';

import { fetchMyDrinkLogs } from '@/application/drink-logs-api.server';
import { getRequestTimeZone } from '@/application/request-time-zone';
import { getOptionalAccessToken } from '@/application/require-access-token';
import { DrinkLogBatchForm } from '@/components/drink-logs/drink-log-batch-form';
import { logToLine } from '@/components/drink-logs/drink-log-line';
import { Heading } from '@/components/ui/heading';
import { addCalendarYmd, zonedDateToIso } from '@/utils/time-zone';

export const metadata: Metadata = {
  title: 'この日の記録を編集',
};

type PageProps = {
  params: Promise<{ date: string }>;
};

function sharedPlace(logs: DrinkLog[]): { name: string; url: string; mixed: boolean } {
  const names = new Set(logs.map((log) => log.placeName ?? ''));
  const urls = new Set(logs.map((log) => log.placeUrl ?? ''));
  if (names.size <= 1 && urls.size <= 1) {
    return {
      name: logs[0]?.placeName ?? '',
      url: logs[0]?.placeUrl ?? '',
      mixed: false,
    };
  }
  return { name: '', url: '', mixed: true };
}

export default async function EditDrinkLogsForDayPage({ params }: PageProps) {
  const { date } = await params;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    notFound();
  }

  const { user, accessToken } = await getOptionalAccessToken();
  if (!user || !accessToken) {
    redirect('/login');
  }

  const timeZone = await getRequestTimeZone();
  const rangeFrom = zonedDateToIso(date, timeZone);
  const rangeTo = zonedDateToIso(addCalendarYmd(date, 1), timeZone);

  const logs = await fetchMyDrinkLogs(accessToken, {
    limit: 20,
    from: rangeFrom,
    to: rangeTo,
  });
  if (logs.length === 0) {
    notFound();
  }

  const place = sharedPlace(logs);

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
        この日の記録を編集
      </Heading>
      <p className="text-muted-foreground mb-8 text-sm">
        同じ日に飲んだお酒をまとめて修正できます。行の追加・削除もできます。
      </p>

      <DrinkLogBatchForm
        mode="day-edit"
        timeZone={timeZone}
        initialDrankAt={date}
        initialPlaceName={place.name}
        initialPlaceUrl={place.url}
        initialLines={logs.map(logToLine)}
        rangeFrom={rangeFrom}
        rangeTo={rangeTo}
        placeMixed={place.mixed}
      />
    </div>
  );
}
