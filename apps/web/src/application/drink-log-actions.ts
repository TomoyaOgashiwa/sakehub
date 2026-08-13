'use server';

import { revalidatePath } from 'next/cache';
import type { DrinkLog, VolumePrecision, VolumeUnit } from '@sakehub/types';

import { toDrinkLog, type ApiDrinkLog } from '@/application/drink-log-mappers';
import { requireAccessToken } from '@/application/require-access-token';
import { authServerFetch } from '@/application/server-api';

export type DrinkLogActionState =
  | { ok: true; data?: DrinkLog[] }
  | { ok: false; error: string };

interface BatchItemPayload {
  drink_id?: string;
  custom_drink_name?: string;
  input_unit: VolumeUnit;
  input_value: number;
  serving_key?: string;
  volume_precision: VolumePrecision;
  quantity?: number;
}

export async function createDrinkLogBatch(
  _prevState: DrinkLogActionState,
  formData: FormData,
): Promise<DrinkLogActionState> {
  const token = await requireAccessToken();
  if (!token.ok) {
    return {
      ok: false,
      error: token.error.includes('ログイン')
        ? '記録するにはログインが必要です。'
        : token.error,
    };
  }

  const drankAtRaw = ((formData.get('drank_at') as string | null) ?? '').trim();
  const placeName = ((formData.get('place_name') as string | null) ?? '').trim();
  const placeUrl = ((formData.get('place_url') as string | null) ?? '').trim();
  const itemsJSON = ((formData.get('items_json') as string | null) ?? '').trim();

  let items: BatchItemPayload[];
  try {
    const parsed = JSON.parse(itemsJSON) as BatchItemPayload[];
    if (!Array.isArray(parsed) || parsed.length === 0) {
      return { ok: false, error: '飲んだお酒を1つ以上追加してください。' };
    }
    items = parsed;
  } catch {
    return { ok: false, error: 'お酒リストの形式が不正です。' };
  }

  let drankAt: string | undefined;
  if (drankAtRaw) {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(drankAtRaw);
    if (!match) {
      return { ok: false, error: '日付が不正です。' };
    }
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const parsed = new Date(year, month - 1, day);
    if (
      Number.isNaN(parsed.getTime()) ||
      parsed.getFullYear() !== year ||
      parsed.getMonth() !== month - 1 ||
      parsed.getDate() !== day
    ) {
      return { ok: false, error: '日付が不正です。' };
    }
    drankAt = parsed.toISOString();
  }

  const result = await authServerFetch<{ data: ApiDrinkLog[] }>('/api/auth/drink-logs', {
    accessToken: token.accessToken,
    method: 'POST',
    body: {
      ...(drankAt ? { drank_at: drankAt } : {}),
      ...(placeName ? { place_name: placeName } : {}),
      ...(placeUrl ? { place_url: placeUrl } : {}),
      items,
    },
  });

  if (!result.ok) {
    return { ok: false, error: result.error };
  }

  revalidatePath('/my-logs');
  return { ok: true, data: (result.data.data ?? []).map(toDrinkLog) };
}

export async function deleteDrinkLog(logId: string): Promise<DrinkLogActionState> {
  const token = await requireAccessToken();
  if (!token.ok) {
    return {
      ok: false,
      error: token.error.includes('ログイン')
        ? '削除するにはログインが必要です。'
        : token.error,
    };
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
