import type { DrinkCategory } from './drink';

export type SavedDrinkStatus = 'drank' | 'want';

export type DrinkVisibility = 'published' | 'provisional';

export interface SavedDrinkCatalog {
  id: string;
  slug: string;
  name: string;
  nameEn?: string;
  category: Exclude<DrinkCategory, 'all'>;
  imageUrl?: string;
  visibility: DrinkVisibility;
  manufacturer?: string;
}

export interface ListDepthSpecialty {
  category: Exclude<DrinkCategory, 'all'>;
  drank: number;
  total: number;
}

export interface ListDepthNextDrink {
  slug: string;
  name: string;
}

export interface ListDepthMaker {
  manufacturer: string;
  drank: number;
  nextDrinks: ListDepthNextDrink[];
}

/** Personal fill map for /list. Not a title ladder. */
export interface ListDepth {
  specialty: ListDepthSpecialty | null;
  makers: ListDepthMaker[];
  /** specialty = makers are in the top category; all = fallback across categories. */
  makerScope: 'specialty' | 'all';
}

/** One personal mark per user per catalog drink. Rating is an optional annotation. */
export interface SavedDrink {
  id: string;
  userId: string;
  drinkId: string;
  status: SavedDrinkStatus;
  note: string;
  createdAt: string;
  drink?: SavedDrinkCatalog;
  rating?: number;
  comment?: string;
}
