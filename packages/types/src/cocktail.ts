import type { CocktailRecipeStatus } from './cocktail-recipe';

/**
 * カクテル種別マスタ（例: レモンサワー、マンハッタン）。
 * ユーザー作成レシピ（CocktailRecipe）はこのマスタに紐づく。
 */
export interface Cocktail {
  id: string;
  slug: string;
  name: string;
  nameEn?: string;
  description: string;
  imageUrl?: string;
  baseSpirit?: string;
  abv?: number;
  originCountry?: string;
  recipeCount: number;
  createdAt: string;
  updatedAt: string;
}

/** ジャンル詳細ページの一覧表示用レシピ（材料を含まない軽量版）。 */
export interface CocktailRecipeSummary {
  id: string;
  cocktailId: string;
  userId: string;
  name: string;
  memo?: string;
  imageUrl?: string;
  status: CocktailRecipeStatus;
  averageRating: number;
  totalRatings: number;
  createdAt: string;
  updatedAt: string;
}

/** カクテルマスタ + 紐づく published レシピ一覧。 */
export interface CocktailDetail extends Cocktail {
  recipes: CocktailRecipeSummary[];
  /** true when more published recipes exist beyond the returned page. */
  hasMoreRecipes: boolean;
}

/** ユーザー作成レシピへの星評価。 */
export interface CocktailRecipeRating {
  id: string;
  recipeId: string;
  userId: string;
  rating: number;
  comment: string;
  createdAt: string;
  updatedAt: string;
}
