import Image from 'next/image';
import Link from 'next/link';
import type { ReactNode } from 'react';

import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';

interface EntityCatalogCardProps {
  href: string;
  title: string;
  subtitle?: string;
  description: string;
  imageUrl?: string;
  imageAlt: string;
  badge?: string;
  fallbackIcon: ReactNode;
  footer?: ReactNode;
}

/** Shared media catalog card used by drinks and cocktail masters. */
export function EntityCatalogCard({
  href,
  title,
  subtitle,
  description,
  imageUrl,
  imageAlt,
  badge,
  fallbackIcon,
  footer,
}: EntityCatalogCardProps) {
  return (
    <Link href={href} className="group block">
      <Card className="h-full transition-shadow group-hover:shadow-md">
        <figure className="bg-muted flex items-center justify-center px-4 pt-4">
          {imageUrl ? (
            <div className="relative aspect-4/3 w-full overflow-hidden rounded-lg">
              <Image
                src={imageUrl}
                alt={imageAlt}
                fill
                sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 25vw"
                className="object-cover"
              />
            </div>
          ) : (
            <div className="from-muted to-muted-foreground/10 flex aspect-4/3 w-full items-center justify-center rounded-lg bg-gradient-to-br">
              {fallbackIcon}
            </div>
          )}
        </figure>

        <CardHeader>
          <div className="flex items-start justify-between gap-2">
            <CardTitle className="line-clamp-1">{title}</CardTitle>
            {badge && (
              <Badge variant="outline" className="shrink-0 capitalize">
                {badge}
              </Badge>
            )}
          </div>
          {subtitle && <p className="text-muted-foreground text-xs">{subtitle}</p>}
        </CardHeader>

        <CardContent>
          <p className="text-muted-foreground line-clamp-2 text-sm">{description}</p>
        </CardContent>

        {footer != null && (
          <CardFooter className="text-muted-foreground gap-4 text-xs">{footer}</CardFooter>
        )}
      </Card>
    </Link>
  );
}
