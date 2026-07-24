import 'server-only';

import { revalidatePath } from 'next/cache';

import { requireAccessToken } from '@/application/require-access-token';
import { authServerFetch } from '@/application/server-api';

export interface RatingActionState<T> {
  ok: boolean;
  error: string;
  data?: T;
}

export interface ParsedRatingForm {
  entityId: string;
  rating: number;
  comment: string;
}

const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/i;
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function isSafeSlug(slug: string): boolean {
  return SLUG_PATTERN.test(slug) && slug.length <= 100;
}

export function isSafeUUID(id: string): boolean {
  return UUID_PATTERN.test(id);
}

/** Build a drink detail path only when the slug is a safe path segment. */
export function drinkRevalidatePath(slug: string): string | null {
  if (!isSafeSlug(slug)) return null;
  return `/drinks/${slug}`;
}

/** Build a cocktail recipe path only when slug/id are safe path segments. */
export function cocktailRecipeRevalidatePath(slug: string, recipeId: string): string | null {
  if (!isSafeSlug(slug) || !isSafeUUID(recipeId)) return null;
  return `/cocktails/${slug}/recipes/${recipeId}`;
}

export function parseRatingFormData(
  formData: FormData,
  entityIdField: string,
  missingIdError: string,
): { ok: true; value: ParsedRatingForm } | { ok: false; error: string } {
  const entityId = formData.get(entityIdField) as string | null;
  const ratingRaw = formData.get('rating') as string | null;
  const comment = ((formData.get('comment') as string | null) ?? '').trim();

  if (!entityId) {
    return { ok: false, error: missingIdError };
  }

  const rating = Number(ratingRaw);
  if (!ratingRaw || !Number.isInteger(rating) || rating < 1 || rating > 5) {
    return { ok: false, error: '評価は1〜5の整数で選択してください。' };
  }

  if (comment.length > 1000) {
    return { ok: false, error: 'コメントは1000文字以内で入力してください。' };
  }

  return { ok: true, value: { entityId, rating, comment } };
}

export async function upsertEntityRating<TApi, TDto>(options: {
  formData: FormData;
  entityIdField: string;
  missingIdError: string;
  upsertPath: string;
  bodyKey: string;
  /** Derive a safe cache path from trusted fields; never trust a raw pathname. */
  resolveRevalidatePath: (entityId: string, formData: FormData) => string | null;
  mapResponse: (raw: TApi) => TDto;
}): Promise<RatingActionState<TDto>> {
  const parsed = parseRatingFormData(
    options.formData,
    options.entityIdField,
    options.missingIdError,
  );
  if (!parsed.ok) {
    return { ok: false, error: parsed.error };
  }

  const auth = await requireAccessToken();
  if (!auth.ok) {
    return { ok: false, error: auth.error };
  }

  const result = await authServerFetch<TApi>(options.upsertPath, {
    method: 'POST',
    accessToken: auth.accessToken,
    body: {
      [options.bodyKey]: parsed.value.entityId,
      rating: parsed.value.rating,
      comment: parsed.value.comment,
    },
  });

  if (!result.ok) {
    return { ok: false, error: result.error || '評価の送信に失敗しました。' };
  }

  const path = options.resolveRevalidatePath(parsed.value.entityId, options.formData);
  if (path) {
    revalidatePath(path);
  }

  return { ok: true, error: '', data: options.mapResponse(result.data) };
}

export async function deleteEntityRating<T = never>(options: {
  ratingId: string;
  deletePath: string;
  /** Safe cache path built server-side from validated slug/id segments. */
  pathToRevalidate?: string | null;
}): Promise<RatingActionState<T>> {
  const auth = await requireAccessToken();
  if (!auth.ok) {
    return { ok: false, error: auth.error };
  }

  const result = await authServerFetch(options.deletePath, {
    method: 'DELETE',
    accessToken: auth.accessToken,
    emptyResponse: true,
  });

  if (!result.ok) {
    return { ok: false, error: result.error || '評価の削除に失敗しました。' };
  }

  if (options.pathToRevalidate) {
    revalidatePath(options.pathToRevalidate);
  }

  return { ok: true, error: '' };
}
