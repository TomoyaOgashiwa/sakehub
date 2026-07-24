import type { Cocktail } from '@sakehub/types';

import { CocktailCard } from './cocktail-card';

interface CocktailGridProps {
  cocktails: Cocktail[];
}

export function CocktailGrid({ cocktails }: CocktailGridProps) {
  if (cocktails.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-center">
        <p className="text-muted-foreground text-lg">カクテルが見つかりませんでした</p>
        <p className="text-muted-foreground mt-1 text-sm">検索条件を変更してみてください</p>
      </div>
    );
  }

  return (
    <section aria-label="カクテル一覧">
      <ul
        className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
        role="list"
      >
        {cocktails.map((cocktail) => (
          <li key={cocktail.id}>
            <CocktailCard cocktail={cocktail} />
          </li>
        ))}
      </ul>
    </section>
  );
}
