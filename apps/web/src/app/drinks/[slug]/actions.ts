'use server';

import type { DrinkReview } from '@sakehub/types';

import {
  deleteEntityRating,
  upsertEntityRating,
  type RatingActionState,
} from '@/application/rating-action-helpers';

export type ReviewState = RatingActionState<DrinkReview>;

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

export async function submitReview(
  _prevState: ReviewState,
  formData: FormData,
): Promise<ReviewState> {
  return upsertEntityRating<ApiDrinkReview, DrinkReview>({
    formData,
    entityIdField: 'drink_id',
    missingIdError: 'drink_id が見つかりません。',
    upsertPath: '/api/auth/reviews',
    bodyKey: 'drink_id',
    pathPrefix: '/drinks/',
    mapResponse: toDrinkReview,
  });
}

export async function deleteReview(reviewId: string, pathname?: string): Promise<ReviewState> {
  return deleteEntityRating<DrinkReview>({
    ratingId: reviewId,
    deletePath: `/api/auth/reviews/${encodeURIComponent(reviewId)}`,
    pathname,
    pathPrefix: '/drinks/',
  });
}
