'use client';

import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { useActionState } from 'react';

import { Button } from '@/components/ui/button';
import { Heading } from '@/components/ui/heading';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { safeNextPath } from '@/utils/safe-next-path';

import { type AuthState, signUp } from '../actions';

const initialState: AuthState = { ok: false, error: '' };

export default function SignupPage() {
  const searchParams = useSearchParams();
  const next = safeNextPath(searchParams.get('next'));
  const [state, formAction, isPending] = useActionState(signUp, initialState);
  const loginHref = next === '/' ? '/login' : `/login?next=${encodeURIComponent(next)}`;

  return (
    <div className="space-y-6">
      <div className="space-y-2 text-center">
        <Heading level="h1">Create Account</Heading>
        <p className="text-muted-foreground text-sm">飲んだ／飲みたいを残すために登録</p>
      </div>

      <form action={formAction} className="space-y-4">
        {next !== '/' && <input type="hidden" name="next" value={next} />}
        <div className="space-y-2">
          <Label htmlFor="email">Email</Label>
          <Input id="email" name="email" type="email" placeholder="you@example.com" required />
        </div>
        <div className="space-y-2">
          <Label htmlFor="password">Password</Label>
          <Input id="password" name="password" type="password" minLength={6} required />
        </div>
        <div className="space-y-2">
          <Label htmlFor="confirmPassword">Confirm Password</Label>
          <Input
            id="confirmPassword"
            name="confirmPassword"
            type="password"
            minLength={6}
            required
          />
        </div>

        {!state.ok && state.error && <p className="text-destructive text-sm">{state.error}</p>}

        <Button type="submit" className="w-full" disabled={isPending}>
          {isPending ? 'Creating account...' : 'Sign Up'}
        </Button>
      </form>

      <p className="text-muted-foreground text-center text-sm">
        Already have an account?{' '}
        <Link href={loginHref} className="text-foreground underline underline-offset-4">
          Sign In
        </Link>
      </p>
    </div>
  );
}
