import 'server-only';

import type { DrinkReview } from '@sakehub/types';

const API_URL = process.env.API_URL ?? 'http://localhost:8080';

interface ApiReviewListResponse {
  data: ApiReview[] | null;
}

interface ApiReview {
  id: string;
  drink_id: string;
  user_id: string;
  rating: number;
  comment: string;
  created_at: string;
  updated_at: string;
}

function toReview(api: ApiReview): DrinkReview {
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

/** Fetch all reviews for a drink (public, no auth required). */
export async function fetchReviewsByDrinkId(drinkId: string): Promise<DrinkReview[]> {
  try {
    const url = new URL(`${API_URL}/api/public/reviews`);
    url.searchParams.set('drink_id', drinkId);

    const res = await fetch(url.toString(), {
      headers: { 'Content-Type': 'application/json' },
      next: { revalidate: 0 },
    });
    if (!res.ok) return [];

    const body = (await res.json()) as ApiReviewListResponse;
    return (body.data ?? []).map(toReview);
  } catch {
    return [];
  }
}

/** Fetch the authenticated user's review for a drink. Returns null if none. */
export async function fetchMyReview(
  drinkId: string,
  accessToken: string,
): Promise<DrinkReview | null> {
  try {
    const url = new URL(`${API_URL}/api/auth/reviews/mine`);
    url.searchParams.set('drink_id', drinkId);

    const res = await fetch(url.toString(), {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      next: { revalidate: 0 },
    });
    if (!res.ok) return null;

    const body = (await res.json()) as { data: ApiReview | null };
    return body.data ? toReview(body.data) : null;
  } catch {
    return null;
  }
}
