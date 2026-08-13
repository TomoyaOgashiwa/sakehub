'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import type { SavedDrink, SavedDrinkStatus } from '@sakehub/types';

import { isSafeSlug, isSafeUUID } from '@/application/rating-action-helpers';
import { requireAccessToken } from '@/application/require-access-token';
import { toSavedDrink, type ApiSavedDrink } from '@/application/saved-drink-mappers';
import { authServerFetch } from '@/application/server-api';

export type SavedDrinkActionState = { ok: true; data?: SavedDrink } | { ok: false; error: string };

const MAX_NOTE_LEN = 280;
// Keep in sync with apps/api saveddrink.MaxProvisionalRaw.
const MAX_PROVISIONAL_NAME_LEN = 200;

function revalidateSavedDrinkPaths(slug: string) {
  if (isSafeSlug(slug)) {
    revalidatePath(`/drinks/${slug}`);
  }
  revalidatePath('/list');
  revalidatePath('/');
}

function isSavedDrinkStatus(value: string): value is SavedDrinkStatus {
  return value === 'drank' || value === 'want';
}

export async function saveDrink(
  drinkId: string,
  drinkSlug: string,
  status: SavedDrinkStatus,
): Promise<SavedDrinkActionState> {
  if (!isSafeUUID(drinkId)) {
    return { ok: false, error: 'drink_id が見つかりません。' };
  }
  if (!isSavedDrinkStatus(status)) {
    return { ok: false, error: '意図を選んでください。' };
  }

  const auth = await requireAccessToken();
  if (!auth.ok) {
    return { ok: false, error: 'リストに残すにはログインが必要です。' };
  }

  const result = await authServerFetch<ApiSavedDrink>('/api/auth/saved-drinks', {
    method: 'POST',
    accessToken: auth.accessToken,
    body: { drink_id: drinkId, status },
  });
  if (!result.ok) {
    return { ok: false, error: result.error || 'リストへの追加に失敗しました。' };
  }

  revalidateSavedDrinkPaths(drinkSlug);
  return { ok: true, data: toSavedDrink(result.data) };
}

export async function saveProvisionalDrink(
  name: string,
  status: SavedDrinkStatus,
): Promise<SavedDrinkActionState> {
  const trimmed = name.trim();
  if (!trimmed) {
    return { ok: false, error: '名前を入力してください。' };
  }
  if ([...trimmed].length > MAX_PROVISIONAL_NAME_LEN) {
    return { ok: false, error: `名前は${MAX_PROVISIONAL_NAME_LEN}文字以内で入力してください。` };
  }
  if (!isSavedDrinkStatus(status)) {
    return { ok: false, error: '意図を選んでください。' };
  }

  const auth = await requireAccessToken();
  if (!auth.ok) {
    return { ok: false, error: 'リストに残すにはログインが必要です。' };
  }

  const result = await authServerFetch<ApiSavedDrink>('/api/auth/saved-drinks/provisional', {
    method: 'POST',
    accessToken: auth.accessToken,
    body: { name: trimmed, status },
  });
  if (!result.ok) {
    return { ok: false, error: result.error || 'リストへの追加に失敗しました。' };
  }

  revalidatePath('/');
  revalidatePath('/list');
  redirect('/list');
}

export async function updateSavedDrink(
  drinkId: string,
  drinkSlug: string,
  patch: { status?: SavedDrinkStatus; note?: string },
): Promise<SavedDrinkActionState> {
  if (!isSafeUUID(drinkId)) {
    return { ok: false, error: 'drink_id が見つかりません。' };
  }
  if (patch.status === undefined && patch.note === undefined) {
    return { ok: false, error: '更新する内容がありません。' };
  }
  if (patch.status !== undefined && !isSavedDrinkStatus(patch.status)) {
    return { ok: false, error: '意図を選んでください。' };
  }
  if (patch.note !== undefined && [...patch.note].length > MAX_NOTE_LEN) {
    return { ok: false, error: `メモは${MAX_NOTE_LEN}文字以内で入力してください。` };
  }

  const auth = await requireAccessToken();
  if (!auth.ok) {
    return { ok: false, error: 'リストを更新するにはログインが必要です。' };
  }

  const body: { status?: SavedDrinkStatus; note?: string } = {};
  if (patch.status !== undefined) body.status = patch.status;
  if (patch.note !== undefined) body.note = patch.note;

  const result = await authServerFetch<ApiSavedDrink>(
    `/api/auth/saved-drinks/${encodeURIComponent(drinkId)}`,
    {
      method: 'PATCH',
      accessToken: auth.accessToken,
      body,
    },
  );
  if (!result.ok) {
    return { ok: false, error: result.error || 'リストの更新に失敗しました。' };
  }

  revalidateSavedDrinkPaths(drinkSlug);
  return { ok: true, data: toSavedDrink(result.data) };
}

export async function unsaveDrink(
  drinkId: string,
  drinkSlug: string,
): Promise<SavedDrinkActionState> {
  if (!isSafeUUID(drinkId)) {
    return { ok: false, error: 'drink_id が見つかりません。' };
  }

  const auth = await requireAccessToken();
  if (!auth.ok) {
    return { ok: false, error: 'リストから外すにはログインが必要です。' };
  }

  const result = await authServerFetch(`/api/auth/saved-drinks/${encodeURIComponent(drinkId)}`, {
    method: 'DELETE',
    accessToken: auth.accessToken,
    emptyResponse: true,
  });
  if (!result.ok) {
    return { ok: false, error: result.error || 'リストからの削除に失敗しました。' };
  }

  revalidateSavedDrinkPaths(drinkSlug);
  return { ok: true };
}
