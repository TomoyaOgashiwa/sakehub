import type {
  ListDepth,
  ListDepthSpecialty,
  SavedDrink,
  SavedDrinkCatalog,
  SavedDrinkStatus,
} from '@sakehub/types';

export interface ApiSavedDrinkCatalog {
  id: string;
  slug: string;
  name: string;
  name_en?: string;
  category: string;
  image_url?: string;
  visibility?: 'published' | 'provisional';
  manufacturer?: string;
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
    manufacturer: api.manufacturer,
  };
}

export interface ApiListDepth {
  specialty: { category: string; drank: number; total: number } | null;
  categories?: { category: string; drank: number; total: number }[];
  makers: {
    manufacturer: string;
    drank: number;
    next_drinks?: { slug: string; name: string }[];
  }[];
  maker_scope?: 'specialty' | 'all';
  provisional_count?: number;
}

function toSpecialty(row: { category: string; drank: number; total: number }): ListDepthSpecialty {
  return {
    category: row.category as ListDepthSpecialty['category'],
    drank: row.drank,
    total: row.total,
  };
}

export function toListDepth(api: ApiListDepth): ListDepth {
  return {
    specialty: api.specialty ? toSpecialty(api.specialty) : null,
    categories: (api.categories ?? []).map(toSpecialty),
    makers: (api.makers ?? []).map((maker) => ({
      manufacturer: maker.manufacturer,
      drank: maker.drank,
      nextDrinks: (maker.next_drinks ?? []).map((drink) => ({
        slug: drink.slug,
        name: drink.name,
      })),
    })),
    makerScope: api.maker_scope === 'all' ? 'all' : 'specialty',
    provisionalCount: api.provisional_count ?? 0,
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
