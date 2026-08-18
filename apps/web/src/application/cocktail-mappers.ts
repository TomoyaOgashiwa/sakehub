import type {
  CatalogImageSource,
  Cocktail,
  CocktailRecipe,
  CocktailRecipeRating,
  CocktailRecipeSummary,
  MyCocktailRecipeSummary,
} from '@sakehub/types';

export interface ApiCocktail {
  id: string;
  slug: string;
  name: string;
  name_en?: string;
  description: string;
  image_url?: string;
  image_source?: CatalogImageSource;
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
  user_id: string | null;
  author_name?: string;
  name: string;
  memo?: string;
  image_url?: string;
  status: 'draft' | 'published';
  is_official: boolean;
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

export interface ApiRecipeStep {
  id: string;
  recipe_id: string;
  body: string;
  sort_order: number;
  created_at: string;
}

export interface ApiRecipe extends ApiRecipeSummary {
  cocktail_slug?: string;
  ingredients: ApiRecipeIngredient[];
  steps: ApiRecipeStep[];
}

export interface ApiCocktailDetail extends ApiCocktail {
  official_recipe?: ApiRecipe | null;
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

export interface ApiMyRecipeSummary {
  id: string;
  name: string;
  status: 'draft' | 'published';
  image_url?: string;
  updated_at: string;
  cocktail_id: string;
  cocktail_slug: string;
  cocktail_name: string;
}

export interface ApiMyRecipeListResponse {
  data: ApiMyRecipeSummary[] | null;
  total: number;
  limit: number;
  offset: number;
}

export function toCocktail(api: ApiCocktail): Cocktail {
  return {
    id: api.id,
    slug: api.slug,
    name: api.name,
    nameEn: api.name_en,
    description: api.description,
    imageUrl: api.image_url,
    imageSource: api.image_source ?? 'none',
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
    userId: api.user_id ?? null,
    authorName: api.author_name,
    name: api.name,
    memo: api.memo,
    imageUrl: api.image_url,
    status: api.status,
    isOfficial: Boolean(api.is_official),
    averageRating: api.average_rating,
    totalRatings: api.total_ratings,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

export function toCocktailRecipe(api: ApiRecipe): CocktailRecipe {
  return {
    ...toRecipeSummary(api),
    cocktailSlug: api.cocktail_slug ?? '',
    ingredients: (api.ingredients ?? []).map((ing) => ({
      id: ing.id,
      recipeId: ing.recipe_id,
      name: ing.name,
      amount: ing.amount,
      unit: ing.unit as CocktailRecipe['ingredients'][number]['unit'],
      sortOrder: ing.sort_order,
      createdAt: ing.created_at,
    })),
    steps: (api.steps ?? []).map((step) => ({
      id: step.id,
      recipeId: step.recipe_id,
      body: step.body,
      sortOrder: step.sort_order,
      createdAt: step.created_at,
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

export function toMyRecipeSummary(api: ApiMyRecipeSummary): MyCocktailRecipeSummary {
  return {
    id: api.id,
    name: api.name,
    status: api.status,
    imageUrl: api.image_url,
    updatedAt: api.updated_at,
    cocktailId: api.cocktail_id,
    cocktailSlug: api.cocktail_slug ?? '',
    cocktailName: api.cocktail_name,
  };
}
