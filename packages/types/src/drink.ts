export const DRINK_CATEGORIES = [
  'all',
  'beer',
  'wine',
  'whisky',
  'sake',
  'shochu',
  'vodka',
  'gin',
  'rum',
  'tequila',
  'brandy',
  'liqueur',
  'cocktail',
  'other',
] as const;

export type DrinkCategory = (typeof DRINK_CATEGORIES)[number];

export type Drink = {
  id: string;
  slug: string;
  name: string;
  nameEn?: string;
  category: Exclude<DrinkCategory, 'all'>;
  subcategory?: string;
  description: string;
  imageUrl?: string;
  abv?: number;
  originCountry?: string;
  manufacturer?: string;
  averageRating: number;
  totalReviews: number;
  createdAt: string;
  updatedAt: string;
};

export type DrinkReview = {
  id: string;
  drinkId: string;
  userId: string;
  rating: number;
  comment: string;
  createdAt: string;
  updatedAt: string;
};
