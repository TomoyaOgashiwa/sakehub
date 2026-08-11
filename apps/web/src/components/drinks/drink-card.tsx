import type { Drink } from '@sakehub/types';
import { Wine } from 'lucide-react';

import { EntityCatalogCard } from '@/components/catalog/entity-catalog-card';
import { Badge } from '@/components/ui/badge';
import { StarRatingDisplay } from '@/components/ui/star-rating';
import { getCatalogImageSourceLabel } from '@/utils/catalog-image-source-label';

interface DrinkCardProps {
  drink: Drink;
}

export function DrinkCard({ drink }: DrinkCardProps) {
  const imageSourceLabel = getCatalogImageSourceLabel(drink.imageSource);

  return (
    <EntityCatalogCard
      href={`/drinks/${drink.slug}`}
      title={drink.name}
      subtitle={drink.nameEn}
      description={drink.description}
      imageUrl={drink.imageUrl}
      imageAlt={drink.name}
      imageBadge={
        imageSourceLabel ? (
          <Badge variant={imageSourceLabel.variant} className="bg-background/90 shadow-sm">
            {imageSourceLabel.text}
          </Badge>
        ) : undefined
      }
      badge={drink.category}
      fallbackIcon={<Wine className="text-muted-foreground/40 size-12" aria-hidden="true" />}
      footer={
        <>
          {drink.abv != null && <span>{drink.abv}%</span>}
          {drink.originCountry && <span>{drink.originCountry}</span>}
          {drink.averageRating > 0 && (
            <div className="ml-auto">
              <StarRatingDisplay
                value={drink.averageRating}
                size="sm"
                showValue={false}
                className="gap-0.5"
              />
            </div>
          )}
        </>
      }
    />
  );
}
