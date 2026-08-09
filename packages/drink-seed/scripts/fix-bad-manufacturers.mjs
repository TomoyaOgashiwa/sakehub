#!/usr/bin/env node
/* global console */
/**
 * One-shot corrections for truncated / token manufacturers that slipped
 * into data/drinks (e.g. "No", "Bud", "Gin", "2"). Also syncs matching
 * entries in data/batches.
 */
import { readdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const DRINK_DIR = path.join(ROOT, 'data', 'drinks');
const BATCH_DIR = path.join(ROOT, 'data', 'batches');

/** slug → correct manufacturer */
const BY_SLUG = {
  'no-209-gin': 'Distillery No. 209',
  'bud-light': 'AB InBev',
  'gin-mare': 'Gin Mare',
  '2-towns-brightcider': '2 Towns Ciderhouse',
  '9148-gin-lavender': 'Niigata Kameda Distillery',
  '9148-gin-original': 'Niigata Kameda Distillery',
  'ej-vsop-brandy': 'E&J Gallo',
  'kah-blanco': 'Kah Tequila',
  'sol-cerveza': 'Heineken',
  'tia-maria': 'Illva Saronno',
  umi: '大海酒造',
  maou: '白玉醸造',
  'kuro-isanishiki': '大口酒造',
  'kuro-satsuma': '若潮酒造',
  'kuro-sesen': '西酒造',
  'kuro-shiranami': '薩摩酒造',
  'kura-awamori': '瑞穂酒造',
  'sato-kuro': '鹿児島酒造',
  'sato-mugi': '鹿児島酒造',
  'sato-shiro': '鹿児島酒造',
  'haku-vodka': 'Suntory',
  'skyy-vodka': 'Campari Group',
  'vdka-6100': 'Yamanashi Wine',
  'etsu-gin': '新潟亀田蒸留所',
  'bols-genever': 'Lucas Bols',
  'bols-strawberry': 'Lucas Bols',
  'bols-yogurt': 'Lucas Bols',
  'ocho-anejo': 'Tequila Ocho',
  'ocho-plata': 'Tequila Ocho',
  'ocho-reposado': 'Tequila Ocho',
  'kido-sparkling': '木戸泉酒造',
  'ej-vs-brandy': 'E&J Gallo',
  'f-x-pichler-durnsteiner-kellerberg-riesling-2020': 'F.X. Pichler',
  'original-sin-hard-cider': 'Original Sin',
  'au-bon-climat-santa-barbara-chardonnay-2020': 'Au Bon Climat',
  'don-q-cristal': 'Destilería Serrallés',
  'don-q-gold': 'Destilería Serrallés',
  'don-q-gran-reserva-anejo-xo': 'Destilería Serrallés',
  'ki-no-bi-kyoto-dry-gin': 'The Kyoto Distillery',
  'ki-no-tea-kyoto-dry-gin': 'The Kyoto Distillery',
  'ki-no-tou-old-tom-gin': 'The Kyoto Distillery',
  'lot-no-40-canadian-rye': 'Corby Spirit and Wine',
  'select-aperitivo': 'Gruppo Montenegro',
  'to-ol-gose-to-hollywood': 'To Øl',
};

function describe(d, manufacturer) {
  if (d.category === 'sake' || d.category === 'shochu') {
    return `${d.name}。${manufacturer}の${d.subcategory || d.category}として知られる定番銘柄。`;
  }
  return `${d.nameEn} is a well-known ${d.originCountry} ${d.subcategory || d.category} from ${manufacturer}.`;
}

let drinkFixed = 0;
for (const file of readdirSync(DRINK_DIR).filter((f) => f.endsWith('.json'))) {
  const slug = file.replace(/\.json$/, '');
  const next = BY_SLUG[slug];
  if (!next) continue;
  const filePath = path.join(DRINK_DIR, file);
  const d = JSON.parse(readFileSync(filePath, 'utf8'));
  if (d.manufacturer === next && d.description && !/\bfrom (No|Bud|Gin|2|9148|Kuro|Umi|Maou)\b/.test(d.description)) {
    continue;
  }
  d.manufacturer = next;
  d.description = describe(d, next);
  writeFileSync(filePath, `${JSON.stringify(d, null, 2)}\n`, 'utf8');
  drinkFixed++;
}

let batchFixed = 0;
if (existsSync(BATCH_DIR)) {
  for (const file of readdirSync(BATCH_DIR).filter((f) => f.endsWith('.json'))) {
    const filePath = path.join(BATCH_DIR, file);
    const batch = JSON.parse(readFileSync(filePath, 'utf8'));
    if (!Array.isArray(batch)) continue;
    let changed = false;
    for (const d of batch) {
      const next = BY_SLUG[d.slug];
      if (!next) continue;
      if (d.manufacturer === next) continue;
      d.manufacturer = next;
      d.description = describe(d, next);
      changed = true;
      batchFixed++;
    }
    if (changed) writeFileSync(filePath, `${JSON.stringify(batch, null, 2)}\n`, 'utf8');
  }
}

console.log(`fixed drinks=${drinkFixed}, batch entries=${batchFixed}`);
