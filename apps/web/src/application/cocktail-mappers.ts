import type {
  Cocktail,
  CocktailRecipe,
  CocktailRecipeRating,
  CocktailRecipeSummary,
} from '@sakehub/types';

export interface ApiCocktail {
  id: string;
  slug: string;
  name: string;
  name_en?: string;
  description: string;
  image_url?: string;
  base_spirit?: string;
  abv?: number;
  origin_country?: string;
  recipe_count: number;
  created_at: string;
  updated_at: string;
}

export interface ApiRecipeSummary {
  id: string;
  cocktail_id: string;
  user_id: string;
  name: string;
  memo?: string;
  image_url?: string;
  status: 'draft' | 'published';
  average_rating: number;
  total_ratings: number;
  created_at: string;
  updated_at: string;
}

export interface ApiRecipeIngredient {
  id: string;
  recipe_id: string;
  name: string;
  amount?: number;
  unit?: string;
  sort_order: number;
  created_at: string;
}

export interface ApiRecipe extends ApiRecipeSummary {
  ingredients: ApiRecipeIngredient[];
}

export interface ApiCocktailDetail extends ApiCocktail {
  recipes: ApiRecipeSummary[];
  has_more_recipes?: boolean;
}

export interface ApiRecipeRating {
  id: string;
  recipe_id: string;
  user_id: string;
  rating: number;
  comment: string;
  created_at: string;
  updated_at: string;
}

export function toCocktail(api: ApiCocktail): Cocktail {
  return {
    id: api.id,
    slug: api.slug,
    name: api.name,
    nameEn: api.name_en,
    description: api.description,
    imageUrl: api.image_url,
    baseSpirit: api.base_spirit,
    abv: api.abv,
    originCountry: api.origin_country,
    recipeCount: api.recipe_count,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

export function toRecipeSummary(api: ApiRecipeSummary): CocktailRecipeSummary {
  return {
    id: api.id,
    cocktailId: api.cocktail_id,
    userId: api.user_id,
    name: api.name,
    memo: api.memo,
    imageUrl: api.image_url,
    status: api.status,
    averageRating: api.average_rating,
    totalRatings: api.total_ratings,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

export function toCocktailRecipe(api: ApiRecipe): CocktailRecipe {
  return {
    ...toRecipeSummary(api),
    ingredients: (api.ingredients ?? []).map((ing) => ({
      id: ing.id,
      recipeId: ing.recipe_id,
      name: ing.name,
      amount: ing.amount,
      unit: ing.unit as CocktailRecipe['ingredients'][number]['unit'],
      sortOrder: ing.sort_order,
      createdAt: ing.created_at,
    })),
  };
}

export function toRecipeRating(api: ApiRecipeRating): CocktailRecipeRating {
  return {
    id: api.id,
    recipeId: api.recipe_id,
    userId: api.user_id,
    rating: api.rating,
    comment: api.comment,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}
