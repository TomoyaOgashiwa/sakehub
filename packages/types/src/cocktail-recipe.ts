export const INGREDIENT_UNITS = [
  'ml',
  'g',
  'piece',
  'tsp',
  'tbsp',
  'dash',
  'drop',
  'oz',
  'cl',
] as const;

export type IngredientUnit = (typeof INGREDIENT_UNITS)[number];

export type CocktailRecipeStatus = 'draft' | 'published';

export interface CocktailRecipeIngredient {
  id: string;
  recipeId: string;
  name: string;
  amount?: number;
  unit?: IngredientUnit;
  sortOrder: number;
  createdAt: string;
}

export interface CocktailRecipe {
  id: string;
  cocktailId: string;
  /** Canonical cocktail master slug; used for URL validation without a second fetch. */
  cocktailSlug: string;
  userId: string;
  name: string;
  memo?: string;
  imageUrl?: string;
  status: CocktailRecipeStatus;
  averageRating: number;
  totalRatings: number;
  ingredients: CocktailRecipeIngredient[];
  createdAt: string;
  updatedAt: string;
}

export interface CreateCocktailRecipeIngredientInput {
  name: string;
  amount?: number;
  unit?: IngredientUnit;
  sortOrder: number;
}

export interface CreateCocktailRecipeInput {
  cocktailId: string;
  name: string;
  memo?: string;
  imageUrl?: string;
  status: CocktailRecipeStatus;
  ingredients: CreateCocktailRecipeIngredientInput[];
}
