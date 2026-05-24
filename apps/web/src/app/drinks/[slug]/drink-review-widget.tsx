'use client';

import { useActionState, useOptimistic, useTransition } from 'react';

import type { DrinkReview } from '@sakehub/types';

import { StarRatingInput } from '@/components/ui/star-rating';
import { deleteReview, submitReview } from './actions';
import type { ReviewState } from './actions';

interface DrinkReviewWidgetProps {
  drinkId: string;
  initialReview: DrinkReview | null;
}

const initialState: ReviewState = { ok: false, error: '' };

export function DrinkReviewWidget({ drinkId, initialReview }: DrinkReviewWidgetProps) {
  const [, formAction, isPending] = useActionState(submitReview, initialState);
  const [, startTransition] = useTransition();

  const [optimisticReview, setOptimisticReview] = useOptimistic<DrinkReview | null>(initialReview);

  const handleRatingChange = (rating: number) => {
    const next: DrinkReview = {
      id: optimisticReview?.id ?? '',
      drinkId,
      userId: '',
      rating,
      comment: optimisticReview?.comment ?? '',
      createdAt: optimisticReview?.createdAt ?? new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    startTransition(async () => {
      setOptimisticReview(next);

      const fd = new FormData();
      fd.set('drink_id', drinkId);
      fd.set('rating', String(rating));
      fd.set('comment', optimisticReview?.comment ?? '');
      await formAction(fd);
    });
  };

  const handleDelete = () => {
    if (!optimisticReview?.id) return;
    const id = optimisticReview.id;
    startTransition(async () => {
      setOptimisticReview(null);
      await deleteReview(id);
    });
  };

  const currentRating = optimisticReview?.rating ?? null;

  return (
    <div className="space-y-3">
      <div className="flex flex-col gap-2">
        <p className="text-sm font-medium">あなたの評価</p>
        <div className="flex items-center gap-3">
          <StarRatingInput
            value={currentRating}
            onChange={handleRatingChange}
            disabled={isPending}
            size="lg"
          />
          {currentRating != null && (
            <span className="text-muted-foreground text-sm">
              {currentRating}つ星
              {!isPending && (
                <button
                  type="button"
                  onClick={handleDelete}
                  className="text-muted-foreground hover:text-destructive ml-2 text-xs underline transition-colors"
                >
                  取り消す
                </button>
              )}
            </span>
          )}
          {isPending && (
            <span className="text-muted-foreground animate-pulse text-xs">送信中…</span>
          )}
        </div>
      </div>

      {!currentRating && (
        <p className="text-muted-foreground text-xs">星をタップして評価できます</p>
      )}
    </div>
  );
}
