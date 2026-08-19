import type { CocktailRecipeStatus } from '@sakehub/types';

export interface ParsedRecipeFormFields {
  cocktailId: string;
  name: string;
  memo: string;
  status: CocktailRecipeStatus;
  ingredients: unknown[];
  steps: unknown[];
  imageFile: File | null;
  imageCleared: boolean;
}

export function parseRecipeFormData(
  formData: FormData,
): { ok: true; data: ParsedRecipeFormFields } | { ok: false; error: string } {
  const cocktailId = (formData.get('cocktail_id') as string | null)?.trim() ?? '';
  const name = (formData.get('name') as string | null)?.trim() ?? '';
  const memo = (formData.get('memo') as string | null)?.trim() ?? '';
  const status = (formData.get('status') as string | null) ?? 'draft';
  const ingredientsJson = (formData.get('ingredients') as string | null) ?? '[]';
  const stepsJson = (formData.get('steps') as string | null) ?? '[]';
  const imageFile = formData.get('image') as File | null;
  const imageCleared = (formData.get('image_cleared') as string | null) === '1';

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
    const parsed: unknown = JSON.parse(ingredientsJson);
    if (!Array.isArray(parsed)) throw new Error('not array');
    ingredients = parsed;
  } catch {
    return { ok: false, error: '材料データが不正です。' };
  }

  let steps: unknown[];
  try {
    const parsed: unknown = JSON.parse(stepsJson);
    if (!Array.isArray(parsed)) throw new Error('not array');
    steps = parsed;
  } catch {
    return { ok: false, error: '手順データが不正です。' };
  }

  if (status === 'published') {
    if (ingredients.length === 0) {
      return { ok: false, error: '材料を1つ以上追加してください。' };
    }
    if (steps.length === 0) {
      return { ok: false, error: '作り方を1つ以上追加してください。' };
    }
  }

  return {
    ok: true,
    data: {
      cocktailId,
      name,
      memo,
      status,
      ingredients,
      steps,
      imageFile,
      imageCleared,
    },
  };
}
