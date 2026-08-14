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
  /** Categories with drank > 0 only. Sorted by count, then fill ratio.
   *  drank is unique published drink_id in saved.drank ∪ catalog drink_logs. */
  categories: ListDepthSpecialty[];
  makers: ListDepthMaker[];
  /** specialty = makers are in the top category; all = fallback across categories. */
  makerScope: 'specialty' | 'all';
  /** saved_drinks on provisional drinks. Not included in drank / total. */
  provisionalCount: number;
}

/** One personal mark per user per catalog drink. Rating is an optional annotation.
 *  `id` is empty when the drink is in the drank union but has no saved_drinks row. */
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
