'use server';

import { redirect } from 'next/navigation';

import { createClient } from '@/lib/supabase/server';

export interface RecipeFormState {
  ok: boolean;
  error: string;
}

const API_URL = process.env.API_URL ?? 'http://localhost:8080';

export async function createCocktailRecipe(
  _prevState: RecipeFormState,
  formData: FormData,
): Promise<RecipeFormState> {
  const name = (formData.get('name') as string | null)?.trim() ?? '';
  const memo = (formData.get('memo') as string | null)?.trim() || undefined;
  const status = (formData.get('status') as string | null) ?? 'draft';
  const ingredientsJson = (formData.get('ingredients') as string | null) ?? '[]';
  const imageFile = formData.get('image') as File | null;

  if (!name) {
    return { ok: false, error: 'カクテル名は必須です。' };
  }
  if ([...name].length > 100) {
    return { ok: false, error: 'カクテル名は100文字以内で入力してください。' };
  }
  if (memo && [...memo].length > 1000) {
    return { ok: false, error: 'メモは1000文字以内で入力してください。' };
  }
  if (status !== 'draft' && status !== 'published') {
    return { ok: false, error: '不正なステータスです。' };
  }

  let ingredients: unknown[];
  try {
    const parsed = JSON.parse(ingredientsJson);
    if (!Array.isArray(parsed)) throw new Error('not array');
    ingredients = parsed;
  } catch {
    return { ok: false, error: '材料データが不正です。' };
  }

  if (ingredients.length === 0) {
    return { ok: false, error: '材料を1つ以上追加してください。' };
  }

  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { ok: false, error: '認証が必要です。ログインしてください。' };
  }

  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session) {
    return { ok: false, error: 'セッションが見つかりません。再ログインしてください。' };
  }

  let imageUrl: string | undefined;
  if (imageFile && imageFile.size > 0) {
    const ext = imageFile.name.split('.').pop() ?? 'jpg';
    const path = `${user.id}/${crypto.randomUUID()}.${ext}`;

    const { error: uploadError } = await supabase.storage
      .from('cocktail-images')
      .upload(path, imageFile, { contentType: imageFile.type });

    if (!uploadError) {
      const {
        data: { publicUrl },
      } = supabase.storage.from('cocktail-images').getPublicUrl(path);
      imageUrl = publicUrl;
    }
  }

  let apiRes: Response;
  try {
    apiRes = await fetch(`${API_URL}/api/cocktail-recipes`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({
        name,
        memo,
        image_url: imageUrl,
        status,
        ingredients,
      }),
    });
  } catch {
    return {
      ok: false,
      error: 'サーバーへの接続に失敗しました。しばらくしてから再試行してください。',
    };
  }

  if (!apiRes.ok) {
    const body = (await apiRes.json().catch(() => ({ message: '' }))) as { message?: string };
    return {
      ok: false,
      error: body.message || 'レシピの登録に失敗しました。',
    };
  }

  redirect('/');
}
