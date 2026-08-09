import { readFile } from 'node:fs/promises';

import { seedJsonPath, type CatalogKind } from './paths.ts';

interface DrinkMeta {
  name: string;
  nameEn: string | null;
  category: string;
  subcategory: string | null;
}

interface CocktailMeta {
  name: string;
  nameEn: string | null;
  baseSpirit: string | null;
}

function bottleShapeHint(category: string, subcategory: string | null): string {
  switch (category) {
    case 'sake':
      return 'tall clear Japanese sake bottle with elegant label area';
    case 'whisky':
      return subcategory?.toLowerCase().includes('bourbon')
        ? 'squared bourbon bottle'
        : 'classic whisky bottle with short neck';
    case 'beer':
      return 'beer can or brown beer bottle, product-packaging style';
    case 'wine':
      return 'wine bottle with shoulder and foil capsule';
    case 'gin':
    case 'vodka':
    case 'rum':
    case 'tequila':
    case 'brandy':
    case 'shochu':
      return `tall ${category} bottle`;
    case 'liqueur':
      return 'distinctive liqueur bottle';
    default:
      return 'beverage bottle suitable for the category';
  }
}

function glassHint(slug: string, baseSpirit: string | null): string {
  const s = slug.toLowerCase();
  if (s.includes('martini') || s === 'cosmopolitan' || s === 'espresso-martini') {
    return 'V-shaped martini glass';
  }
  if (s === 'old-fashioned' || s === 'negroni' || s === 'boulevardier' || s === 'penicillin') {
    return 'short rocks / old-fashioned glass with large clear ice';
  }
  if (
    s === 'gin-tonic' ||
    s === 'highball' ||
    s === 'moscow-mule' ||
    s === 'paloma' ||
    s === 'lemon-sour' ||
    s === 'bloody-mary' ||
    s === 'mojito' ||
    s === 'aperol-spritz' ||
    s === 'french-75'
  ) {
    if (s === 'moscow-mule') return 'copper mug';
    if (s === 'aperol-spritz' || s === 'french-75') return 'wine glass or flute with ice';
    return 'tall highball glass with ice';
  }
  if (s === 'margarita' || s === 'daiquiri' || s === 'sidecar' || s === 'whiskey-sour') {
    return 'coupe or rocks cocktail glass';
  }
  if (s === 'pina-colada' || s === 'mai-tai' || s === 'caipirinha') {
    return 'tropical cocktail glass or rocks glass';
  }
  if (baseSpirit?.toLowerCase() === 'champagne') return 'champagne flute';
  return 'appropriate classic cocktail glass';
}

function drinkColorHint(category: string): string {
  switch (category) {
    case 'sake':
      return 'pale clear to slightly golden liquid';
    case 'whisky':
      return 'amber whisky liquid';
    case 'beer':
      return 'golden to dark beer tones matching the style';
    case 'wine':
      return 'wine-appropriate color';
    case 'gin':
    case 'vodka':
      return 'clear spirit';
    case 'rum':
      return 'clear to amber rum';
    case 'tequila':
      return 'clear to soft gold tequila';
    case 'brandy':
      return 'deep amber brandy';
    case 'liqueur':
      return 'rich liqueur color suggested by the product name';
    default:
      return 'natural beverage color';
  }
}

function cocktailColorHint(slug: string): string {
  switch (slug) {
    case 'negroni':
    case 'boulevardier':
    case 'aperol-spritz':
    case 'cosmopolitan':
      return 'red to orange-red drink';
    case 'gin-tonic':
    case 'vodka-martini':
    case 'dry-martini':
    case 'highball':
    case 'lemon-sour':
      return 'clear to pale citrus drink';
    case 'espresso-martini':
      return 'deep brown espresso cocktail with crema foam';
    case 'bloody-mary':
      return 'tomato-red cocktail';
    case 'moscow-mule':
    case 'penicillin':
    case 'whiskey-sour':
    case 'sidecar':
    case 'mai-tai':
      return 'amber to golden cocktail';
    case 'mojito':
    case 'margarita':
    case 'daiquiri':
    case 'paloma':
    case 'french-75':
    case 'caipirinha':
      return 'pale green to clear citrus cocktail';
    case 'pina-colada':
      return 'creamy white tropical cocktail';
    case 'old-fashioned':
    case 'manhattan':
      return 'deep amber cocktail';
    default:
      return 'realistic cocktail color';
  }
}

const SHARED_RULES = [
  'Photorealistic studio product photograph, soft diffused lighting, subtle shadow on a clean seamless light-gray to white background.',
  'Single centered subject, fill most of the frame, no collage, no text overlays, no watermarks, no people, no hands.',
  'No readable brand logos, no trademark text, no legible label copy — abstract or blank label areas only.',
  'Inspired by the named product category, not an exact counterfeit of a real commercial SKU.',
].join(' ');

export async function buildPrompt(kind: CatalogKind, slug: string): Promise<string> {
  const file = seedJsonPath(kind, slug);
  const raw = JSON.parse(await readFile(file, 'utf8')) as Record<string, unknown>;

  if (kind === 'drink') {
    const meta: DrinkMeta = {
      name: String(raw.name ?? slug),
      nameEn: typeof raw.nameEn === 'string' ? raw.nameEn : null,
      category: String(raw.category ?? 'other'),
      subcategory: typeof raw.subcategory === 'string' ? raw.subcategory : null,
    };
    const label = meta.nameEn ? `${meta.name} (${meta.nameEn})` : meta.name;
    return [
      `Catalog hero image for a ${meta.category} product inspired by "${label}".`,
      `Show one ${bottleShapeHint(meta.category, meta.subcategory)} containing ${drinkColorHint(meta.category)}.`,
      SHARED_RULES,
    ].join(' ');
  }

  const meta: CocktailMeta = {
    name: String(raw.name ?? slug),
    nameEn: typeof raw.nameEn === 'string' ? raw.nameEn : null,
    baseSpirit: typeof raw.baseSpirit === 'string' ? raw.baseSpirit : null,
  };
  const label = meta.nameEn ? `${meta.name} (${meta.nameEn})` : meta.name;
  return [
    `Catalog hero image of a finished cocktail inspired by "${label}".`,
    `Serve in a ${glassHint(slug, meta.baseSpirit)} with ${cocktailColorHint(slug)}.`,
    'Minimal classic garnish only; no overcrowded fruit piles.',
    SHARED_RULES,
  ].join(' ');
}
