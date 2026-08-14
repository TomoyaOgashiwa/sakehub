import Link from 'next/link';
import {
  Barrel,
  Beer,
  Blend,
  BottleWine,
  Candy,
  ChevronRight,
  Citrus,
  Flame,
  FlaskRound,
  Flower2,
  Leaf,
  Snowflake,
  Wine,
  type LucideIcon,
} from 'lucide-react';
import type { DrinkCategory, ListDepth, ListDepthMaker, ListDepthSpecialty } from '@sakehub/types';

import { Badge } from '@/components/ui/badge';
import {
  Card,
  CardAction,
  CardContent,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { drinkCategoryLabel, makerSearchHref } from '@/config/drinks';
import { cn } from '@/utils/utils';

interface ListDepthMapProps {
  depth: ListDepth;
  activeCategory?: Exclude<DrinkCategory, 'all'> | null;
  showMakers?: boolean;
}

interface CategoryVisual {
  icon: LucideIcon;
  well: string;
  ink: string;
  fill: string;
}

const CATEGORY_VISUAL: Record<Exclude<DrinkCategory, 'all'>, CategoryVisual> = {
  beer: {
    icon: Beer,
    well: 'bg-drink-beer',
    ink: 'text-drink-beer-foreground',
    fill: 'bg-drink-beer-foreground',
  },
  wine: {
    icon: Wine,
    well: 'bg-drink-wine',
    ink: 'text-drink-wine-foreground',
    fill: 'bg-drink-wine-foreground',
  },
  whisky: {
    icon: Barrel,
    well: 'bg-drink-whisky',
    ink: 'text-drink-whisky-foreground',
    fill: 'bg-drink-whisky-foreground',
  },
  sake: {
    icon: Flower2,
    well: 'bg-drink-sake',
    ink: 'text-drink-sake-foreground',
    fill: 'bg-drink-sake-foreground',
  },
  shochu: {
    icon: FlaskRound,
    well: 'bg-drink-shochu',
    ink: 'text-drink-shochu-foreground',
    fill: 'bg-drink-shochu-foreground',
  },
  vodka: {
    icon: Snowflake,
    well: 'bg-drink-vodka',
    ink: 'text-drink-vodka-foreground',
    fill: 'bg-drink-vodka-foreground',
  },
  gin: {
    icon: Leaf,
    well: 'bg-drink-gin',
    ink: 'text-drink-gin-foreground',
    fill: 'bg-drink-gin-foreground',
  },
  rum: {
    icon: Flame,
    well: 'bg-drink-rum',
    ink: 'text-drink-rum-foreground',
    fill: 'bg-drink-rum-foreground',
  },
  tequila: {
    icon: Citrus,
    well: 'bg-drink-tequila',
    ink: 'text-drink-tequila-foreground',
    fill: 'bg-drink-tequila-foreground',
  },
  brandy: {
    icon: BottleWine,
    well: 'bg-drink-brandy',
    ink: 'text-drink-brandy-foreground',
    fill: 'bg-drink-brandy-foreground',
  },
  liqueur: {
    icon: Candy,
    well: 'bg-drink-liqueur',
    ink: 'text-drink-liqueur-foreground',
    fill: 'bg-drink-liqueur-foreground',
  },
  other: {
    icon: Blend,
    well: 'bg-drink-other',
    ink: 'text-drink-other-foreground',
    fill: 'bg-drink-other-foreground',
  },
};

export function DrinkCategoryGlyph({
  category,
  className,
}: {
  category: Exclude<DrinkCategory, 'all'>;
  className?: string;
}) {
  const visual = CATEGORY_VISUAL[category];
  const Icon = visual.icon;

  return (
    <span
      className={cn(
        'flex size-8 items-center justify-center rounded-lg [&>svg]:size-4',
        visual.well,
        visual.ink,
        className,
      )}
      aria-hidden="true"
    >
      <Icon />
    </span>
  );
}

function categoryHref(category: Exclude<DrinkCategory, 'all'>): string {
  return `/list?category=${encodeURIComponent(category)}`;
}

function CategoryFillTrack({
  drank,
  total,
  className,
}: {
  drank: number;
  total: number;
  className: string;
}) {
  const widthPercent = total > 0 ? Math.min(100, (drank / total) * 100) : 0;

  return (
    <div className="bg-muted h-1.5 overflow-hidden rounded-full" aria-hidden="true">
      <div
        className={cn('h-full rounded-full', className, drank > 0 && 'min-w-0.5')}
        style={{ width: `${widthPercent}%` }}
      />
    </div>
  );
}

function CategorySectionCard({ row }: { row: ListDepthSpecialty }) {
  const label = drinkCategoryLabel(row.category);
  const visual = CATEGORY_VISUAL[row.category];

  return (
    <li>
      <Link
        href={categoryHref(row.category)}
        className="group focus-visible:ring-ring/50 block rounded-xl outline-none focus-visible:ring-3"
        aria-label={`${label} ${row.drank} / ${row.total}`}
      >
        <Card className="transition-shadow group-hover:shadow-md">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <DrinkCategoryGlyph category={row.category} />
              {label}
            </CardTitle>
            <CardAction>
              <ChevronRight className="text-muted-foreground" aria-hidden="true" />
            </CardAction>
          </CardHeader>
          <CardContent className="flex flex-col gap-3">
            <p className="text-3xl font-semibold tabular-nums">
              {row.drank}{' '}
              <span className="text-muted-foreground text-lg font-normal">/ {row.total}</span>
            </p>
            <CategoryFillTrack drank={row.drank} total={row.total} className={visual.fill} />
          </CardContent>
        </Card>
      </Link>
    </li>
  );
}

function CategorySwitcher({
  categories,
  activeCategory,
}: {
  categories: ListDepthSpecialty[];
  activeCategory: Exclude<DrinkCategory, 'all'> | null;
}) {
  return (
    <nav aria-label="カテゴリ切替">
      <ul className="flex flex-wrap gap-2">
        {categories.map((row) => {
          const active = row.category === activeCategory;
          const Icon = CATEGORY_VISUAL[row.category].icon;
          return (
            <li key={row.category}>
              <Badge
                variant={active ? 'default' : 'outline'}
                render={
                  <Link
                    href={categoryHref(row.category)}
                    aria-current={active ? 'page' : undefined}
                  />
                }
              >
                <Icon className={active ? undefined : CATEGORY_VISUAL[row.category].ink} />
                {drinkCategoryLabel(row.category)}
              </Badge>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}

function MakerSectionCard({
  maker,
  category,
}: {
  maker: ListDepthMaker;
  category: Exclude<DrinkCategory, 'all'> | undefined;
}) {
  const searchHref = makerSearchHref(maker.manufacturer, category);

  return (
    <li>
      <Card>
        <CardHeader>
          <CardTitle>
            <Link href={searchHref} className="hover:underline">
              {maker.manufacturer} {maker.drank}種
            </Link>
          </CardTitle>
        </CardHeader>
        {maker.nextDrinks.length > 0 ? (
          <>
            <CardContent>
              <ul className="flex flex-col gap-1">
                {maker.nextDrinks.map((drink) => (
                  <li key={drink.slug}>
                    <Link
                      href={`/drinks/${drink.slug}`}
                      className="text-muted-foreground hover:underline"
                    >
                      {drink.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </CardContent>
            <CardFooter>
              <Link href={searchHref} className="text-muted-foreground text-sm hover:underline">
                同じ作り手の銘柄
              </Link>
            </CardFooter>
          </>
        ) : null}
      </Card>
    </li>
  );
}

export function ListDepthMap({
  depth,
  activeCategory = null,
  showMakers = false,
}: ListDepthMapProps) {
  if (depth.categories.length === 0) {
    return (
      <section aria-label="記録した銘柄の埋まり" className="rounded-lg border border-dashed p-4">
        <p className="text-muted-foreground mb-2 text-sm">まだ記録した銘柄がありません</p>
        <Link href="/" className="text-foreground text-sm font-medium underline">
          銘柄を探す
        </Link>
      </section>
    );
  }

  const { categories, makers } = depth;
  const isCategoryView = showMakers || activeCategory != null;

  if (isCategoryView) {
    return (
      <section aria-label="記録した銘柄の埋まり" className="flex flex-col gap-4">
        <CategorySwitcher categories={categories} activeCategory={activeCategory} />
        {showMakers && makers.length > 0 ? (
          <ul className="flex flex-col gap-3">
            {makers.map((maker) => (
              <MakerSectionCard
                key={maker.manufacturer}
                maker={maker}
                category={activeCategory ?? undefined}
              />
            ))}
          </ul>
        ) : null}
      </section>
    );
  }

  return (
    <section aria-label="記録した銘柄の埋まり">
      <ul className="flex flex-col gap-3">
        {categories.map((row) => (
          <CategorySectionCard key={row.category} row={row} />
        ))}
      </ul>
    </section>
  );
}
