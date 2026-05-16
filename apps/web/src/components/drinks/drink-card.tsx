import type { Drink } from '@sakehub/types';
import Image from 'next/image';
import Link from 'next/link';
import { Wine } from 'lucide-react';

import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';

interface DrinkCardProps {
  drink: Drink;
}

export function DrinkCard({ drink }: DrinkCardProps) {
  return (
    <Link href={`/drinks/${drink.slug}`} className="group block">
      <Card className="h-full transition-shadow group-hover:shadow-md">
        <figure className="bg-muted flex items-center justify-center px-4 pt-4">
          {drink.imageUrl ? (
            <div className="relative aspect-4/3 w-full overflow-hidden rounded-lg">
              <Image
                src={drink.imageUrl}
                alt={drink.name}
                fill
                sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 25vw"
                className="object-cover"
              />
            </div>
          ) : (
            <div className="from-muted to-muted-foreground/10 flex aspect-4/3 w-full items-center justify-center rounded-lg bg-gradient-to-br">
              <Wine className="text-muted-foreground/40 size-12" aria-hidden="true" />
            </div>
          )}
        </figure>

        <CardHeader>
          <div className="flex items-start justify-between gap-2">
            <CardTitle className="line-clamp-1">{drink.name}</CardTitle>
            <Badge variant="outline" className="shrink-0 capitalize">
              {drink.category}
            </Badge>
          </div>
          {drink.nameEn && <p className="text-muted-foreground text-xs">{drink.nameEn}</p>}
        </CardHeader>

        <CardContent>
          <p className="text-muted-foreground line-clamp-2 text-sm">{drink.description}</p>
        </CardContent>

        <CardFooter className="text-muted-foreground gap-4 text-xs">
          {drink.abv != null && <span>{drink.abv}%</span>}
          {drink.originCountry && <span>{drink.originCountry}</span>}
          {drink.averageRating > 0 && (
            <span className="ml-auto">
              {'★'} {drink.averageRating.toFixed(1)}
            </span>
          )}
        </CardFooter>
      </Card>
    </Link>
  );
}
