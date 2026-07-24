'use server';

import { revalidatePath } from 'next/cache';

import type { DrinkReview } from '@sakehub/types';

import { requireAccessToken } from '@/application/require-access-token';
import { authServerFetch } from '@/application/server-api';

export interface ReviewState {
  ok: boolean;
  error: string;
  data?: DrinkReview;
}

interface ApiDrinkReview {
  id: string;
  drink_id: string;
  user_id: string;
  rating: number;
  comment: string;
  created_at: string;
  updated_at: string;
}

function toDrinkReview(api: ApiDrinkReview): DrinkReview {
  return {
    id: api.id,
    drinkId: api.drink_id,
    userId: api.user_id,
    rating: api.rating,
    comment: api.comment,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

function revalidateDrinkPath(pathname: string | null) {
  if (pathname && pathname.startsWith('/drinks/')) {
    revalidatePath(pathname);
  }
}

export async function submitReview(
  _prevState: ReviewState,
  formData: FormData,
): Promise<ReviewState> {
  const drinkId = formData.get('drink_id') as string | null;
  const ratingRaw = formData.get('rating') as string | null;
  const comment = ((formData.get('comment') as string | null) ?? '').trim();
  const pathname = (formData.get('pathname') as string | null) ?? null;

  if (!drinkId) {
    return { ok: false, error: 'drink_id が見つかりません。' };
  }

  const rating = Number(ratingRaw);
  if (!ratingRaw || !Number.isInteger(rating) || rating < 1 || rating > 5) {
    return { ok: false, error: '評価は1〜5の整数で選択してください。' };
  }

  if (comment.length > 1000) {
    return { ok: false, error: 'コメントは1000文字以内で入力してください。' };
  }

  const auth = await requireAccessToken();
  if (!auth.ok) {
    return { ok: false, error: auth.error };
  }

  const result = await authServerFetch<ApiDrinkReview>('/api/auth/reviews', {
    method: 'POST',
    accessToken: auth.accessToken,
    body: { drink_id: drinkId, rating, comment },
  });

  if (!result.ok) {
    return { ok: false, error: result.error || '評価の送信に失敗しました。' };
  }

  revalidateDrinkPath(pathname);
  return { ok: true, error: '', data: toDrinkReview(result.data) };
}

export async function deleteReview(reviewId: string, pathname?: string): Promise<ReviewState> {
  const auth = await requireAccessToken();
  if (!auth.ok) {
    return { ok: false, error: auth.error };
  }

  const result = await authServerFetch(`/api/auth/reviews/${encodeURIComponent(reviewId)}`, {
    method: 'DELETE',
    accessToken: auth.accessToken,
    emptyResponse: true,
  });

  if (!result.ok) {
    return { ok: false, error: result.error || '評価の削除に失敗しました。' };
  }

  revalidateDrinkPath(pathname ?? null);
  return { ok: true, error: '' };
}
