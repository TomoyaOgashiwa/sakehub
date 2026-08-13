import type { DrinkLog } from '@sakehub/types';

import { pureAlcoholGrams, round2 } from '@/utils/volume';

const TOKYO = 'Asia/Tokyo';

export interface DrinkLogDaySection {
  /** YYYY-MM-DD in Asia/Tokyo */
  dayKey: string;
  label: string;
  logs: DrinkLog[];
  drinkCount: number;
  pureAlcoholGrams: number;
  skippedMissingAbv: number;
}

export function tokyoDayKey(iso: string): string {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: TOKYO,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date(iso));
  const year = parts.find((p) => p.type === 'year')?.value;
  const month = parts.find((p) => p.type === 'month')?.value;
  const day = parts.find((p) => p.type === 'day')?.value;
  return `${year}-${month}-${day}`;
}

export function formatTokyoDayLabel(dayKey: string): string {
  const [y, m, d] = dayKey.split('-').map(Number);
  // Noon UTC on that calendar day is unambiguous for weekday labeling.
  const date = new Date(Date.UTC(y, m - 1, d, 12));
  return new Intl.DateTimeFormat('ja-JP', {
    timeZone: 'UTC',
    month: 'long',
    day: 'numeric',
    weekday: 'short',
  }).format(date);
}

export function startOfTokyoDayUtc(reference = new Date()): Date {
  const key = tokyoDayKey(reference.toISOString());
  const [y, m, d] = key.split('-').map(Number);
  // Tokyo midnight = UTC previous day 15:00
  return new Date(Date.UTC(y, m - 1, d, 0, 0, 0) - 9 * 60 * 60 * 1000);
}

export function addUtcDays(date: Date, days: number): Date {
  const next = new Date(date);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
}

export function groupLogsByTokyoDay(logs: DrinkLog[]): DrinkLogDaySection[] {
  const map = new Map<string, DrinkLog[]>();
  for (const log of logs) {
    const key = tokyoDayKey(log.drankAt);
    const bucket = map.get(key);
    if (bucket) {
      bucket.push(log);
    } else {
      map.set(key, [log]);
    }
  }

  const keys = [...map.keys()].sort((a, b) => (a < b ? 1 : a > b ? -1 : 0));
  return keys.map((dayKey) => {
    const dayLogs = map.get(dayKey) ?? [];
    let drinkCount = 0;
    let grams = 0;
    let skipped = 0;
    for (const log of dayLogs) {
      drinkCount += log.quantity;
      const abv = log.drink?.abv;
      if (abv == null) {
        skipped += log.quantity;
        continue;
      }
      grams += pureAlcoholGrams(log.volumeMl * log.quantity, abv);
    }
    return {
      dayKey,
      label: formatTokyoDayLabel(dayKey),
      logs: dayLogs,
      drinkCount,
      pureAlcoholGrams: round2(grams),
      skippedMissingAbv: skipped,
    };
  });
}
