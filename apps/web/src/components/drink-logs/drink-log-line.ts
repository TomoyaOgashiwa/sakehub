import type { DrinkCategoryProduct, DrinkLog, VolumePrecision, VolumeUnit } from '@sakehub/types';

import { presetsForCategory } from '@/config/serving-presets';

export interface DrinkLogLine {
  localId: string;
  logId?: string;
  kind: 'catalog' | 'custom';
  drinkId?: string;
  name: string;
  category?: DrinkCategoryProduct;
  unit: VolumeUnit;
  value: string;
  servingKey: string | null;
  precision: VolumePrecision;
  quantity: number;
}

export interface DrinkLogLineErrors {
  drink?: string;
  input_value?: string;
  quantity?: string;
}

export function createLineFromSelection(option: {
  kind: 'catalog' | 'custom';
  drinkId?: string;
  name: string;
  category?: DrinkCategoryProduct;
}): DrinkLogLine {
  const firstPreset =
    option.kind === 'catalog' && option.category
      ? presetsForCategory(option.category)[0]
      : undefined;
  const defaultMl = firstPreset?.volumeMl ?? 180;

  return {
    localId: crypto.randomUUID(),
    kind: option.kind,
    drinkId: option.drinkId,
    name: option.name,
    category: option.category,
    unit: 'ml',
    value: String(defaultMl),
    servingKey: firstPreset?.key ?? null,
    precision: firstPreset?.defaultPrecision ?? 'exact',
    quantity: 1,
  };
}

export function logToLine(log: DrinkLog): DrinkLogLine {
  if (log.drink) {
    return {
      localId: log.id,
      logId: log.id,
      kind: 'catalog',
      drinkId: log.drink.id,
      name: log.drink.name,
      category: log.drink.category,
      unit: log.inputUnit,
      value: String(log.inputValue),
      servingKey: log.servingKey ?? null,
      precision: log.volumePrecision,
      quantity: log.quantity,
    };
  }
  return {
    localId: log.id,
    logId: log.id,
    kind: 'custom',
    name: log.customDrinkName ?? '不明な銘柄',
    unit: log.inputUnit,
    value: String(log.inputValue),
    servingKey: null,
    precision: log.volumePrecision,
    quantity: log.quantity,
  };
}

export function lineToApiItem(line: DrinkLogLine) {
  return {
    ...(line.logId ? { id: line.logId } : {}),
    ...(line.kind === 'catalog' && line.drinkId
      ? { drink_id: line.drinkId }
      : { custom_drink_name: line.name }),
    input_unit: line.unit,
    input_value: Number(line.value),
    volume_precision: line.precision,
    quantity: line.quantity,
    ...(line.servingKey ? { serving_key: line.servingKey } : {}),
  };
}
