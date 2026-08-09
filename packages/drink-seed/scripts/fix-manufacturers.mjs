#!/usr/bin/env node
/* global console */
/**
 * Post-process drink JSON manufacturers that were inferred as truncated
 * product names (e.g. "Yamazaki 18", "Aberlour 12") into brand/distillery
 * names. Rewrites description when it embeds the old manufacturer.
 */
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const DRINK_DIR = path.join(ROOT, 'data', 'drinks');

/** Prefix → manufacturer (longest match wins). */
const KNOWN = [
  ['山崎', 'サントリー'],
  ['白州', 'サントリー'],
  ['響', 'サントリー'],
  ['知多', 'サントリー'],
  ['余市', 'ニッカウヰスキー'],
  ['宮城峡', 'ニッカウヰスキー'],
  ['竹鶴', 'ニッカウヰスキー'],
  ['駒ヶ岳', '本坊酒造'],
  ['あかし', '江井ヶ島酒造'],
  ['アマハガン', '長濱蒸留所'],
  ['Yamazaki', 'Suntory'],
  ['Hakushu', 'Suntory'],
  ['Hibiki', 'Suntory'],
  ['Chita', 'Suntory'],
  ['Yoichi', 'Nikka'],
  ['Miyagikyo', 'Nikka'],
  ['Taketsuru', 'Nikka'],
  ['Mars', 'Hombo Shuzo'],
  ['Komagatake', 'Hombo Shuzo'],
  ['Akashi', 'Eigashima Shuzo'],
  ['Amahagan', 'Nagahama Distillery'],
  ["Ichiro's Malt", 'Venture Whisky'],
  // Fuji* は単語境界必須（Fujizakura Heights を Kirin に誤マッチさせない）
  ['Fujizakura', '富士桜高原麦酒'],
  ['富士桜', '富士桜高原麦酒'],
  ['Fuji Gotemba', 'Kirin Distillery'],
  ['Fuji Single', 'Kirin Distillery'],
  ['富士山麓', 'Kirin Distillery'],
  ['富士', 'Kirin Distillery'],
  ['Fuji', 'Kirin Distillery'],
  ['No 209', 'Distillery No. 209'],
  ['Bud Light', 'AB InBev'],
  ['Gin Mare', 'Gin Mare'],
  ['2 Towns', '2 Towns Ciderhouse'],
  ['9148', 'Niigata Kameda Distillery'],
  ['EJ ', 'E&J Gallo'],
  ['Kah ', 'Kah Tequila'],
  ['Sol Cerveza', 'Heineken'],
  ['Tia Maria', 'Illva Saronno'],
  ['魔王', '白玉醸造'],
  ['Maou', '白玉醸造'],
  ['海', '大海酒造'],
  ['Umi', '大海酒造'],
  ['Johnnie Walker', 'Diageo'],
  ['Jack Daniel', 'Brown-Forman'],
  ['Gentleman Jack', 'Brown-Forman'],
  ['Woodford Reserve', 'Brown-Forman'],
  ['Old Forester', 'Brown-Forman'],
  ['The Macallan', 'The Macallan'],
  ['Macallan', 'The Macallan'],
  ['Glenmorangie', 'Glenmorangie'],
  ['Ardbeg', 'Ardbeg'],
  ['Lagavulin', 'Diageo'],
  ['Laphroaig', 'Beam Suntory'],
  ['Talisker', 'Diageo'],
  ['Oban', 'Diageo'],
  ['Dalmore', 'Whyte & Mackay'],
  ['Glenfiddich', 'William Grant & Sons'],
  ['The Balvenie', 'William Grant & Sons'],
  ['The Glenlivet', 'Pernod Ricard'],
  ['Glenlivet', 'Pernod Ricard'],
  ['Aberlour', 'Pernod Ricard'],
  ['The GlenDronach', 'Brown-Forman'],
  ['GlenDronach', 'Brown-Forman'],
  ['BenRiach', 'Brown-Forman'],
  ['Ballantine', 'Pernod Ricard'],
  ['Chivas Regal', 'Pernod Ricard'],
  ['Royal Salute', 'Pernod Ricard'],
  ['Dewar', 'Bacardi'],
  ['Monkey Shoulder', 'William Grant & Sons'],
  ["Maker's Mark", 'Beam Suntory'],
  ['Jim Beam', 'Beam Suntory'],
  ['Knob Creek', 'Beam Suntory'],
  ['Basil Hayden', 'Beam Suntory'],
  ['Booker', "Beam Suntory"],
  ["Blanton's", 'Buffalo Trace'],
  ['Eagle Rare', 'Buffalo Trace'],
  ['Buffalo Trace', 'Buffalo Trace'],
  ['Wild Turkey', 'Campari Group'],
  ['Russell', 'Campari Group'],
  ['Four Roses', 'Kirin'],
  ['Bulleit', 'Diageo'],
  ['Crown Royal', 'Diageo'],
  ['Canadian Club', 'Beam Suntory'],
  ['Jameson', 'Pernod Ricard'],
  ['Tullamore', 'William Grant & Sons'],
  ['Redbreast', 'Pernod Ricard'],
  ['Bushmills', 'Proximo Spirits'],
  ['WhistlePig', 'WhistlePig'],
  ['Amrut', 'Amrut Distilleries'],
  ['Kavalan', 'King Car'],
  ['Suntory', 'Suntory'],
  ['Nikka', 'Nikka'],
  ['Jose Cuervo', 'Jose Cuervo'],
  ['Don Julio', 'Diageo'],
  ['Patron', 'Bacardi'],
  ['Patrón', 'Bacardi'],
  ['Casamigos', 'Diageo'],
  ['Espolon', 'Campari Group'],
  ['Espolòn', 'Campari Group'],
  ['Herradura', 'Brown-Forman'],
  ['Olmeca', 'Pernod Ricard'],
  ['Hennessy', 'LVMH'],
  ['Remy Martin', 'Rémy Cointreau'],
  ['Rémy Martin', 'Rémy Cointreau'],
  ['Martell', 'Pernod Ricard'],
  ['Courvoisier', 'Beam Suntory'],
  ['St Remy', 'Rémy Cointreau'],
  ['St-Remy', 'Rémy Cointreau'],
  ['Laird', "Laird & Company"],
  ['Bombay Sapphire', 'Bacardi'],
  ['Tanqueray', 'Diageo'],
  ['Beefeater', 'Pernod Ricard'],
  ['Gordon', 'Diageo'],
  ['Hendrick', 'William Grant & Sons'],
  ['Roku', 'Suntory'],
  ['Grey Goose', 'Bacardi'],
  ['Absolut', 'Pernod Ricard'],
  ['Smirnoff', 'Diageo'],
  ['Belvedere', 'LVMH'],
  ['Ketel One', 'Diageo'],
  ['Ciroc', 'Diageo'],
  ['Cîroc', 'Diageo'],
  ['Wyborowa', 'Pernod Ricard'],
  ['Bacardi', 'Bacardi'],
  ['Captain Morgan', 'Diageo'],
  ['Havana Club', 'Pernod Ricard'],
  ['Mount Gay', 'Rémy Cointreau'],
  ['Appleton', 'Campari Group'],
  ['Diplomatico', 'Diplomático'],
  ['Diplomático', 'Diplomático'],
  ['Zacapa', 'Diageo'],
  ['Ron Zacapa', 'Diageo'],
  ['Malibu', 'Pernod Ricard'],
  ['Kraken', 'Proximo Spirits'],
  ['Cointreau', 'Rémy Cointreau'],
  ['Grand Marnier', 'Campari Group'],
  ['Baileys', 'Diageo'],
  ['Kahlua', 'Pernod Ricard'],
  ['Kahlúa', 'Pernod Ricard'],
  ['Chambord', 'Brown-Forman'],
  ['Disaronno', 'Illva Saronno'],
  ['Amaretto', 'Illva Saronno'],
  ['Luxardo', 'Luxardo'],
  ['Campari', 'Campari Group'],
  ['Aperol', 'Campari Group'],
  ['Amarula', 'Amarula'],
  ['Hpnotiq', 'Heaven Hill'],
  ['Asahi', 'アサヒビール'],
  ['Kirin', 'キリンビール'],
  ['Sapporo', 'サッポロビール'],
  ['Yebisu', 'サッポロビール'],
  ['Guinness', 'Diageo'],
  ['Heineken', 'Heineken'],
  ['Corona', 'AB InBev'],
  ['Stella Artois', 'AB InBev'],
  ['Budweiser', 'AB InBev'],
  ['Hoegaarden', 'AB InBev'],
  ['Leffe', 'AB InBev'],
  ['Chimay', 'Chimay'],
  ['Orval', 'Orval'],
  ['Duvel', 'Duvel Moortgat'],
  ['BrewDog', 'BrewDog'],
  ['Stone', 'Stone Brewing'],
  ['Somersby', 'Carlsberg'],
  ['Strongbow', 'Heineken'],
  ['42 Below', 'Bacardi'],
  ['1800', 'Proximo Spirits'],
  ['Jager', 'Mast-Jägermeister'],
  ['Jägermeister', 'Mast-Jägermeister'],
  ['Jagermeister', 'Mast-Jägermeister'],
  ['一ノ蔵', '一ノ蔵'],
  ['三和酒類', '三和酒類'],
  ['いいちこ', '三和酒類'],
  ['Iichiko', 'Sanwa Shurui'],
  ['霧島', '霧島酒造'],
  ['Kirishima', 'Kirishima Shuzo'],
  ['黒霧島', '霧島酒造'],
  ['白霧島', '霧島酒造'],
  ['赤霧島', '霧島酒造'],
].sort((a, b) => b[0].length - a[0].length);

