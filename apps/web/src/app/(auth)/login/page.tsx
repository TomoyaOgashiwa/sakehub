'use client';

import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { useActionState } from 'react';

import { Button } from '@/components/ui/button';
import { Heading } from '@/components/ui/heading';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { isRecipeComposeNext } from '@/utils/recipe-compose-href';
import { safeNextPath } from '@/utils/safe-next-path';

import { type AuthState, signIn } from '../actions';

const initialState: AuthState = { ok: false, error: '' };

export default function LoginPage() {
  const searchParams = useSearchParams();
  const next = safeNextPath(searchParams.get('next'));
  const [state, formAction, isPending] = useActionState(signIn, initialState);
  const signupHref = next === '/' ? '/signup' : `/signup?next=${encodeURIComponent(next)}`;
  const copy = isRecipeComposeNext(next)
    ? 'アレンジレシピを投稿するためにログイン'
    : '飲んだ／飲みたいを残すためにログイン';

  return (
    <div className="space-y-6">
      <div className="space-y-2 text-center">
        <Heading level="h1">Sign In</Heading>
        <p className="text-muted-foreground text-sm">{copy}</p>
      </div>

      <form action={formAction} className="space-y-4">
        {next !== '/' && <input type="hidden" name="next" value={next} />}
        <div className="space-y-2">
          <Label htmlFor="email">Email</Label>
          <Input id="email" name="email" type="email" placeholder="you@example.com" required />
        </div>
        <div className="space-y-2">
          <Label htmlFor="password">Password</Label>
          <Input id="password" name="password" type="password" required />
        </div>

        {!state.ok && state.error && <p className="text-destructive text-sm">{state.error}</p>}

        <Button type="submit" className="w-full" disabled={isPending}>
          {isPending ? 'Signing in...' : 'Sign In'}
        </Button>
      </form>

      <p className="text-muted-foreground text-center text-sm">
        Don&apos;t have an account?{' '}
        <Link href={signupHref} className="text-foreground underline underline-offset-4">
          Sign Up
        </Link>
      </p>
    </div>
  );
}
