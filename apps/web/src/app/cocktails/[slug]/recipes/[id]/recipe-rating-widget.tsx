'use client';

import { useOptimistic, useState, useTransition } from 'react';

import type { CocktailRecipeRating } from '@sakehub/types';

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
import { deleteRecipeRating, submitRecipeRating } from './actions';
import type { RecipeRatingState } from './actions';

interface RecipeRatingWidgetProps {
  recipeId: string;
  cocktailSlug: string;
  initialRating: CocktailRecipeRating | null;
}

const emptyState: RecipeRatingState = { ok: false, error: '' };

export function RecipeRatingWidget({
  recipeId,
  cocktailSlug,
  initialRating,
}: RecipeRatingWidgetProps) {
  const pathname = `/cocktails/${cocktailSlug}/recipes/${recipeId}`;
  const [open, setOpen] = useState(false);
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState('');

  // Confirmed server-aligned state. useOptimistic alone would snap back when the
  // transition ends unless we keep a local confirmed value to feed it.
  const [confirmedRating, setConfirmedRating] = useState<CocktailRecipeRating | null>(initialRating);
  const [optimisticRating, setOptimisticRating] =
    useOptimistic<CocktailRecipeRating | null>(confirmedRating);

  const [draftRating, setDraftRating] = useState<number | null>(null);
  const [draftComment, setDraftComment] = useState('');

  const handleOpen = (isOpen: boolean) => {
    if (isOpen) {
      setDraftRating(optimisticRating?.rating ?? null);
      setDraftComment(optimisticRating?.comment ?? '');
      setError('');
    }
    setOpen(isOpen);
  };

  const handleSubmit = () => {
    if (!draftRating) return;

    const rating = draftRating;
    const comment = draftComment.trim();

    const next: CocktailRecipeRating = {
      id: optimisticRating?.id ?? '',
      recipeId,
      userId: optimisticRating?.userId ?? '',
      rating,
      comment,
      createdAt: optimisticRating?.createdAt ?? new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    startTransition(async () => {
      setOptimisticRating(next);
      setOpen(false);
      setError('');

      const fd = new FormData();
      fd.set('recipe_id', recipeId);
      fd.set('rating', String(rating));
      fd.set('comment', comment);
      fd.set('pathname', pathname);

      const result = await submitRecipeRating(emptyState, fd);
      if (result.ok && result.data) {
        setConfirmedRating(result.data);
        return;
      }
      setError(result.error);
    });
  };

  const handleDelete = () => {
    if (!optimisticRating?.id) return;
    const id = optimisticRating.id;
    startTransition(async () => {
      setOptimisticRating(null);
      setError('');
      const result = await deleteRecipeRating(id, pathname);
      if (result.ok) {
        setConfirmedRating(null);
        return;
      }
      setError(result.error);
    });
  };

  const currentRating = optimisticRating?.rating ?? null;
  const hasRating = currentRating != null;

  return (
    <div className="space-y-3">
      <p className="text-sm font-medium">あなたの評価</p>

      {hasRating ? (
        <div className="flex flex-wrap items-center gap-3">
          <StarRatingDisplay value={currentRating} size="md" showValue={false} />
          <span className="text-foreground font-medium">{currentRating}つ星</span>
          {optimisticRating?.comment && (
            <p className="text-muted-foreground w-full text-sm">{optimisticRating.comment}</p>
          )}
          <Dialog open={open} onOpenChange={handleOpen}>
            <DialogTrigger render={<Button variant="outline" size="sm" disabled={isPending} />}>
              評価を編集する
            </DialogTrigger>
            <RatingDialogContent
              draftRating={draftRating}
              draftComment={draftComment}
              onRatingChange={setDraftRating}
              onCommentChange={setDraftComment}
              onSubmit={handleSubmit}
              isPending={isPending}
              error={error}
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
          {!open && error && <p className="text-destructive w-full text-sm">{error}</p>}
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          <Dialog open={open} onOpenChange={handleOpen}>
            <DialogTrigger render={<Button variant="outline" size="sm" disabled={isPending} />}>
              評価する
            </DialogTrigger>
            <RatingDialogContent
              draftRating={draftRating}
              draftComment={draftComment}
              onRatingChange={setDraftRating}
              onCommentChange={setDraftComment}
              onSubmit={handleSubmit}
              isPending={isPending}
              error={error}
            />
          </Dialog>
          <p className="text-muted-foreground text-xs">ボタンをタップして評価できます</p>
          {!open && error && <p className="text-destructive text-sm">{error}</p>}
        </div>
      )}
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
            placeholder="このレシピの感想を書いてください…"
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
