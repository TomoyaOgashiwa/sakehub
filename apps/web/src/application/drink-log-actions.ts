'use server';

import { revalidatePath } from 'next/cache';
import type { DrinkLog } from '@sakehub/types';

import { toDrinkLog, type ApiDrinkLog } from '@/application/drink-log-mappers';
import { requireAccessToken } from '@/application/require-access-token';
import { authServerFetch } from '@/application/server-api';
import {
  drinkLogBatchSchema,
  drinkLogDayReplaceSchema,
  drinkLogUpdateSchema,
  firstZodErrorMessage,
  zonedDateToIso,
  zodIssuesToFieldErrors,
} from '@/utils/drink-log-schema';

export type DrinkLogActionState =
  | { ok: true; data?: DrinkLog | DrinkLog[] }
  | { ok: false; error: string; fieldErrors?: Record<string, string> };

function authError(tokenError: string, verb: string): DrinkLogActionState {
  return {
    ok: false,
    error: tokenError.includes('ログイン') ? `${verb}するにはログインが必要です。` : tokenError,
  };
}

export async function createDrinkLogBatch(
  _prevState: DrinkLogActionState,
  formData: FormData,
): Promise<DrinkLogActionState> {
  const token = await requireAccessToken();
  if (!token.ok) {
    return authError(token.error, '記録');
  }

  const timeZone = ((formData.get('time_zone') as string | null) ?? '').trim();
  const drankAtRaw = ((formData.get('drank_at') as string | null) ?? '').trim();
  const placeName = ((formData.get('place_name') as string | null) ?? '').trim();
  const placeUrl = ((formData.get('place_url') as string | null) ?? '').trim();
  const itemsJSON = ((formData.get('items_json') as string | null) ?? '').trim();

  let itemsUnknown: unknown;
  try {
    itemsUnknown = JSON.parse(itemsJSON);
  } catch {
    return { ok: false, error: 'お酒リストの形式が不正です。' };
  }

  const parsed = drinkLogBatchSchema.safeParse({
    time_zone: timeZone,
    ...(drankAtRaw ? { drank_at: drankAtRaw } : {}),
    place_name: placeName,
    place_url: placeUrl,
    items: itemsUnknown,
  });

  if (!parsed.success) {
    return {
      ok: false,
      error: firstZodErrorMessage(parsed.error),
      fieldErrors: zodIssuesToFieldErrors(parsed.error),
    };
  }

  const { drank_at, place_name, place_url, items, time_zone } = parsed.data;

  const result = await authServerFetch<{ data: ApiDrinkLog[] }>('/api/auth/drink-logs', {
    accessToken: token.accessToken,
    method: 'POST',
    body: {
      ...(drank_at ? { drank_at: zonedDateToIso(drank_at, time_zone) } : {}),
      ...(place_name ? { place_name } : {}),
      ...(place_url ? { place_url } : {}),
      items,
    },
  });

  if (!result.ok) {
    return { ok: false, error: result.error };
  }

  revalidatePath('/my-logs');
  return { ok: true, data: (result.data.data ?? []).map(toDrinkLog) };
}

export async function replaceDrinkLogsForDay(
  _prevState: DrinkLogActionState,
  formData: FormData,
): Promise<DrinkLogActionState> {
  const token = await requireAccessToken();
  if (!token.ok) {
    return authError(token.error, '編集');
  }

  const timeZone = ((formData.get('time_zone') as string | null) ?? '').trim();
  const rangeFrom = ((formData.get('range_from') as string | null) ?? '').trim();
  const rangeTo = ((formData.get('range_to') as string | null) ?? '').trim();
  const drankAtRaw = ((formData.get('drank_at') as string | null) ?? '').trim();
  const placeName = ((formData.get('place_name') as string | null) ?? '').trim();
  const placeUrl = ((formData.get('place_url') as string | null) ?? '').trim();
  const itemsJSON = ((formData.get('items_json') as string | null) ?? '').trim();

  let itemsUnknown: unknown;
  try {
    itemsUnknown = JSON.parse(itemsJSON);
  } catch {
    return { ok: false, error: 'お酒リストの形式が不正です。' };
  }

  const parsed = drinkLogDayReplaceSchema.safeParse({
    time_zone: timeZone,
    range_from: rangeFrom,
    range_to: rangeTo,
    drank_at: drankAtRaw,
    place_name: placeName,
    place_url: placeUrl,
    items: itemsUnknown,
  });

  if (!parsed.success) {
    return {
      ok: false,
      error: firstZodErrorMessage(parsed.error),
      fieldErrors: zodIssuesToFieldErrors(parsed.error),
    };
  }

  const { drank_at, place_name, place_url, items, time_zone, range_from, range_to } = parsed.data;

  const result = await authServerFetch<{ data: ApiDrinkLog[] }>('/api/auth/drink-logs/day', {
    accessToken: token.accessToken,
    method: 'PUT',
    body: {
      range_from,
      range_to,
      drank_at: zonedDateToIso(drank_at, time_zone),
      place_name: place_name ?? null,
      place_url: place_url ?? null,
      items,
    },
  });

  if (!result.ok) {
    return { ok: false, error: result.error };
  }

  revalidatePath('/my-logs');
  return { ok: true, data: (result.data.data ?? []).map(toDrinkLog) };
}

