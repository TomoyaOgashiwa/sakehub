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
  name: string;
  category: Exclude<DrinkCategory, 'all'>;
  description: string;
  imageUrl?: string;
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
