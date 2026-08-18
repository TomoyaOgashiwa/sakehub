import { loginHref } from '@/utils/login-href';

export function recipeComposePath(cocktailId?: string): string {
  const id = cocktailId?.trim();
  if (!id) return '/my-cocktails/new';
  return `/my-cocktails/new?cocktail_id=${encodeURIComponent(id)}`;
}

export function recipeComposeHref({
  loggedIn,
  cocktailId,
}: {
  loggedIn: boolean;
  cocktailId?: string;
}): string {
  const path = recipeComposePath(cocktailId);
  return loggedIn ? path : loginHref(path);
}

export function isRecipeComposeNext(next: string): boolean {
  return next.startsWith('/my-cocktails');
}
