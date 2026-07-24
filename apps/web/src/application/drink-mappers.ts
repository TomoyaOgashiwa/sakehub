import type { DrinkReview } from '@sakehub/types';

export interface ApiDrinkReview {
  id: string;
  drink_id: string;
  user_id: string;
  rating: number;
  comment: string;
  created_at: string;
  updated_at: string;
}

export function toDrinkReview(api: ApiDrinkReview): DrinkReview {
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
