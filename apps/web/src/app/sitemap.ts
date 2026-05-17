import type { MetadataRoute } from 'next';

import { fetchDrinksServer } from '@/application/drinks-api.server';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL ?? 'http://localhost:3000';

  const staticRoutes: MetadataRoute.Sitemap = [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
  ];

  try {
    const { drinks } = await fetchDrinksServer({ limit: 1000 });
    const drinkRoutes: MetadataRoute.Sitemap = drinks.map((drink) => ({
      url: `${baseUrl}/drinks/${drink.slug}`,
      lastModified: new Date(drink.updatedAt),
      changeFrequency: 'weekly',
      priority: 0.8,
    }));
    return [...staticRoutes, ...drinkRoutes];
  } catch {
    return staticRoutes;
  }
}
