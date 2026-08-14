import Link from 'next/link';
import type { Cocktail } from '@sakehub/types';

import { CocktailCard } from '@/components/cocktails/cocktail-card';
import { Heading } from '@/components/ui/heading';

interface BaseCocktailPreviewProps {
  heading: string;
  headingId: string;
  description: string;
  cocktails: Cocktail[];
  moreHref: string;
}

export function BaseCocktailPreview({
  heading,
  headingId,
  description,
  cocktails,
  moreHref,
}: BaseCocktailPreviewProps) {
  if (cocktails.length === 0) return null;

  return (
    <section aria-labelledby={headingId} className="flex flex-col gap-4">
      <div className="flex flex-col gap-1">
        <Heading level="h2" id={headingId}>
          {heading}
        </Heading>
        <p className="text-muted-foreground text-sm">{description}</p>
      </div>
      <ul className="grid grid-cols-1 gap-4 sm:grid-cols-2" role="list">
        {cocktails.map((cocktail) => (
          <li key={cocktail.id}>
            <CocktailCard cocktail={cocktail} />
          </li>
        ))}
      </ul>
      <p>
        <Link
          href={moreHref}
          className="text-foreground text-sm font-medium underline underline-offset-2"
        >
          同じベースのカクテル
        </Link>
      </p>
    </section>
  );
}
