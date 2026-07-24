import type { Cocktail } from '@sakehub/types';

import { apiClient } from './api-client';

export interface ApiCocktail {
  id: string;
  slug: string;
  name: string;
  name_en?: string;
  description: string;
  image_url?: string;
  base_spirit?: string;
  abv?: number;
  origin_country?: string;
  recipe_count: number;
  created_at: string;
  updated_at: string;
}

interface ApiCocktailListResponse {
  data: ApiCocktail[] | null;
}

export function toCocktail(api: ApiCocktail): Cocktail {
  return {
    id: api.id,
    slug: api.slug,
    name: api.name,
    nameEn: api.name_en,
    description: api.description,
    imageUrl: api.image_url,
    baseSpirit: api.base_spirit,
    abv: api.abv,
    originCountry: api.origin_country,
    recipeCount: api.recipe_count,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

export async function fetchCocktails(): Promise<Cocktail[]> {
  const res = await apiClient<ApiCocktailListResponse>('/api/cocktails');
  return (res.data ?? []).map(toCocktail);
}
