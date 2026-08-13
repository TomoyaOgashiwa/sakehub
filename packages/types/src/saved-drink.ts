import type { DrinkCategory } from './drink';

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
  createdAt: string;
  drink?: SavedDrinkCatalog;
  rating?: number;
  comment?: string;
}
