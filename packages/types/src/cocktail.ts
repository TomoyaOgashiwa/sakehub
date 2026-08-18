import type { CatalogImageSource } from './drink';
import type { CocktailRecipe, CocktailRecipeStatus } from './cocktail-recipe';

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
  imageSource: CatalogImageSource;
  baseSpirit?: string;
  abv?: number;
  originCountry?: string;
  recipeCount: number;
  createdAt: string;
  updatedAt: string;
}

/** GET /api/cocktails list response (paginated). */
export interface CocktailListResult {
  cocktails: Cocktail[];
  total: number;
  limit: number;
  offset: number;
}

export interface CocktailListParams {
  q?: string;
  baseSpirit?: string;
  limit?: number;
  offset?: number;
}

/** Zero-hit search log payload (POST /api/search-misses). */
export type SearchMissScope = 'cocktail' | 'drink' | 'ingredient';

export interface SearchMissCreateInput {
  scope: SearchMissScope;
  queryRaw: string;
  resultCount: number;
  clientHash?: string;
}

/** ジャンル詳細ページの一覧表示用レシピ（材料・手順を含まない軽量版）。 */
export interface CocktailRecipeSummary {
  id: string;
  cocktailId: string;
  userId: string | null;
  authorName?: string;
  name: string;
  memo?: string;
  imageUrl?: string;
  status: CocktailRecipeStatus;
  isOfficial: boolean;
  averageRating: number;
  totalRatings: number;
  createdAt: string;
  updatedAt: string;
}

/** カクテルマスタ + 紐づく published レシピ一覧 + 公式基本レシピ。 */
export interface CocktailDetail extends Cocktail {
  officialRecipe?: CocktailRecipe;
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
