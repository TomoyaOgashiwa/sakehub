import type { DrinkLog } from '@sakehub/types';

import { addCalendarYmd, zonedDateToIso, zonedDayKey } from '@/utils/time-zone';
import { pureAlcoholGrams, round2 } from '@/utils/volume';

export interface DrinkLogDaySection {
  /** YYYY-MM-DD in the viewer's time zone */
  dayKey: string;
  label: string;
  logs: DrinkLog[];
  drinkCount: number;
  pureAlcoholGrams: number;
  skippedMissingAbv: number;
}

export function formatZonedDayLabel(dayKey: string): string {
  const [y, m, d] = dayKey.split('-').map(Number);
  const date = new Date(Date.UTC(y, m - 1, d, 12));
  return new Intl.DateTimeFormat('ja-JP', {
    timeZone: 'UTC',
    month: 'long',
    day: 'numeric',
    weekday: 'short',
  }).format(date);
}

export function startOfWeekZoned(date: Date, timeZone: string): Date {
  const todayYmd = zonedDayKey(date.toISOString(), timeZone);
  const weekday = new Intl.DateTimeFormat('en-US', {
    timeZone,
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
  return new Date(zonedDateToIso(addCalendarYmd(todayYmd, -offset), timeZone));
}

export function groupLogsByZonedDay(logs: DrinkLog[], timeZone: string): DrinkLogDaySection[] {
  const map = new Map<string, DrinkLog[]>();
  for (const log of logs) {
    const key = zonedDayKey(log.drankAt, timeZone);
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
      label: formatZonedDayLabel(dayKey),
      logs: dayLogs,
      drinkCount,
      pureAlcoholGrams: round2(grams),
      skippedMissingAbv: skipped,
    };
  });
}
