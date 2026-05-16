import type { Drink } from '@sakehub/types';

import { DrinkCard } from './drink-card';

interface DrinkGridProps {
  drinks: Drink[];
}

export function DrinkGrid({ drinks }: DrinkGridProps) {
  if (drinks.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-center">
        <p className="text-muted-foreground text-lg">お酒が見つかりませんでした</p>
        <p className="text-muted-foreground mt-1 text-sm">検索条件を変更してみてください</p>
      </div>
    );
  }

  return (
    <section aria-label="お酒一覧">
      <ul
        className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
        role="list"
      >
        {drinks.map((drink) => (
          <li key={drink.id}>
            <DrinkCard drink={drink} />
          </li>
        ))}
      </ul>
    </section>
  );
}
