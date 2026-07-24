import type { MetadataRoute } from 'next';

import { fetchDrinksServer } from '@/application/drinks-api.server';
import { fetchCocktailsServer } from '@/application/cocktails-api.server';

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

  const [drinkRoutes, cocktailRoutes] = await Promise.all([
    fetchDrinksServer({ limit: 1000 })
      .then(({ drinks }) =>
        drinks.map(
          (drink): MetadataRoute.Sitemap[number] => ({
            url: `${baseUrl}/drinks/${drink.slug}`,
            lastModified: new Date(drink.updatedAt),
            changeFrequency: 'weekly',
            priority: 0.8,
          }),
        ),
      )
      .catch((): MetadataRoute.Sitemap => []),
    fetchCocktailsServer()
      .then((cocktails) =>
        cocktails.map(
          (cocktail): MetadataRoute.Sitemap[number] => ({
            url: `${baseUrl}/cocktails/${cocktail.slug}`,
            lastModified: new Date(cocktail.updatedAt),
            changeFrequency: 'weekly',
            priority: 0.8,
          }),
        ),
      )
      .catch((): MetadataRoute.Sitemap => []),
  ]);

  return [...staticRoutes, ...drinkRoutes, ...cocktailRoutes];
}
