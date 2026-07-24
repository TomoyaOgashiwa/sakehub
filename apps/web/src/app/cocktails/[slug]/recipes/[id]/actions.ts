'use server';

import type { CocktailRecipeRating } from '@sakehub/types';

import { createClient } from '@/lib/supabase/server';

const API_URL = process.env.API_URL ?? 'http://localhost:8080';

export interface RecipeRatingState {
  ok: boolean;
  error: string;
  data?: CocktailRecipeRating;
}

export async function submitRecipeRating(
  _prevState: RecipeRatingState,
  formData: FormData,
): Promise<RecipeRatingState> {
  const recipeId = formData.get('recipe_id') as string | null;
  const ratingRaw = formData.get('rating') as string | null;
  const comment = ((formData.get('comment') as string | null) ?? '').trim();

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

  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { ok: false, error: '評価するにはログインが必要です。' };
  }

  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session) {
    return { ok: false, error: 'セッションが見つかりません。再ログインしてください。' };
  }

  let apiRes: Response;
  try {
    apiRes = await fetch(`${API_URL}/api/auth/cocktail-recipe-ratings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({ recipe_id: recipeId, rating, comment }),
    });
  } catch {
    return {
      ok: false,
      error: 'サーバーへの接続に失敗しました。しばらくしてから再試行してください。',
    };
  }

  if (!apiRes.ok) {
    const body = (await apiRes.json().catch(() => ({ error: '' }))) as { error?: string };
    return { ok: false, error: body.error || '評価の送信に失敗しました。' };
  }

  const data = (await apiRes.json()) as CocktailRecipeRating;
  return { ok: true, error: '', data };
}

export async function deleteRecipeRating(ratingId: string): Promise<RecipeRatingState> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { ok: false, error: '認証が必要です。' };
  }

  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session) {
    return { ok: false, error: 'セッションが見つかりません。' };
  }

  let apiRes: Response;
  try {
    apiRes = await fetch(
      `${API_URL}/api/auth/cocktail-recipe-ratings/${encodeURIComponent(ratingId)}`,
      {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${session.access_token}` },
      },
    );
  } catch {
    return { ok: false, error: 'サーバーへの接続に失敗しました。' };
  }

  if (!apiRes.ok && apiRes.status !== 204) {
    return { ok: false, error: '評価の削除に失敗しました。' };
  }

  return { ok: true, error: '' };
}
