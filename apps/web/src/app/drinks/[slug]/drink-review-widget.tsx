'use client';

import { useOptimistic, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import type { DrinkReview } from '@sakehub/types';

import { saveDrink, unsaveDrink } from '@/application/saved-drink-actions';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { StarRatingDisplay, StarRatingInput } from '@/components/ui/star-rating';
import { Textarea } from '@/components/ui/textarea';

import { deleteReview, submitReview, type ReviewState } from './actions';

interface DrinkReviewWidgetProps {
  drinkId: string;
  drinkSlug: string;
  initialSaved: boolean;
  initialReview: DrinkReview | null;
}

const initialReviewState: ReviewState = { ok: false, error: '' };

export function DrinkReviewWidget({
  drinkId,
  drinkSlug,
  initialSaved,
  initialReview,
}: DrinkReviewWidgetProps) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState('');

  const [confirmedSaved, setConfirmedSaved] = useState(initialSaved);
  const [optimisticSaved, setOptimisticSaved] = useOptimistic(confirmedSaved);

  const [confirmedReview, setConfirmedReview] = useState<DrinkReview | null>(initialReview);
  const [optimisticReview, setOptimisticReview] = useOptimistic(confirmedReview);

  const [draftRating, setDraftRating] = useState<number | null>(null);
  const [draftComment, setDraftComment] = useState('');

  const handleOpen = (isOpen: boolean) => {
    if (isOpen) {
      setDraftRating(optimisticReview?.rating ?? null);
      setDraftComment(optimisticReview?.comment ?? '');
      setError('');
    }
    setOpen(isOpen);
  };

  const handleSave = () => {
    startTransition(async () => {
      setOptimisticSaved(true);
      setError('');
      const result = await saveDrink(drinkId, drinkSlug);
      if (result.ok) {
        setConfirmedSaved(true);
        router.refresh();
        return;
      }
      setError(result.error);
    });
  };

  const handleUnsave = () => {
    startTransition(async () => {
      setOptimisticSaved(false);
      setOptimisticReview(null);
      setError('');
      const result = await unsaveDrink(drinkId, drinkSlug);
      if (result.ok) {
        setConfirmedSaved(false);
        setConfirmedReview(null);
        router.refresh();
        return;
      }
      setError(result.error);
    });
  };

  const handleSubmitRating = () => {
    if (!draftRating) return;
    const rating = draftRating;
    const comment = draftComment.trim();
    const next: DrinkReview = {
      id: optimisticReview?.id ?? '',
      drinkId,
      userId: optimisticReview?.userId ?? '',
      rating,
      comment,
      createdAt: optimisticReview?.createdAt ?? new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    startTransition(async () => {
      setOptimisticReview(next);
      setOptimisticSaved(true);
      setOpen(false);
      setError('');

      const fd = new FormData();
      fd.set('drink_id', drinkId);
      fd.set('drink_slug', drinkSlug);
      fd.set('rating', String(rating));
      fd.set('comment', comment);
      const result = await submitReview(initialReviewState, fd);
      if (result.ok && result.data) {
        setConfirmedReview(result.data);
        setConfirmedSaved(true);
        router.refresh();
        return;
      }
      setError(result.error);
    });
  };

  const handleClearRating = () => {
    if (!optimisticReview?.id) return;
    const id = optimisticReview.id;
    startTransition(async () => {
      setOptimisticReview(null);
      setError('');
      const result = await deleteReview(id, drinkSlug);
      if (result.ok) {
        setConfirmedReview(null);
        router.refresh();
        return;
      }
      setError(result.error);
    });
  };

  const ratingDialog = (
    <RatingDialogContent
      draftRating={draftRating}
      draftComment={draftComment}
      onRatingChange={setDraftRating}
      onCommentChange={setDraftComment}
      onSubmit={handleSubmitRating}
      isPending={isPending}
      error={error}
    />
  );

  return (
    <div className="space-y-3">
      {optimisticSaved ? (
        <div className="space-y-3">
          <p className="text-sm font-medium">リストに追加済み</p>
          {optimisticReview ? (
            <div className="flex flex-wrap items-center gap-3">
              <StarRatingDisplay value={optimisticReview.rating} size="md" showValue={false} />
              <span className="text-foreground font-medium">{optimisticReview.rating}つ星</span>
              {optimisticReview.comment && (
                <p className="text-muted-foreground w-full text-sm">{optimisticReview.comment}</p>
              )}
              <Dialog open={open} onOpenChange={handleOpen}>
                <DialogTrigger render={<Button variant="outline" size="sm" disabled={isPending} />}>
                  評価を編集
                </DialogTrigger>
                {ratingDialog}
              </Dialog>
              {!isPending && optimisticReview.id && (
                <button
                  type="button"
                  onClick={handleClearRating}
                  className="text-muted-foreground hover:text-destructive text-xs underline transition-colors"
                >
                  評価を消す
                </button>
              )}
              <button
                type="button"
                onClick={handleUnsave}
                disabled={isPending}
                className="text-muted-foreground hover:text-destructive text-xs underline transition-colors"
              >
                リストから外す
              </button>
            </div>
          ) : (
            <div className="flex flex-wrap items-center gap-3">
              <Dialog open={open} onOpenChange={handleOpen}>
                <DialogTrigger render={<Button variant="outline" size="sm" disabled={isPending} />}>
                  評価する
                </DialogTrigger>
                {ratingDialog}
              </Dialog>
              <button
                type="button"
                onClick={handleUnsave}
                disabled={isPending}
                className="text-muted-foreground hover:text-destructive text-xs underline transition-colors"
              >
                リストから外す
              </button>
            </div>
          )}
        </div>
      ) : (
        <div className="flex flex-wrap items-center gap-3">
          <Button type="button" size="sm" disabled={isPending} onClick={handleSave}>
            リストに残す
          </Button>
          <Dialog open={open} onOpenChange={handleOpen}>
            <DialogTrigger render={<Button variant="secondary" size="sm" disabled={isPending} />}>
              評価する
            </DialogTrigger>
            {ratingDialog}
          </Dialog>
        </div>
      )}

      {isPending && <span className="text-muted-foreground animate-pulse text-xs">送信中…</span>}
      {!open && error && <p className="text-destructive text-sm">{error}</p>}
    </div>
  );
}

interface RatingDialogContentProps {
  draftRating: number | null;
  draftComment: string;
  onRatingChange: (rating: number) => void;
  onCommentChange: (comment: string) => void;
  onSubmit: () => void;
  isPending: boolean;
  error: string;
}

function RatingDialogContent({
  draftRating,
  draftComment,
  onRatingChange,
  onCommentChange,
  onSubmit,
  isPending,
  error,
}: RatingDialogContentProps) {
  return (
    <DialogContent className="sm:max-w-md">
      <DialogHeader>
        <DialogTitle>評価を入力</DialogTitle>
      </DialogHeader>

      <div className="space-y-4 py-2">
        <div className="space-y-2">
          <Label>星評価 (必須)</Label>
          <StarRatingInput
            value={draftRating}
            onChange={onRatingChange}
            size="lg"
            disabled={isPending}
          />
          {draftRating != null && (
            <p className="text-muted-foreground text-xs">{draftRating}つ星</p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="rating-comment">コメント (任意)</Label>
          <Textarea
            id="rating-comment"
            placeholder="この飲み物の感想を書いてください…"
            value={draftComment}
            onChange={(e) => onCommentChange(e.target.value)}
            maxLength={1000}
            disabled={isPending}
            className="resize-none"
            rows={3}
          />
          <p className="text-muted-foreground text-right text-xs">{draftComment.length} / 1000</p>
        </div>

        {error && <p className="text-destructive text-sm">{error}</p>}
      </div>

      <DialogFooter>
        <Button onClick={onSubmit} disabled={!draftRating || isPending}>
          {isPending ? '送信中…' : '評価を送信'}
        </Button>
      </DialogFooter>
    </DialogContent>
  );
}
