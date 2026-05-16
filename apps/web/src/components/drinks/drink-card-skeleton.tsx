import { Card, CardContent, CardFooter, CardHeader } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';

export function DrinkCardSkeleton() {
  return (
    <Card className="h-full">
      <div className="px-4 pt-4">
        <Skeleton className="aspect-4/3 w-full rounded-lg" />
      </div>
      <CardHeader>
        <div className="flex items-start justify-between gap-2">
          <Skeleton className="h-5 w-32" />
          <Skeleton className="h-5 w-16 rounded-full" />
        </div>
        <Skeleton className="h-3 w-24" />
      </CardHeader>
      <CardContent>
        <Skeleton className="h-4 w-full" />
        <Skeleton className="mt-1 h-4 w-3/4" />
      </CardContent>
      <CardFooter>
        <Skeleton className="h-3 w-20" />
      </CardFooter>
    </Card>
  );
}

export function DrinkGridSkeleton({ count = 8 }: { count?: number }) {
  return (
    <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {Array.from({ length: count }, (_, i) => (
        <DrinkCardSkeleton key={i} />
      ))}
    </div>
  );
}
