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
  pathname: string | null;
}

export function parseRatingFormData(
  formData: FormData,
  entityIdField: string,
  missingIdError: string,
): { ok: true; value: ParsedRatingForm } | { ok: false; error: string } {
  const entityId = formData.get(entityIdField) as string | null;
  const ratingRaw = formData.get('rating') as string | null;
  const comment = ((formData.get('comment') as string | null) ?? '').trim();
  const pathname = (formData.get('pathname') as string | null) ?? null;

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

  return { ok: true, value: { entityId, rating, comment, pathname } };
}

export function revalidateEntityPath(pathname: string | null, pathPrefix: string) {
  if (pathname && pathname.startsWith(pathPrefix)) {
    revalidatePath(pathname);
  }
}

export async function upsertEntityRating<TApi, TDto>(options: {
  formData: FormData;
  entityIdField: string;
  missingIdError: string;
  upsertPath: string;
  bodyKey: string;
  pathPrefix: string;
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

  revalidateEntityPath(parsed.value.pathname, options.pathPrefix);
  return { ok: true, error: '', data: options.mapResponse(result.data) };
}

export async function deleteEntityRating<T = never>(options: {
  ratingId: string;
  deletePath: string;
  pathname?: string;
  pathPrefix: string;
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

  revalidateEntityPath(options.pathname ?? null, options.pathPrefix);
  return { ok: true, error: '' };
}
