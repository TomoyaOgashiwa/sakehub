'use client';

import { useActionState, useOptimistic, useTransition, useState } from 'react';

import type { DrinkReview } from '@sakehub/types';

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
import { deleteReview, submitReview } from './actions';
import type { ReviewState } from './actions';

interface DrinkReviewWidgetProps {
  drinkId: string;
  initialReview: DrinkReview | null;
}

const initialState: ReviewState = { ok: false, error: '' };

export function DrinkReviewWidget({ drinkId, initialReview }: DrinkReviewWidgetProps) {
  const [open, setOpen] = useState(false);
  const [state, formAction, isPending] = useActionState(submitReview, initialState);
  const [, startTransition] = useTransition();

  const [optimisticReview, setOptimisticReview] = useOptimistic<DrinkReview | null>(initialReview);

  // Local draft state inside the modal (reset when modal opens)
  const [draftRating, setDraftRating] = useState<number | null>(null);
  const [draftComment, setDraftComment] = useState('');

  const handleOpen = (isOpen: boolean) => {
    if (isOpen) {
      setDraftRating(optimisticReview?.rating ?? null);
      setDraftComment(optimisticReview?.comment ?? '');
    }
    setOpen(isOpen);
  };

  const handleSubmit = () => {
    if (!draftRating) return;

    const rating = draftRating;
    const comment = draftComment.trim();

    const next: DrinkReview = {
      id: optimisticReview?.id ?? '',
      drinkId,
      userId: '',
      rating,
      comment,
      createdAt: optimisticReview?.createdAt ?? new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    startTransition(async () => {
      setOptimisticReview(next);
      setOpen(false);

      const fd = new FormData();
      fd.set('drink_id', drinkId);
      fd.set('rating', String(rating));
      fd.set('comment', comment);
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
  const hasReview = currentRating != null;

  return (
    <div className="space-y-3">
      <p className="text-sm font-medium">あなたの評価</p>

      {hasReview ? (
        <div className="flex flex-wrap items-center gap-3">
          <StarRatingDisplay value={currentRating} size="md" showValue={false} />
          <span className="text-foreground font-medium">{currentRating}つ星</span>
          {optimisticReview?.comment && (
            <p className="text-muted-foreground w-full text-sm">{optimisticReview.comment}</p>
          )}
          <Dialog open={open} onOpenChange={handleOpen}>
            <DialogTrigger render={<Button variant="outline" size="sm" disabled={isPending} />}>
              評価を編集する
            </DialogTrigger>
            <RatingDialogContent
              drinkId={drinkId}
              draftRating={draftRating}
              draftComment={draftComment}
              onRatingChange={setDraftRating}
              onCommentChange={setDraftComment}
              onSubmit={handleSubmit}
              isPending={isPending}
              error={!state.ok && state.error ? state.error : ''}
            />
          </Dialog>
          {!isPending && (
            <button
              type="button"
              onClick={handleDelete}
              className="text-muted-foreground hover:text-destructive text-xs underline transition-colors"
            >
              取り消す
            </button>
          )}
          {isPending && (
            <span className="text-muted-foreground animate-pulse text-xs">送信中…</span>
          )}
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          <Dialog open={open} onOpenChange={handleOpen}>
            <DialogTrigger render={<Button variant="outline" size="sm" disabled={isPending} />}>
              評価する
            </DialogTrigger>
            <RatingDialogContent
              drinkId={drinkId}
              draftRating={draftRating}
              draftComment={draftComment}
              onRatingChange={setDraftRating}
              onCommentChange={setDraftComment}
              onSubmit={handleSubmit}
              isPending={isPending}
              error={!state.ok && state.error ? state.error : ''}
            />
          </Dialog>
          <p className="text-muted-foreground text-xs">ボタンをタップして評価できます</p>
        </div>
      )}
    </div>
  );
}

interface RatingDialogContentProps {
  drinkId: string;
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