/**
 * Brand prefix match with a boundary after the prefix.
 * Prevents `Fuji` matching `Fujizakura`, `Mars` matching `Marshall`, etc.
 * CJK prefixes may be followed by space / middle-dot / end, but not another
 * CJK syllable that continues a longer proper noun unless the prefix itself
 * is the longer entry (longest-first sort handles 富士桜 before 富士).
 */
function matchesBrandPrefix(text, prefix) {
  if (!text || !text.startsWith(prefix)) return false;
  if (text.length === prefix.length) return true;
  const next = text[prefix.length];
  const prefixEndsLatin = /[A-Za-z0-9]$/.test(prefix);
  if (prefixEndsLatin) {
    // Latin brand must end the token: space, hyphen, apostrophe, or EOS.
    return /[\s'’-]/.test(next);
  }
  // CJK / mixed: allow whitespace or middle-dot; block if next continues
  // the same CJK run without separator (富士 + 桜 → need longer prefix entry).
  if (/[\s'’・-]/.test(next)) return true;
  if (/[\u3040-\u30ff\u4e00-\u9fff]/.test(next)) return false;
  return true;
}

const CATEGORY_TOKENS = new Set([
  'Gin',
  'Vodka',
  'Rum',
  'Beer',
  'Wine',
  'Whisky',
  'Whiskey',
  'Tequila',
  'Brandy',
  'Liqueur',
  'Cider',
  'Shochu',
  'Sake',
]);

function looksBad(manufacturer, nameEn, name) {
  if (!manufacturer) return true;
  if (manufacturer === nameEn || manufacturer === name) return true;
  if (CATEGORY_TOKENS.has(manufacturer)) return true;
  // digit-only or leading numeric fragment used as mfr ("2", "9148")
  if (/^\d+$/.test(manufacturer)) return true;
  // extremely short Latin token ("No", "Bud", "Gin") — CJK brewery names are OK
  if (/^[A-Za-z]{1,3}$/.test(manufacturer)) return true;
  // truncated product: "Yamazaki 18", "Aberlour 12", "Wild Turkey 101"
  if (/\b\d+(\.\d+)?\b/.test(manufacturer) && !/&|Brothers|Sons|Group|Distill|Company|Company|Co\.|Ltd|酒造|醸造|Brew/i.test(manufacturer)) {
    return true;
  }
  // first two tokens of product name
  const two = nameEn.split(/\s+/).slice(0, 2).join(' ');
  if (manufacturer === two && /\d/.test(two)) return true;
  return false;
}

function inferManufacturer(nameEn, name) {
  for (const [prefix, mfr] of KNOWN) {
    if (matchesBrandPrefix(nameEn, prefix) || matchesBrandPrefix(name, prefix)) return mfr;
  }
  // Strip common expression suffixes, keep brand head
  const stripped = nameEn
    .replace(/\s+\d+(\.\d+)?(\s*(Year Old|Years?|YO|yr|年.*))?.*$/i, '')
    .replace(
      /\s+(Single Malt|Blended Malt|Blended|Bourbon|Rye|Tennessee|Reserve|Original|Classic|Premium|VSOP|XO|VS|Napoleon|Blanco|Reposado|Anejo|Añejo|Extra Añejo|Cristalino|London Dry|Dry Gin|Vodka|Rum|Cognac|Armagnac|IPA|Lager|Stout|Pilsner|Pale Ale|Wheat|Red|White|Sparkling|Brut|Extra Dry).*$/i,
      '',
    )
    .replace(/\s+(Edition|No\.?\s*\d+|Distiller.?s).*$/i, '')
    .trim();
  if (stripped && stripped !== nameEn && !/\d/.test(stripped)) return stripped;
  // Fall back to first significant token(s), skipping "The"
  const tokens = nameEn.split(/\s+/).filter(Boolean);
  if (tokens[0] === 'The' && tokens.length >= 2) return tokens.slice(0, 2).join(' ');
  return tokens[0] || nameEn;
}

function describe(d, manufacturer) {
  const ja = /[\u3040-\u30ff\u4e00-\u9fff]/.test(d.name);
  if (ja && d.category === 'sake') {
    return `${d.name}。${manufacturer}の${d.subcategory || '日本酒'}として知られる定番銘柄。`;
  }
  return `${d.nameEn} is a well-known ${d.originCountry} ${d.subcategory || d.category} from ${manufacturer}.`;
}

function knownManufacturer(nameEn, name) {
  for (const [prefix, mfr] of KNOWN) {
    if (matchesBrandPrefix(nameEn || '', prefix) || matchesBrandPrefix(name || '', prefix)) {
      return mfr;
    }
  }
  return null;
}

function looksProducty(manufacturer) {
  return /\b(Single|Malt|Reserve|Original|Blended|Year|Distiller|Bourbon|Rye|Gin|Vodka|Rum|VSOP|XO|Blanco|Reposado|Añejo|Cristalino|IPA|Lager|Stout)\b/i.test(
    manufacturer || '',
  );
}

let fixed = 0;
for (const file of readdirSync(DRINK_DIR).filter((f) => f.endsWith('.json')).sort()) {
  const filePath = path.join(DRINK_DIR, file);
  const d = JSON.parse(readFileSync(filePath, 'utf8'));
  const known = knownManufacturer(d.nameEn || '', d.name || '');
  const shouldFix =
    (known && d.manufacturer !== known) ||
    looksBad(d.manufacturer, d.nameEn || '', d.name || '') ||
    looksProducty(d.manufacturer);
  if (!shouldFix) continue;
  const next = known || inferManufacturer(d.nameEn || d.name, d.name || '');
  if (next === d.manufacturer) continue;
  const old = d.manufacturer;
  d.manufacturer = next;
  if (
    !d.description ||
    d.description.includes(String(old)) ||
    /selected for broad drink catalog|is a well-known/.test(d.description)
  ) {
    d.description = describe(d, next);
  }
  writeFileSync(filePath, `${JSON.stringify(d, null, 2)}\n`, 'utf8');
  fixed++;
}
console.log(`fixed manufacturer on ${fixed} drink(s)`);
