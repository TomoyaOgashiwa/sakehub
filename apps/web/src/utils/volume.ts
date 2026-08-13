import type { VolumeUnit } from '@sakehub/types';

/** US fluid ounce in milliliters. */
export const ML_PER_OZ = 29.5735;

/** Ethanol density (g/ml) for pure alcohol mass. */
export const ETHANOL_DENSITY = 0.789;

export function round2(value: number): number {
  return Math.round(value * 100) / 100;
}

export function ozToMl(oz: number): number {
  return round2(oz * ML_PER_OZ);
}

export function mlToOz(ml: number): number {
  return round2(ml / ML_PER_OZ);
}

export function toVolumeMl(unit: VolumeUnit, value: number): number {
  return unit === 'oz' ? ozToMl(value) : round2(value);
}

export function convertVolumeValue(
  value: number,
  from: VolumeUnit,
  to: VolumeUnit,
): number {
  if (from === to) return round2(value);
  if (from === 'ml' && to === 'oz') return mlToOz(value);
  return ozToMl(value);
}

export function pureAlcoholGrams(volumeMl: number, abv: number): number {
  return round2(volumeMl * (abv / 100) * ETHANOL_DENSITY);
}

export function formatVolumeDisplay(
  inputUnit: VolumeUnit,
  inputValue: number,
  volumeMl: number,
): string {
  if (inputUnit === 'oz') {
    return `${round2(inputValue)} oz（${round2(volumeMl)} ml）`;
  }
  return `${round2(volumeMl)} ml`;
}
