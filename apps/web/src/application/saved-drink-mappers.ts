import type { SavedDrink, SavedDrinkCatalog, SavedDrinkStatus } from '@sakehub/types';

export interface ApiSavedDrinkCatalog {
  id: string;
  slug: string;
  name: string;
  name_en?: string;
  category: string;
  image_url?: string;
  visibility?: 'published' | 'provisional';
}

export interface ApiSavedDrink {
  id: string;
  user_id: string;
  drink_id: string;
  status: SavedDrinkStatus;
  note: string;
  created_at: string;
  drink?: ApiSavedDrinkCatalog;
  rating?: number;
  comment?: string;
}

function toCatalog(api: ApiSavedDrinkCatalog): SavedDrinkCatalog {
  return {
    id: api.id,
    slug: api.slug,
    name: api.name,
    nameEn: api.name_en,
    category: api.category as SavedDrinkCatalog['category'],
    imageUrl: api.image_url,
    visibility: api.visibility === 'provisional' ? 'provisional' : 'published',
  };
}

export function toSavedDrink(api: ApiSavedDrink): SavedDrink {
  return {
    id: api.id,
    userId: api.user_id,
    drinkId: api.drink_id,
    status: api.status,
    note: api.note ?? '',
    createdAt: api.created_at,
    drink: api.drink ? toCatalog(api.drink) : undefined,
    rating: api.rating,
    comment: api.comment,
  };
}
