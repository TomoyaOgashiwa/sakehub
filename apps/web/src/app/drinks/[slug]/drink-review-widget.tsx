'use client';

import type { DrinkReview } from '@sakehub/types';

import { EntityRatingWidget } from '@/components/ratings/entity-rating-widget';

import { deleteReview, submitReview } from './actions';
import type { ReviewState } from './actions';

interface DrinkReviewWidgetProps {
  drinkId: string;
  drinkSlug: string;
  initialReview: DrinkReview | null;
}

const initialState: ReviewState = { ok: false, error: '' };

export function DrinkReviewWidget({ drinkId, drinkSlug, initialReview }: DrinkReviewWidgetProps) {
  const pathname = `/drinks/${drinkSlug}`;

  return (
    <EntityRatingWidget
      initialRating={initialReview}
      commentPlaceholder="この飲み物の感想を書いてください…"
      buildOptimistic={({ previous, rating, comment }) => ({
        id: previous?.id ?? '',
        drinkId,
        userId: previous?.userId ?? '',
        rating,
        comment,
        createdAt: previous?.createdAt ?? new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      })}
      onSubmit={async (rating, comment) => {
        const fd = new FormData();
        fd.set('drink_id', drinkId);
        fd.set('rating', String(rating));
        fd.set('comment', comment);
        fd.set('pathname', pathname);
        return submitReview(initialState, fd);
      }}
      onDelete={(id) => deleteReview(id, pathname)}
    />
  );
}