export async function updateDrinkLog(
  logId: string,
  _prevState: DrinkLogActionState,
  formData: FormData,
): Promise<DrinkLogActionState> {
  const token = await requireAccessToken();
  if (!token.ok) {
    return authError(token.error, '編集');
  }

  if (!logId.trim()) {
    return { ok: false, error: '記録 ID が不正です。' };
  }

  const timeZone = ((formData.get('time_zone') as string | null) ?? '').trim();
  const drankAtRaw = ((formData.get('drank_at') as string | null) ?? '').trim();
  const placeName = ((formData.get('place_name') as string | null) ?? '').trim();
  const placeUrl = ((formData.get('place_url') as string | null) ?? '').trim();
  const itemJSON = ((formData.get('item_json') as string | null) ?? '').trim();

  let itemUnknown: unknown;
  try {
    itemUnknown = JSON.parse(itemJSON);
  } catch {
    return { ok: false, error: 'お酒データの形式が不正です。' };
  }

  const itemObj =
    itemUnknown && typeof itemUnknown === 'object' ? (itemUnknown as Record<string, unknown>) : {};

  const parsed = drinkLogUpdateSchema.safeParse({
    time_zone: timeZone,
    ...(drankAtRaw ? { drank_at: drankAtRaw } : {}),
    place_name: placeName,
    place_url: placeUrl,
    ...itemObj,
  });

  if (!parsed.success) {
    return {
      ok: false,
      error: firstZodErrorMessage(parsed.error),
      fieldErrors: zodIssuesToFieldErrors(parsed.error),
    };
  }

  const data = parsed.data;
  const result = await authServerFetch<ApiDrinkLog>(
    `/api/auth/drink-logs/${encodeURIComponent(logId)}`,
    {
      accessToken: token.accessToken,
      method: 'PATCH',
      body: {
        ...(data.drank_at ? { drank_at: zonedDateToIso(data.drank_at, data.time_zone) } : {}),
        place_name: data.place_name ?? null,
        place_url: data.place_url ?? null,
        ...(data.drink_id ? { drink_id: data.drink_id } : {}),
        ...(data.custom_drink_name ? { custom_drink_name: data.custom_drink_name } : {}),
        input_unit: data.input_unit,
        input_value: data.input_value,
        volume_precision: data.volume_precision,
        quantity: data.quantity,
        ...(data.serving_key ? { serving_key: data.serving_key } : {}),
      },
    },
  );

  if (!result.ok) {
    return { ok: false, error: result.error };
  }

  revalidatePath('/my-logs');
  revalidatePath(`/my-logs/${logId}/edit`);
  return { ok: true, data: toDrinkLog(result.data) };
}

export async function deleteDrinkLog(logId: string): Promise<DrinkLogActionState> {
  const token = await requireAccessToken();
  if (!token.ok) {
    return authError(token.error, '削除');
  }

  const result = await authServerFetch(`/api/auth/drink-logs/${encodeURIComponent(logId)}`, {
    accessToken: token.accessToken,
    method: 'DELETE',
    emptyResponse: true,
  });

  if (!result.ok) {
    return { ok: false, error: result.error };
  }

  revalidatePath('/my-logs');
  return { ok: true };
}
