import type { Cocktail } from '@sakehub/types';
import { Martini } from 'lucide-react';

import { EntityCatalogCard } from '@/components/catalog/entity-catalog-card';

interface CocktailCardProps {
  cocktail: Cocktail;
}

export function CocktailCard({ cocktail }: CocktailCardProps) {
  return (
    <EntityCatalogCard
      href={`/cocktails/${cocktail.slug}`}
      title={cocktail.name}
      subtitle={cocktail.nameEn}
      description={cocktail.description}
      imageUrl={cocktail.imageUrl}
      imageAlt={cocktail.name}
      badge={cocktail.baseSpirit}
      fallbackIcon={<Martini className="text-muted-foreground/40 size-12" aria-hidden="true" />}
      footer={
        <>
          {cocktail.abv != null && <span>{cocktail.abv}%</span>}
          {cocktail.originCountry && <span>{cocktail.originCountry}</span>}
          <span className="ml-auto font-medium">レシピ {cocktail.recipeCount}件</span>
        </>
      }
    />
  );
}
