'use client';

import { useOptimistic, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import type { DrinkReview, SavedDrinkStatus } from '@sakehub/types';

import { saveDrink, unsaveDrink, updateSavedDrink } from '@/application/saved-drink-actions';
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
import { oppositeSavedDrinkStatus, savedDrinkStatusLabel } from '@/utils/saved-drink-status';

import { deleteReview, submitReview, type ReviewState } from './actions';

interface DrinkReviewWidgetProps {
  drinkId: string;
  drinkSlug: string;
  initialSaved: boolean;
  initialStatus: SavedDrinkStatus | null;
  initialNote: string;
  initialReview: DrinkReview | null;
}

const initialReviewState: ReviewState = { ok: false, error: '' };
const MAX_NOTE_LEN = 280;

export function DrinkReviewWidget({
  drinkId,
  drinkSlug,
  initialSaved,
  initialStatus,
  initialNote,
  initialReview,
}: DrinkReviewWidgetProps) {
  const router = useRouter();
  const [ratingOpen, setRatingOpen] = useState(false);
  const [noteOpen, setNoteOpen] = useState(false);
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState('');

  const [confirmedSaved, setConfirmedSaved] = useState(initialSaved);
  const [optimisticSaved, setOptimisticSaved] = useOptimistic(confirmedSaved);

  const [confirmedStatus, setConfirmedStatus] = useState<SavedDrinkStatus | null>(initialStatus);
  const [optimisticStatus, setOptimisticStatus] = useOptimistic(confirmedStatus);

  const [confirmedNote, setConfirmedNote] = useState(initialNote);
  const [optimisticNote, setOptimisticNote] = useOptimistic(confirmedNote);

  const [confirmedReview, setConfirmedReview] = useState<DrinkReview | null>(initialReview);
  const [optimisticReview, setOptimisticReview] = useOptimistic(confirmedReview);

  const [draftRating, setDraftRating] = useState<number | null>(null);
  const [draftComment, setDraftComment] = useState('');
  const [draftNote, setDraftNote] = useState(initialNote);

  const handleRatingOpen = (isOpen: boolean) => {
    if (isOpen) {
      setDraftRating(optimisticReview?.rating ?? null);
      setDraftComment(optimisticReview?.comment ?? '');
      setError('');
    }
    setRatingOpen(isOpen);
  };

  const handleNoteOpen = (isOpen: boolean) => {
    if (isOpen) {
      setDraftNote(optimisticNote);
      setError('');
    }
    setNoteOpen(isOpen);
  };

  const handleSave = (status: SavedDrinkStatus) => {
    startTransition(async () => {
      setOptimisticSaved(true);
      setOptimisticStatus(status);
      setError('');
      const result = await saveDrink(drinkId, drinkSlug, status);
      if (result.ok) {
        setConfirmedSaved(true);
        setConfirmedStatus(result.data?.status ?? status);
        if (result.data) setConfirmedNote(result.data.note);
        router.refresh();
        return;
      }
      setError(result.error);
    });
  };

  const handleToggleStatus = () => {
    if (!optimisticStatus) return;
    const next = oppositeSavedDrinkStatus(optimisticStatus);
    startTransition(async () => {
      setOptimisticStatus(next);
      setError('');
      const result = await updateSavedDrink(drinkId, drinkSlug, { status: next });
      if (result.ok) {
        setConfirmedStatus(result.data?.status ?? next);
        router.refresh();
        return;
      }
      setError(result.error);
    });
  };

  const handleSaveNote = () => {
    const note = draftNote.trim();
    startTransition(async () => {
      setOptimisticNote(note);
      setNoteOpen(false);
      setError('');
      const result = await updateSavedDrink(drinkId, drinkSlug, { note });
      if (result.ok) {
        setConfirmedNote(result.data?.note ?? note);
        router.refresh();
        return;
      }
      setError(result.error);
    });
  };

  const handleUnsave = () => {
    startTransition(async () => {
      setOptimisticSaved(false);
      setOptimisticStatus(null);
      setOptimisticNote('');
      setOptimisticReview(null);
      setError('');
      const result = await unsaveDrink(drinkId, drinkSlug);
      if (result.ok) {
        setConfirmedSaved(false);
        setConfirmedStatus(null);
        setConfirmedNote('');
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
      if (!optimisticStatus) setOptimisticStatus('drank');
      setRatingOpen(false);
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
        if (!confirmedStatus) setConfirmedStatus('drank');
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

  const noteDialog = (
    <NoteDialogContent
      draftNote={draftNote}
      onNoteChange={setDraftNote}
      onSubmit={handleSaveNote}
      isPending={isPending}
      error={error}
    />
  );

  return (
    <div className="space-y-3">
      {optimisticSaved && optimisticStatus ? (
        <div className="space-y-3">
          <div className="flex flex-wrap items-center gap-3">
            <p className="text-sm font-medium">{savedDrinkStatusLabel(optimisticStatus)}</p>
            <Button
              type="button"
              variant="outline"
              size="sm"
              disabled={isPending}
              onClick={handleToggleStatus}
            >
              {optimisticStatus === 'drank' ? '飲みたいにする' : '飲んだにする'}
            </Button>
          </div>

          {optimisticNote ? (
            <p className="text-muted-foreground text-sm whitespace-pre-wrap">{optimisticNote}</p>
          ) : null}

          <div className="flex flex-wrap items-center gap-3">
            <Dialog open={noteOpen} onOpenChange={handleNoteOpen}>
              <DialogTrigger render={<Button variant="outline" size="sm" disabled={isPending} />}>
                {optimisticNote ? 'メモを編集' : 'メモを追加'}
              </DialogTrigger>
              {noteDialog}
            </Dialog>

            {optimisticReview ? (
              <>
                <StarRatingDisplay value={optimisticReview.rating} size="md" showValue={false} />
                <span className="text-foreground font-medium">{optimisticReview.rating}つ星</span>
                {optimisticReview.comment && (
                  <p className="text-muted-foreground w-full text-sm">{optimisticReview.comment}</p>
                )}
                <Dialog open={ratingOpen} onOpenChange={handleRatingOpen}>
                  <DialogTrigger
                    render={<Button variant="outline" size="sm" disabled={isPending} />}
                  >
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
              </>
            ) : (
              <Dialog open={ratingOpen} onOpenChange={handleRatingOpen}>
                <DialogTrigger render={<Button variant="outline" size="sm" disabled={isPending} />}>
                  評価する
                </DialogTrigger>
                {ratingDialog}
              </Dialog>
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
        </div>
      ) : (
        <div className="flex flex-wrap items-center gap-3">
          <Button type="button" size="sm" disabled={isPending} onClick={() => handleSave('drank')}>
            飲んだ
          </Button>
          <Button type="button" size="sm" disabled={isPending} onClick={() => handleSave('want')}>
            飲みたい
          </Button>
          <Dialog open={ratingOpen} onOpenChange={handleRatingOpen}>
            <DialogTrigger render={<Button variant="secondary" size="sm" disabled={isPending} />}>
              評価する
            </DialogTrigger>
            {ratingDialog}
          </Dialog>
        </div>
      )}

      {isPending && <span className="text-muted-foreground animate-pulse text-xs">送信中…</span>}
      {!ratingOpen && !noteOpen && error && <p className="text-destructive text-sm">{error}</p>}
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

interface NoteDialogContentProps {
  draftNote: string;
  onNoteChange: (note: string) => void;
  onSubmit: () => void;
  isPending: boolean;
  error: string;
}

function NoteDialogContent({
  draftNote,
  onNoteChange,
  onSubmit,
  isPending,
  error,
}: NoteDialogContentProps) {
  return (
    <DialogContent className="sm:max-w-md">
      <DialogHeader>
        <DialogTitle>メモ</DialogTitle>
      </DialogHeader>

      <div className="space-y-4 py-2">
        <div className="space-y-2">
          <Label htmlFor="saved-drink-note">非公開メモ (任意)</Label>
          <Textarea
            id="saved-drink-note"
            placeholder="覚え書き（任意）"
            value={draftNote}
            onChange={(e) => onNoteChange(e.target.value)}
            maxLength={MAX_NOTE_LEN}
            disabled={isPending}
            className="resize-none"
            rows={3}
          />
          <p className="text-muted-foreground text-right text-xs">
            {[...draftNote].length} / {MAX_NOTE_LEN}
          </p>
        </div>
        {error && <p className="text-destructive text-sm">{error}</p>}
      </div>

      <DialogFooter>
        <Button onClick={onSubmit} disabled={isPending}>
          {isPending ? '送信中…' : '保存'}
        </Button>
      </DialogFooter>
    </DialogContent>
  );
}
