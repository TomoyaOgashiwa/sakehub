'use server';

import { revalidatePath } from 'next/cache';
import type { SavedDrink } from '@sakehub/types';

import { isSafeSlug, isSafeUUID } from '@/application/rating-action-helpers';
import { requireAccessToken } from '@/application/require-access-token';
import { toSavedDrink, type ApiSavedDrink } from '@/application/saved-drink-mappers';
import { authServerFetch } from '@/application/server-api';

export type SavedDrinkActionState = { ok: true; data?: SavedDrink } | { ok: false; error: string };

function revalidateSavedDrinkPaths(slug: string) {
  if (isSafeSlug(slug)) {
    revalidatePath(`/drinks/${slug}`);
  }
  revalidatePath('/list');
  revalidatePath('/');
}

export async function saveDrink(
  drinkId: string,
  drinkSlug: string,
): Promise<SavedDrinkActionState> {
  if (!isSafeUUID(drinkId)) {
    return { ok: false, error: 'drink_id が見つかりません。' };
  }

  const auth = await requireAccessToken();
  if (!auth.ok) {
    return { ok: false, error: 'リストに残すにはログインが必要です。' };
  }

  const result = await authServerFetch<ApiSavedDrink>('/api/auth/saved-drinks', {
    method: 'POST',
    accessToken: auth.accessToken,
    body: { drink_id: drinkId },
  });
  if (!result.ok) {
    return { ok: false, error: result.error || 'リストへの追加に失敗しました。' };
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
