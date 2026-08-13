import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';

import { fetchDrinkLogSummary, fetchMyDrinkLogs } from '@/application/drink-logs-api.server';
import { getOptionalAccessToken } from '@/application/require-access-token';
import { Badge } from '@/components/ui/badge';
import { buttonVariants } from '@/components/ui/button';
import { Heading } from '@/components/ui/heading';
import { findServingPreset } from '@/config/serving-presets';
import {
  addUtcDays,
  groupLogsByTokyoDay,
  startOfTokyoDayUtc,
} from '@/utils/drink-log-day';
import { cn } from '@/utils/utils';
import { formatVolumeDisplay, round2 } from '@/utils/volume';

import { DeleteLogButton } from './delete-log-button';

export const metadata: Metadata = {
  title: '飲んだ記録',
};

function startOfWeekTokyo(date: Date): Date {
  const tokyoToday = startOfTokyoDayUtc(date);
  // Get weekday in Tokyo for "today"
  const weekday = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Tokyo',
    weekday: 'short',
  }).format(date);
  const map: Record<string, number> = {
    Mon: 0,
    Tue: 1,
    Wed: 2,
    Thu: 3,
    Fri: 4,
    Sat: 5,
    Sun: 6,
  };
  const offset = map[weekday] ?? 0;
  return addUtcDays(tokyoToday, -offset);
}

