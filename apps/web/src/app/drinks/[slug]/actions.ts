'use server';

import { revalidatePath } from 'next/cache';
import type { DrinkReview } from '@sakehub/types';

import { toDrinkReview, type ApiDrinkReview } from '@/application/drink-mappers';
import {
  deleteEntityRating,
  drinkRevalidatePath,
  upsertEntityRating,
  type RatingActionState,
} from '@/application/rating-action-helpers';

export type ReviewState = RatingActionState<DrinkReview>;

export async function submitReview(
  _prevState: ReviewState,
  formData: FormData,
): Promise<ReviewState> {
  const result = await upsertEntityRating<ApiDrinkReview, DrinkReview>({
    formData,
    entityIdField: 'drink_id',
    missingIdError: 'drink_id が見つかりません。',
    upsertPath: '/api/auth/reviews',
    bodyKey: 'drink_id',
    resolveRevalidatePath: (_drinkId, fd) => {
      const slug = ((fd.get('drink_slug') as string | null) ?? '').trim();
      return drinkRevalidatePath(slug);
    },
    mapResponse: toDrinkReview,
  });
  if (result.ok) {
    revalidatePath('/list');
    revalidatePath('/');
  }
  return result;
}

export async function deleteReview(reviewId: string, drinkSlug: string): Promise<ReviewState> {
  const result = await deleteEntityRating<DrinkReview>({
    ratingId: reviewId,
    deletePath: `/api/auth/reviews/${encodeURIComponent(reviewId)}`,
    pathToRevalidate: drinkRevalidatePath(drinkSlug),
  });
  if (result.ok) {
    revalidatePath('/list');
    revalidatePath('/');
  }
  return result;
}
