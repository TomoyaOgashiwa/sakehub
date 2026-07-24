import type { Cocktail } from '@sakehub/types';
import Image from 'next/image';
import Link from 'next/link';
import { Martini } from 'lucide-react';

import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';

interface CocktailCardProps {
  cocktail: Cocktail;
}

export function CocktailCard({ cocktail }: CocktailCardProps) {
  return (
    <Link href={`/cocktails/${cocktail.slug}`} className="group block">
      <Card className="h-full transition-shadow group-hover:shadow-md">
        <figure className="bg-muted flex items-center justify-center px-4 pt-4">
          {cocktail.imageUrl ? (
            <div className="relative aspect-4/3 w-full overflow-hidden rounded-lg">
              <Image
                src={cocktail.imageUrl}
                alt={cocktail.name}
                fill
                sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 25vw"
                className="object-cover"
              />
            </div>
          ) : (
            <div className="from-muted to-muted-foreground/10 flex aspect-4/3 w-full items-center justify-center rounded-lg bg-gradient-to-br">
              <Martini className="text-muted-foreground/40 size-12" aria-hidden="true" />
            </div>
          )}
        </figure>

        <CardHeader>
          <div className="flex items-start justify-between gap-2">
            <CardTitle className="line-clamp-1">{cocktail.name}</CardTitle>
            {cocktail.baseSpirit && (
              <Badge variant="outline" className="shrink-0 capitalize">
                {cocktail.baseSpirit}
              </Badge>
            )}
          </div>
          {cocktail.nameEn && <p className="text-muted-foreground text-xs">{cocktail.nameEn}</p>}
        </CardHeader>

        <CardContent>
          <p className="text-muted-foreground line-clamp-2 text-sm">{cocktail.description}</p>
        </CardContent>

        <CardFooter className="text-muted-foreground gap-4 text-xs">
          {cocktail.abv != null && <span>{cocktail.abv}%</span>}
          {cocktail.originCountry && <span>{cocktail.originCountry}</span>}
          <span className="ml-auto font-medium">レシピ {cocktail.recipeCount}件</span>
        </CardFooter>
      </Card>
    </Link>
  );
}
