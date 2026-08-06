import { DRINK_CATEGORIES as PRODUCT_DRINK_CATEGORIES } from '@sakehub/seed-utils';

/**
 * 'all'（UI フィルタの「すべて」チップ）を除いた実体は `@sakehub/seed-utils`
 * の `DRINK_CATEGORIES` を single source とする。DB の CHECK 制約
 * （supabase/migrations/20260515210611_create_drinks.sql）と
 * `packages/drink-seed/src/schema.ts` も同じ配列を参照しており、ここだけ
 * 更新して他が追従しない、という回帰を防ぐ。
 */
export const DRINK_CATEGORIES = ['all', ...PRODUCT_DRINK_CATEGORIES] as const;

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
