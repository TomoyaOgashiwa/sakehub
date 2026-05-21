'use client';

import { Button } from '@/components/ui/button';

import { signOut } from '../(auth)/actions';

export function SignOutButton() {
  return (
    <form action={signOut}>
      <Button type="submit" variant="outline">
        Sign Out
      </Button>
    </form>
  );
}
