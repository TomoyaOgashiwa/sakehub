'use server';

import { revalidatePath } from 'next/cache';
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
  const cocktailId = (formData.get('cocktail_id') as string | null)?.trim() ?? '';
  const name = (formData.get('name') as string | null)?.trim() ?? '';
  const memo = (formData.get('memo') as string | null)?.trim() || undefined;
  const status = (formData.get('status') as string | null) ?? 'draft';
  const ingredientsJson = (formData.get('ingredients') as string | null) ?? '[]';
  const stepsJson = (formData.get('steps') as string | null) ?? '[]';
  const imageFile = formData.get('image') as File | null;

  if (!cocktailId) {
    return { ok: false, error: 'カクテルの種類を選択してください。' };
  }
  if (!name) {
    return { ok: false, error: 'カクテル名は必須です。' };
  }
  if ([...name].length > 100) {
    return { ok: false, error: 'カクテル名は100文字以内で入力してください。' };
  }
  if (memo && [...memo].length > 1000) {
    return { ok: false, error: 'コツ・ポイントは1000文字以内で入力してください。' };
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

  let steps: unknown[];
  try {
    const parsed = JSON.parse(stepsJson);
    if (!Array.isArray(parsed)) throw new Error('not array');
    steps = parsed;
  } catch {
    return { ok: false, error: '手順データが不正です。' };
  }

  // published requires ≥1 ingredient and ≥1 step; draft may be empty.
  if (status === 'published') {
    if (ingredients.length === 0) {
      return { ok: false, error: '材料を1つ以上追加してください。' };
    }
    if (steps.length === 0) {
      return { ok: false, error: '作り方を1つ以上追加してください。' };
    }
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
        cocktail_id: cocktailId,
        name,
        memo,
        image_url: imageUrl,
        status,
        ingredients,
        steps,
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

  let created: { id?: string; status?: string; cocktail_slug?: string } = {};
  try {
    created = (await apiRes.json()) as typeof created;
  } catch {
    created = {};
  }

  const id = created.id?.trim() ?? '';
  const slug = created.cocktail_slug?.trim() ?? '';
  const published = created.status === 'published' && id !== '' && slug !== '';

  revalidatePath('/my-cocktails');
  if (published) {
    revalidatePath(`/cocktails/${slug}`);
    revalidatePath(`/cocktails/${slug}/recipes/${id}`);
    redirect(`/cocktails/${slug}/recipes/${id}`);
  }
  redirect('/my-cocktails');
}
