import type { DrinkCategory } from './drink';

export type SavedDrinkStatus = 'drank' | 'want';

export interface SavedDrinkCatalog {
  id: string;
  slug: string;
  name: string;
  nameEn?: string;
  category: Exclude<DrinkCategory, 'all'>;
  imageUrl?: string;
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
