'use client';

import { useActionState, useState } from 'react';

import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Field, FieldError, FieldLabel } from '@/components/ui/field';
import { WITHDRAWN_AUTHOR_LABEL } from '@/utils/withdrawn-author';

import { type ProfileActionState, deleteAccount } from './actions';

const initialState: ProfileActionState = { ok: false, error: '' };

export function DeleteAccountSection() {
  const [state, formAction, isPending] = useActionState(deleteAccount, initialState);
  const [confirmed, setConfirmed] = useState(false);
  const invalid = !state.ok && Boolean(state.error);

  return (
    <div className="flex flex-col gap-3">
      <h2 className="text-destructive text-sm font-medium">Danger zone</h2>
      <p className="text-muted-foreground text-sm">
        退会するとリスト・評価・飲酒ログは削除されます。公開済みレシピの本文は「
        {WITHDRAWN_AUTHOR_LABEL}」名義で残ります。
      </p>

      <Dialog>
        <DialogTrigger render={<Button variant="destructive" />}>Delete account</DialogTrigger>
        <DialogContent className="sm:max-w-md" showCloseButton={!isPending}>
          <form action={formAction} className="flex flex-col gap-4">
            <DialogHeader>
              <DialogTitle>アカウントを削除しますか？</DialogTitle>
              <DialogDescription>
                この操作は取り消せません。リスト・評価・飲酒ログは消えます。公開済みレシピの本文は「
                {WITHDRAWN_AUTHOR_LABEL}」名義で残ります。同じメールでは再ログインできません。
              </DialogDescription>
            </DialogHeader>

            <Field orientation="horizontal" data-invalid={invalid || undefined}>
              <Checkbox
                id="confirm-deletion"
                checked={confirmed}
                onCheckedChange={(checked) => setConfirmed(checked === true)}
                disabled={isPending}
                aria-invalid={invalid || undefined}
              />
              {/* Base UI Checkbox は FormData に載らないため hidden で Server Action に渡す */}
              <input type="hidden" name="confirm" value={confirmed ? '1' : ''} />
              <FieldLabel htmlFor="confirm-deletion" className="font-normal">
                リスト・評価・ログが削除されることを理解しました
              </FieldLabel>
            </Field>
            {invalid ? <FieldError>{state.error}</FieldError> : null}

            <DialogFooter>
              <Button type="submit" variant="destructive" disabled={!confirmed || isPending}>
                {isPending ? 'Deleting...' : 'Delete account'}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {invalid ? (
        <p className="text-destructive text-sm" role="alert">
          {state.error}
        </p>
      ) : null}
    </div>
  );
}
