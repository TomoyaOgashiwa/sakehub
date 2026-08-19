'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';

import { fetchMyCocktailRecipe } from '@/application/cocktails-api.server';
import { authServerFetch } from '@/application/server-api';
import { createClient } from '@/lib/supabase/server';

import { parsePublishedMetaFormData, parseRecipeFormData } from '../../recipe-form-data';
import type { RecipeFormState } from '../../recipe-form-state';

interface PatchedRecipe {
  id?: string;
  status?: string;
  cocktail_slug?: string;
}

const RECIPE_ID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function recipeIdFromForm(formData: FormData): string {
  return (formData.get('id') as string | null)?.trim() ?? '';
}

async function requireSession(): Promise<
  { ok: true; userId: string; accessToken: string } | { ok: false; error: string }
> {
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

  return { ok: true, userId: user.id, accessToken: session.access_token };
}

function mapPatchError(status: number, message: string): string {
  if (
    status === 400 &&
    (message.includes('published recipes cannot be updated') ||
      message.includes('published recipes can only update'))
  ) {
    return '公開済みのレシピの材料・作り方は変えられません。';
  }
  return message || 'レシピの更新に失敗しました。';
}

async function resolveImageUrl(
  userId: string,
  imageFile: File | null,
  imageCleared: boolean,
): Promise<string | null | undefined> {
  if (imageFile && imageFile.size > 0) {
    const supabase = await createClient();
    const ext = imageFile.name.split('.').pop() ?? 'jpg';
    const path = `${userId}/${crypto.randomUUID()}.${ext}`;

    const { error: uploadError } = await supabase.storage
      .from('cocktail-images')
      .upload(path, imageFile, { contentType: imageFile.type });

    if (!uploadError) {
      const {
        data: { publicUrl },
      } = supabase.storage.from('cocktail-images').getPublicUrl(path);
      return publicUrl;
    }
    return undefined;
  }
  if (imageCleared) {
    return null;
  }
  return undefined;
}

export async function updateCocktailRecipe(
  _prevState: RecipeFormState,
  formData: FormData,
): Promise<RecipeFormState> {
  const id = recipeIdFromForm(formData);
  if (!RECIPE_ID_RE.test(id)) {
    return { ok: false, error: 'レシピが見つかりません。' };
  }

  const parsed = parseRecipeFormData(formData);
  if (!parsed.ok) return parsed;

  const auth = await requireSession();
  if (!auth.ok) return auth;

  const { cocktailId, name, memo, status, ingredients, steps, imageFile, imageCleared } =
    parsed.data;

  const imageUrl = await resolveImageUrl(auth.userId, imageFile, imageCleared);

  const body: Record<string, unknown> = {
    cocktail_id: cocktailId,
    name,
    status,
    ingredients,
    steps,
    // Empty memo must be null. Omitting the key (Create's "no memo") cannot clear a tip.
    memo: memo === '' ? null : memo,
  };
  // Omit image_url when the photo was not changed. Create treats a missing key as
  // "no image"; the same on PATCH would wipe the stored photo.
  if (imageUrl !== undefined) {
    body.image_url = imageUrl;
  }

  const result = await authServerFetch<PatchedRecipe>(
    `/api/auth/cocktail-recipes/${encodeURIComponent(id)}`,
    {
      accessToken: auth.accessToken,
      method: 'PATCH',
      body,
    },
  );
  if (!result.ok) {
    return { ok: false, error: mapPatchError(result.status, result.error) };
  }

  const updatedId = result.data.id?.trim() || id;
  const slug = result.data.cocktail_slug?.trim() ?? '';
  const published = result.data.status === 'published' && slug !== '';

  revalidatePath('/my-cocktails');
  if (published) {
    revalidatePath(`/cocktails/${slug}`);
    revalidatePath(`/cocktails/${slug}/recipes/${updatedId}`);
    redirect(`/cocktails/${slug}/recipes/${updatedId}`);
  }
  redirect('/my-cocktails');
}

export async function updatePublishedCocktailRecipe(
  _prevState: RecipeFormState,
  formData: FormData,
): Promise<RecipeFormState> {
  const id = recipeIdFromForm(formData);
  if (!RECIPE_ID_RE.test(id)) {
    return { ok: false, error: 'レシピが見つかりません。' };
  }

  const parsed = parsePublishedMetaFormData(formData);
  if (!parsed.ok) return parsed;

  const auth = await requireSession();
  if (!auth.ok) return auth;

  // Do not trust the form for current status. A meta-only PATCH against a
  // draft would full-replace ingredients/steps to empty.
  const owned = await fetchMyCocktailRecipe(auth.accessToken, id);
  if (!owned.ok) {
    if (owned.status === 401) {
      return { ok: false, error: '認証が必要です。ログインしてください。' };
    }
    if (owned.status === 404) {
      return { ok: false, error: 'レシピが見つかりません。' };
    }
    return { ok: false, error: owned.error || 'レシピの取得に失敗しました。' };
  }
  if (owned.recipe.status !== 'published') {
    return { ok: false, error: '公開済みのレシピだけ、この画面から保存できます。' };
  }

  const { name, memo, imageFile, imageCleared } = parsed.data;
  const imageUrl = await resolveImageUrl(auth.userId, imageFile, imageCleared);

  const body: Record<string, unknown> = {
    name,
    // Empty memo must be null. Omitting the key cannot clear a tip.
    memo: memo === '' ? null : memo,
  };
  if (imageUrl !== undefined) {
    body.image_url = imageUrl;
  }

  const result = await authServerFetch<PatchedRecipe>(
    `/api/auth/cocktail-recipes/${encodeURIComponent(id)}`,
    {
      accessToken: auth.accessToken,
      method: 'PATCH',
      body,
    },
  );
  if (!result.ok) {
    return { ok: false, error: mapPatchError(result.status, result.error) };
  }

  const updatedId = result.data.id?.trim() || id;
  const slug = result.data.cocktail_slug?.trim() ?? '';

  revalidatePath('/my-cocktails');
  if (slug) {
    revalidatePath(`/cocktails/${slug}`);
    revalidatePath(`/cocktails/${slug}/recipes/${updatedId}`);
    redirect(`/cocktails/${slug}/recipes/${updatedId}`);
  }
  redirect('/my-cocktails');
}

export async function deleteDraftCocktailRecipe(
  _prevState: RecipeFormState,
  formData: FormData,
): Promise<RecipeFormState> {
  const id = recipeIdFromForm(formData);
  if (!RECIPE_ID_RE.test(id)) {
    return { ok: false, error: 'レシピが見つかりません。' };
  }

  const auth = await requireSession();
  if (!auth.ok) return auth;

  const result = await authServerFetch(`/api/auth/cocktail-recipes/${encodeURIComponent(id)}`, {
    accessToken: auth.accessToken,
    method: 'DELETE',
    emptyResponse: true,
  });
  if (!result.ok) {
    if (result.status === 400) {
      return { ok: false, error: '公開済みのレシピは削除できません。' };
    }
    if (result.status === 404) {
      return { ok: false, error: '下書きが見つかりません。' };
    }
    return { ok: false, error: result.error || '下書きの削除に失敗しました。' };
  }

  revalidatePath('/my-cocktails');
  redirect('/my-cocktails');
}
