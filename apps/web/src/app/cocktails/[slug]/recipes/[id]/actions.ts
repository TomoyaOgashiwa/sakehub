'use server';

import { revalidatePath } from 'next/cache';

import type { CocktailRecipeRating } from '@sakehub/types';

import { toRecipeRating, type ApiRecipeRating } from '@/application/cocktail-mappers';
import { requireAccessToken } from '@/application/require-access-token';
import { authServerFetch } from '@/application/server-api';

export interface RecipeRatingState {
  ok: boolean;
  error: string;
  data?: CocktailRecipeRating;
}

function revalidateRecipePath(pathname: string | null) {
  if (pathname && pathname.startsWith('/cocktails/')) {
    revalidatePath(pathname);
  }
}

export async function submitRecipeRating(
  _prevState: RecipeRatingState,
  formData: FormData,
): Promise<RecipeRatingState> {
  const recipeId = formData.get('recipe_id') as string | null;
  const ratingRaw = formData.get('rating') as string | null;
  const comment = ((formData.get('comment') as string | null) ?? '').trim();
  const pathname = (formData.get('pathname') as string | null) ?? null;

  if (!recipeId) {
    return { ok: false, error: 'recipe_id が見つかりません。' };
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

  const result = await authServerFetch<ApiRecipeRating>('/api/auth/cocktail-recipe-ratings', {
    method: 'POST',
    accessToken: auth.accessToken,
    body: { recipe_id: recipeId, rating, comment },
  });

  if (!result.ok) {
    return { ok: false, error: result.error || '評価の送信に失敗しました。' };
  }

  revalidateRecipePath(pathname);
  return { ok: true, error: '', data: toRecipeRating(result.data) };
}

export async function deleteRecipeRating(
  ratingId: string,
  pathname?: string,
): Promise<RecipeRatingState> {
  const auth = await requireAccessToken();
  if (!auth.ok) {
    return { ok: false, error: auth.error };
  }

  const result = await authServerFetch(
    `/api/auth/cocktail-recipe-ratings/${encodeURIComponent(ratingId)}`,
    {
      method: 'DELETE',
      accessToken: auth.accessToken,
      emptyResponse: true,
    },
  );

  if (!result.ok) {
    return { ok: false, error: result.error || '評価の削除に失敗しました。' };
  }

  revalidateRecipePath(pathname ?? null);
  return { ok: true, error: '' };
}
