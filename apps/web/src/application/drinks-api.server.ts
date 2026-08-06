import 'server-only';

import type { Drink } from '@sakehub/types';

import { serverFetch } from './server-api';

interface ApiDrink {
  id: string;
  slug: string;
  name: string;
  name_en?: string;
  category: string;
  subcategory?: string;
  description: string;
  image_url?: string;
  abv?: number;
  origin_country?: string;
  manufacturer?: string;
  average_rating: number;
  total_reviews: number;
  created_at: string;
  updated_at: string;
}

interface ApiDrinkListResponse {
  data: ApiDrink[];
  total: number;
  limit: number;
  offset: number;
}

function toDrink(api: ApiDrink): Drink {
  return {
    id: api.id,
    slug: api.slug,
    name: api.name,
    nameEn: api.name_en,
    category: api.category as Drink['category'],
    subcategory: api.subcategory,
    description: api.description,
    imageUrl: api.image_url,
    abv: api.abv,
    originCountry: api.origin_country,
    manufacturer: api.manufacturer,
    averageRating: api.average_rating,
    totalReviews: api.total_reviews,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

export interface DrinkListResult {
  drinks: Drink[];
  total: number;
  limit: number;
  offset: number;
}

export interface FetchDrinksParams {
  category?: string;
  q?: string;
  limit?: number;
  offset?: number;
}

export async function fetchDrinksServer(params: FetchDrinksParams = {}): Promise<DrinkListResult> {
  const queryParams: Record<string, string> = {};
  if (params.category && params.category !== 'all') {
    queryParams.category = params.category;
  }
  if (params.q) {
    queryParams.q = params.q;
  }
  if (params.limit) {
    queryParams.limit = String(params.limit);
  }
  if (params.offset) {
    queryParams.offset = String(params.offset);
  }

  const res = await serverFetch<ApiDrinkListResponse>('/api/drinks', { params: queryParams });

  return {
    drinks: (res.data ?? []).map(toDrink),
    total: res.total,
    limit: res.limit,
    offset: res.offset,
  };
}

export async function fetchDrinkBySlugServer(slug: string): Promise<Drink> {
  const res = await serverFetch<ApiDrink>(`/api/drinks/by-slug/${encodeURIComponent(slug)}`);
  return toDrink(res);
}
