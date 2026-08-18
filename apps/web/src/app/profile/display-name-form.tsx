'use client';

import { useActionState } from 'react';

import { Button } from '@/components/ui/button';
import { Field, FieldDescription, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field';
import { Input } from '@/components/ui/input';
import { DISPLAY_NAME_MAX_LENGTH } from '@/utils/display-label';

import { type ProfileActionState, updateDisplayName } from './actions';

const initialState: ProfileActionState = { ok: false, error: '' };

interface DisplayNameFormProps {
  defaultDisplayName: string;
}

export function DisplayNameForm({ defaultDisplayName }: DisplayNameFormProps) {
  const [state, formAction, isPending] = useActionState(updateDisplayName, initialState);
  const invalid = !state.ok && Boolean(state.error);

  return (
    <form action={formAction}>
      <FieldGroup>
        <Field data-invalid={invalid || undefined}>
          <FieldLabel htmlFor="display_name">Display Name</FieldLabel>
          <Input
            id="display_name"
            name="display_name"
            type="text"
            defaultValue={defaultDisplayName}
            maxLength={DISPLAY_NAME_MAX_LENGTH}
            autoComplete="nickname"
            aria-invalid={invalid || undefined}
            disabled={isPending}
          />
          <FieldDescription>1–{DISPLAY_NAME_MAX_LENGTH} characters. Required.</FieldDescription>
          {invalid ? <FieldError>{state.error}</FieldError> : null}
          {state.ok ? <p className="text-muted-foreground text-sm">Display name updated.</p> : null}
        </Field>
        <Button type="submit" disabled={isPending}>
          {isPending ? 'Saving...' : 'Save display name'}
        </Button>
      </FieldGroup>
    </form>
  );
}
