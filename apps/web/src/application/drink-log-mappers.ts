import type {
  DrinkCategoryProduct,
  DrinkLog,
  DrinkLogSummary,
  VolumePrecision,
  VolumeUnit,
} from '@sakehub/types';

export interface ApiDrinkLogDrink {
  id: string;
  slug: string;
  name: string;
  category: string;
  abv?: number;
}

export interface ApiDrinkLog {
  id: string;
  user_id: string;
  drink_id?: string | null;
  custom_drink_name?: string | null;
  drank_at: string;
  volume_ml: number;
  quantity: number;
  input_unit: VolumeUnit;
  input_value: number;
  serving_key?: string | null;
  volume_precision: VolumePrecision;
  place_name?: string | null;
  place_url?: string | null;
  created_at: string;
  updated_at: string;
  drink?: ApiDrinkLogDrink | null;
}

export interface ApiDrinkLogSummary {
  from: string;
  to: string;
  log_count: number;
  pure_alcohol_grams: number;
  skipped_missing_abv: number;
}

export function toDrinkLog(api: ApiDrinkLog): DrinkLog {
  return {
    id: api.id,
    userId: api.user_id,
    drinkId: api.drink_id ?? undefined,
    customDrinkName: api.custom_drink_name ?? undefined,
    drankAt: api.drank_at,
    volumeMl: api.volume_ml,
    quantity: api.quantity ?? 1,
    inputUnit: api.input_unit,
    inputValue: api.input_value,
    servingKey: api.serving_key ?? undefined,
    volumePrecision: api.volume_precision,
    placeName: api.place_name ?? undefined,
    placeUrl: api.place_url ?? undefined,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
    drink: api.drink
      ? {
          id: api.drink.id,
          slug: api.drink.slug,
          name: api.drink.name,
          category: api.drink.category as DrinkCategoryProduct,
          abv: api.drink.abv,
        }
      : undefined,
  };
}

export function toDrinkLogSummary(api: ApiDrinkLogSummary): DrinkLogSummary {
  return {
    from: api.from,
    to: api.to,
    logCount: api.log_count,
    pureAlcoholGrams: api.pure_alcohol_grams,
    skippedMissingAbv: api.skipped_missing_abv,
  };
}
