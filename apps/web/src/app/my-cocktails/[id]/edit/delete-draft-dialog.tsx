'use client';

import { useActionState } from 'react';

import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';

import { deleteDraftCocktailRecipe } from './actions';
import type { RecipeFormState } from '../../recipe-form-state';

const initialState: RecipeFormState = { ok: false, error: '' };

interface DeleteDraftDialogProps {
  recipeId: string;
}

export function DeleteDraftDialog({ recipeId }: DeleteDraftDialogProps) {
  const [state, formAction, isPending] = useActionState(deleteDraftCocktailRecipe, initialState);
  const invalid = !state.ok && Boolean(state.error);

  return (
    <div className="mt-10 border-t pt-6">
      <Dialog>
        <DialogTrigger render={<Button variant="destructive" />}>下書きを削除</DialogTrigger>
        <DialogContent className="sm:max-w-md" showCloseButton={!isPending}>
          <form action={formAction} className="flex flex-col gap-4">
            <input type="hidden" name="id" value={recipeId} readOnly />
            <DialogHeader>
              <DialogTitle>下書きを削除しますか？</DialogTitle>
              <DialogDescription>この下書きを削除しますか？取り消せません。</DialogDescription>
            </DialogHeader>
            {invalid ? (
              <p className="text-destructive text-sm" role="alert">
                {state.error}
              </p>
            ) : null}
            <DialogFooter>
              <Button type="submit" variant="destructive" disabled={isPending}>
                {isPending ? '削除中...' : '削除する'}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