export default async function MyLogsPage() {
  const { user, accessToken } = await getOptionalAccessToken();
  if (!user || !accessToken) {
    redirect('/login');
  }

  const weekStart = startOfWeekTokyo(new Date());
  const weekEnd = addUtcDays(weekStart, 7);
  const from = weekStart.toISOString();
  const to = weekEnd.toISOString();

  const listFrom = addUtcDays(startOfTokyoDayUtc(new Date()), -29).toISOString();
  const listTo = addUtcDays(startOfTokyoDayUtc(new Date()), 1).toISOString();

  const [summary, logs] = await Promise.all([
    fetchDrinkLogSummary(accessToken, from, to),
    fetchMyDrinkLogs(accessToken, { limit: 100, from: listFrom, to: listTo }),
  ]);

  const daySections = groupLogsByTokyoDay(logs);

  const weekLabel = `${weekStart.toLocaleDateString('ja-JP', {
    timeZone: 'Asia/Tokyo',
    month: 'short',
    day: 'numeric',
  })} – ${addUtcDays(weekEnd, -1).toLocaleDateString('ja-JP', {
    timeZone: 'Asia/Tokyo',
    month: 'short',
    day: 'numeric',
  })}`;

  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <div className="mb-8 flex flex-wrap items-start justify-between gap-4">
        <div>
          <Heading level="h1" className="mb-2">
            飲んだ記録
          </Heading>
          <p className="text-muted-foreground text-sm">
            飲んだ量を残して、日ごと・週ごとの目安摂取量を確認できます。
          </p>
        </div>
        <Link href="/my-logs/new" className={cn(buttonVariants())}>
          記録を追加
        </Link>
      </div>

      <section
        aria-labelledby="week-summary-heading"
        className="bg-muted/40 mb-10 rounded-xl border p-5"
      >
        <Heading level="h2" id="week-summary-heading" className="mb-1 text-base">
          今週の摂取量
        </Heading>
        <p className="text-muted-foreground mb-4 text-xs">{weekLabel}</p>
        {summary ? (
          <dl className="grid grid-cols-2 gap-4 sm:grid-cols-3">
            <div>
              <dt className="text-muted-foreground text-xs">純アルコール</dt>
              <dd className="text-2xl font-semibold tabular-nums">
                {round2(summary.pureAlcoholGrams)}
                <span className="ml-1 text-sm font-normal">g</span>
              </dd>
            </div>
            <div>
              <dt className="text-muted-foreground text-xs">杯数</dt>
              <dd className="text-2xl font-semibold tabular-nums">{summary.logCount}</dd>
            </div>
            {summary.skippedMissingAbv > 0 && (
              <div className="col-span-2 sm:col-span-1">
                <dt className="text-muted-foreground text-xs">度数不明のため未算入</dt>
                <dd className="text-lg font-medium tabular-nums">{summary.skippedMissingAbv}件</dd>
              </div>
            )}
          </dl>
        ) : (
          <p className="text-muted-foreground text-sm">集計を取得できませんでした。</p>
        )}
      </section>

      <section aria-labelledby="recent-logs-heading" className="space-y-6">
        <Heading level="h2" id="recent-logs-heading">
          直近30日の記録
        </Heading>

        {daySections.length === 0 ? (
          <div className="rounded-lg border border-dashed p-8 text-center">
            <p className="text-muted-foreground mb-3 text-sm">まだ記録がありません。</p>
            <Link href="/my-logs/new" className="text-foreground text-sm font-medium underline">
              最初の記録を追加する
            </Link>
          </div>
        ) : (
          daySections.map((section) => (
            <section
              key={section.dayKey}
              aria-labelledby={`day-${section.dayKey}`}
              className="space-y-3"
            >
              <div className="flex flex-wrap items-baseline justify-between gap-2 border-b pb-2">
                <Heading level="h3" id={`day-${section.dayKey}`} className="text-base">
                  {section.label}
                </Heading>
                <p className="text-muted-foreground text-sm tabular-nums">
                  {section.drinkCount}杯
                  <span className="mx-1.5">·</span>
                  {section.pureAlcoholGrams}g
                  {section.skippedMissingAbv > 0 && (
                    <span className="ml-2 text-xs">
                      （度数不明 {section.skippedMissingAbv}杯を未算入）
                    </span>
                  )}
                </p>
              </div>

              <ul className="space-y-3">
                {section.logs.map((log) => {
                  const presetLabel = log.servingKey
                    ? findServingPreset(log.servingKey)?.label
                    : undefined;
                  const volumeLabel = formatVolumeDisplay(
                    log.inputUnit,
                    log.inputValue,
                    log.volumeMl,
                  );
                  const title = log.drink?.name ?? log.customDrinkName ?? '不明な銘柄';

                  return (
                    <li
                      key={log.id}
                      className="flex items-start justify-between gap-3 rounded-lg border p-3"
                    >
                      <div className="min-w-0 space-y-1">
                        {log.drink ? (
                          <Link
                            href={`/drinks/${log.drink.slug}`}
                            className="font-medium hover:underline"
                          >
                            {title}
                          </Link>
                        ) : (
                          <p className="font-medium">
                            {title}
                            {log.customDrinkName && (
                              <span className="ml-2">
                                <Badge variant="secondary">未登録</Badge>
                              </span>
                            )}
                          </p>
                        )}
                        <p className="text-muted-foreground text-sm">
                          {presetLabel ? `${presetLabel} · ${volumeLabel}` : volumeLabel}
                          {log.quantity > 1 && (
                            <span className="tabular-nums"> × {log.quantity}杯</span>
                          )}
                          {log.volumePrecision === 'estimated' && (
                            <span className="ml-2">
                              <Badge variant="secondary">目安</Badge>
                            </span>
                          )}
                        </p>
                        {(log.placeName || log.placeUrl) && (
                          <p className="text-muted-foreground text-xs break-all">
                            {log.placeName && <span>{log.placeName}</span>}
                            {log.placeName && log.placeUrl && <span> · </span>}
                            {log.placeUrl &&
                              (log.placeUrl.startsWith('http://') ||
                              log.placeUrl.startsWith('https://') ? (
                                <a
                                  href={log.placeUrl}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="underline underline-offset-2"
                                >
                                  リンク
                                </a>
                              ) : (
                                <span>{log.placeUrl}</span>
                              ))}
                          </p>
                        )}
                        <p className="text-muted-foreground text-xs">
                          <Link
                            href={`/my-logs/${log.id}/edit`}
                            className="underline underline-offset-2"
                          >
                            編集
                          </Link>
                        </p>
                      </div>
                      <DeleteLogButton logId={log.id} />
                    </li>
                  );
                })}
              </ul>
            </section>
          ))
        )}
      </section>
    </div>
  );
}
