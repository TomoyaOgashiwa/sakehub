export const TIME_ZONE_COOKIE = 'sakehub-tz';

const FALLBACK_TIME_ZONE = 'UTC';

export function isValidTimeZone(timeZone: string): boolean {
  if (!timeZone) return false;
  try {
    Intl.DateTimeFormat('en-US', { timeZone });
    return true;
  } catch {
    return false;
  }
}

export function resolveTimeZone(timeZone: string | null | undefined): string {
  if (timeZone && isValidTimeZone(timeZone)) {
    return timeZone;
  }
  return FALLBACK_TIME_ZONE;
}

export function getBrowserTimeZone(): string {
  return resolveTimeZone(Intl.DateTimeFormat().resolvedOptions().timeZone);
}

/** Offset of `timeZone` at `date` (local = UTC + offset). */
function timeZoneOffsetMs(date: Date, timeZone: string): number {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date);

  const value = (type: Intl.DateTimeFormatPartTypes) =>
    Number(parts.find((part) => part.type === type)?.value);

  const asUtc = Date.UTC(
    value('year'),
    value('month') - 1,
    value('day'),
    value('hour'),
    value('minute'),
    value('second'),
  );
  return asUtc - date.getTime();
}

export function zonedDayKey(iso: string, timeZone: string): string {
  const tz = resolveTimeZone(timeZone);
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: tz,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date(iso));
  const year = parts.find((p) => p.type === 'year')?.value;
  const month = parts.find((p) => p.type === 'month')?.value;
  const day = parts.find((p) => p.type === 'day')?.value;
  return `${year}-${month}-${day}`;
}

/** Format an ISO timestamp as YYYY-MM-DD in `timeZone`. */
export function isoToZonedDateInput(iso: string, timeZone: string): string {
  return zonedDayKey(iso, timeZone);
}

/** Today's calendar date in `timeZone` as YYYY-MM-DD. */
export function todayYmdInTimeZone(timeZone: string, reference = new Date()): string {
  return isoToZonedDateInput(reference.toISOString(), timeZone);
}

/**
 * Calendar today in the JS runtime's local timezone.
 * Use from the browser (not Server Components — Node is usually UTC).
 */
export function localTodayYmd(reference = new Date()): string {
  const year = reference.getFullYear();
  const month = String(reference.getMonth() + 1).padStart(2, '0');
  const day = String(reference.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Create/update payload for `drank_at`:
 * today's calendar date → the current UTC instant;
 * any past date → local midnight in `timeZone`.
 */
export function ymdToDrankAtIso(ymd: string, timeZone: string, now = new Date()): string {
  if (ymd === todayYmdInTimeZone(timeZone, now)) {
    return now.toISOString();
  }
  return zonedDateToIso(ymd, timeZone);
}

/**
 * Interpret YYYY-MM-DD as local midnight in `timeZone`, return ISO UTC.
 * Two-pass offset correction handles DST.
 */
export function zonedDateToIso(ymd: string, timeZone: string): string {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(ymd);
  if (!match) {
    throw new Error('invalid date');
  }
  const tz = resolveTimeZone(timeZone);
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const utcGuess = Date.UTC(year, month - 1, day, 0, 0, 0);
  const offset1 = timeZoneOffsetMs(new Date(utcGuess), tz);
  const instant1 = utcGuess - offset1;
  const offset2 = timeZoneOffsetMs(new Date(instant1), tz);
  return new Date(utcGuess - offset2).toISOString();
}

export function startOfZonedDayUtc(reference: Date, timeZone: string): Date {
  const key = zonedDayKey(reference.toISOString(), timeZone);
  return new Date(zonedDateToIso(key, timeZone));
}

export function addCalendarYmd(ymd: string, days: number): string {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(ymd);
  if (!match) {
    throw new Error('invalid date');
  }
  const dt = new Date(
    Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3]) + days, 12),
  );
  const year = dt.getUTCFullYear();
  const month = String(dt.getUTCMonth() + 1).padStart(2, '0');
  const day = String(dt.getUTCDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}
