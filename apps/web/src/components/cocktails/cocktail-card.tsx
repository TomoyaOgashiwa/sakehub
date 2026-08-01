import type { Cocktail } from '@sakehub/types';
import { Martini } from 'lucide-react';

import { Badge } from '@/components/ui/badge';
import { EntityCatalogCard } from '@/components/catalog/entity-catalog-card';

interface CocktailCardProps {
  cocktail: Cocktail;
}

export function CocktailCard({ cocktail }: CocktailCardProps) {
  const recruiting = cocktail.recipeCount === 0;

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
          {recruiting ? (
            <Badge variant="secondary" className="font-medium">
              レシピ募集中
            </Badge>
          ) : (
            <span className="font-medium">レシピ {cocktail.recipeCount}件</span>
          )}
          {cocktail.abv != null && <span className="ml-auto">{cocktail.abv}%</span>}
          {cocktail.originCountry && (
            <span className={cocktail.abv == null ? 'ml-auto' : undefined}>
              {cocktail.originCountry}
            </span>
          )}
        </>
      }
    />
  );
}
