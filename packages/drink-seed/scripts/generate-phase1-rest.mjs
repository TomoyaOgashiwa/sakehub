#!/usr/bin/env node
/* global console */
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const BATCH_DIR = path.join(ROOT, 'data', 'batches');
const DRINK_DIR = path.join(ROOT, 'data', 'drinks');
const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

const phase1Counts = {
  whisky: 95,
  beer: 75,
  wine: 76,
  shochu: 58,
  gin: 58,
  vodka: 49,
  rum: 49,
  tequila: 49,
  brandy: 49,
  liqueur: 58,
  other: 39,
};

const phase2Counts = {
  sake: 100,
  whisky: 80,
  beer: 70,
  wine: 70,
  shochu: 40,
  gin: 30,
  vodka: 25,
  rum: 25,
  tequila: 25,
  brandy: 25,
  liqueur: 40,
  other: 20,
};

const protectedExistingSlugs = new Set([
  'yamazaki-12',
  'hibiki-harmony',
  'macallan-12-sherry-oak',
  'makers-mark',
  'jameson',
  'asahi-super-dry',
  'yebisu-premium',
  'sapporo-premium',
  'guinness-draught',
  'brewdog-punk-ipa',
  'grace-koshu',
  'cloudy-bay-sauvignon-blanc',
  'chateau-margaux-2015',
  'opus-one-2020',
  'iichiko-frasco',
  'mori-izo',
  'roku-gin',
  'hendricks-gin',
  'grey-goose',
  'ron-zacapa-23',
  'don-julio-1942',
  'hennessy-xo',
  'baileys-original',
  'kahlua',
  'somersby-apple-cider',
]);

for (const slug of readBatchSlugs('phase1-sake.json')) {
  protectedExistingSlugs.add(slug);
}

const rows = [];

function add(category, defaults, block) {
  for (const rawLine of block.trim().split('\n')) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const [namePart, subcategory, abv, originCountry, manufacturer, aliases] = line.split('|');
    const [nameEn, name = nameEn] = namePart.split('::');
    rows.push({
      nameEn: nameEn.trim(),
      name: name.trim(),
      category,
      subcategory: (subcategory || defaults.subcategory).trim(),
      abv: Number(abv || defaults.abv),
      originCountry: (originCountry || defaults.originCountry).trim(),
      manufacturer: (manufacturer || defaults.manufacturer || inferManufacturer(nameEn)).trim(),
      aliases: aliases ? aliases.split(';').map((alias) => alias.trim()).filter(Boolean) : [],
    });
  }
}

function addVariants(category, defaults, brand, variants) {
  for (const variant of variants) {
    add(category, defaults, `${brand} ${variant}`);
  }
}

function slugify(value) {
  return value
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/&/g, ' and ')
    .replace(/\+/g, ' plus ')
    .replace(/['’]/g, '')
    .replace(/[^a-zA-Z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .toLowerCase();
}

function inferManufacturer(nameEn) {
  const known = [
    ['Johnnie Walker', 'Diageo'],
    ['Jack Daniel', 'Brown-Forman'],
    ['The Macallan', 'The Macallan'],
    ['Glenmorangie', 'Glenmorangie'],
    ['Glenfiddich', 'William Grant & Sons'],
    ['The Glenlivet', 'The Glenlivet Distillery'],
    ['Ballantine', 'Chivas Brothers'],
    ['Chivas Regal', 'Chivas Brothers'],
    ['Dewar', 'Bacardi'],
    ['Jose Cuervo', 'Jose Cuervo'],
    ['Don Julio', 'Diageo'],
    ['Patron', 'Bacardi'],
    ['Hennessy', 'Hennessy'],
    ['Remy Martin', 'Remy Cointreau'],
    ['Martell', 'Martell'],
    ['Courvoisier', 'Courvoisier'],
  ];
  const match = known.find(([prefix]) => nameEn.startsWith(prefix));
  if (match) return match[1];
  return nameEn.split(/\s+/).slice(0, 2).join(' ');
}

function toDrinkSeed(entry) {
  const slug = slugify(entry.nameEn);
  if (!SLUG_PATTERN.test(slug)) {
    throw new Error(`Invalid slug generated for ${entry.nameEn}: ${slug}`);
  }
  return {
    slug,
    name: entry.name,
    nameEn: entry.nameEn,
    category: entry.category,
    subcategory: entry.subcategory,
    description: `${entry.nameEn} is a well-known ${entry.originCountry} ${entry.subcategory} from ${entry.manufacturer}, selected for broad drink catalog coverage in Japan.`,
    imageUrl: null,
    abv: entry.abv,
    originCountry: entry.originCountry,
    manufacturer: entry.manufacturer,
    aliases: entry.aliases,
  };
}

function readBatchSlugs(fileName) {
  const filePath = path.join(BATCH_DIR, fileName);
  if (!existsSync(filePath)) return [];
  const batch = JSON.parse(readFileSync(filePath, 'utf8'));
  return Array.isArray(batch) ? batch.map((drink) => drink.slug).filter(Boolean) : [];
}

function buildCatalog() {
  const catalog = new Map();
  const seen = new Set();
  for (const entry of rows.map(toDrinkSeed)) {
    if (seen.has(entry.slug)) {
      throw new Error(`Duplicate generated slug: ${entry.slug}`);
    }
    if (protectedExistingSlugs.has(entry.slug)) {
      throw new Error(`Generated slug duplicates protected existing seed: ${entry.slug}`);
    }
    seen.add(entry.slug);
    const categoryRows = catalog.get(entry.category) || [];
    categoryRows.push(entry);
    catalog.set(entry.category, categoryRows);
  }
  return catalog;
}

function writeJson(filePath, value) {
  writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
}

function assertEnough(catalog, category, needed) {
  const available = catalog.get(category)?.length || 0;
  if (available < needed) {
    throw new Error(`${category} has ${available} curated rows; need ${needed}`);
  }
}

function countDrinksByCategory() {
  const counts = {};
  for (const entry of readdirSync(DRINK_DIR).filter((file) => file.endsWith('.json'))) {
    const drink = JSON.parse(readFileSync(path.join(DRINK_DIR, entry), 'utf8'));
    counts[drink.category] = (counts[drink.category] || 0) + 1;
  }
  return Object.fromEntries(Object.entries(counts).sort(([a], [b]) => a.localeCompare(b)));
}

// Curated data blocks are appended below. The generator slices them into Phase1/Phase2
// batches so reruns stay deterministic while individual drink files are not overwritten.

add(
  'sake',
  { subcategory: 'Junmai Ginjo', abv: 15, originCountry: 'Japan' },
  String.raw`
Kamoshibito Kuheiji Eau du Desir::醸し人九平次 EAU DU DESIR
Kamoshibito Kuheiji Human::醸し人九平次 human
Kamoshibito Kuheiji Sauvage::醸し人九平次 SAUVAGE
Kaze no Mori Alpha Type 1::風の森 ALPHA TYPE 1
Kaze no Mori Akitsuho 657::風の森 秋津穂657
Kaze no Mori Omachi 807::風の森 雄町807
Kaze no Mori Tsuyuhakaze 507::風の森 露葉風507
Senkin Classic Muku::仙禽 クラシック無垢
Senkin Modern Muku::仙禽 モダン無垢
Senkin Kabutomushi::仙禽 かぶとむし
Senkin Yukidaruma::仙禽 雪だるま
Ohmine 3 Grain Yamadanishiki::大嶺 3粒 山田錦
Ohmine 3 Grain Omachi::大嶺 3粒 雄町
Ohmine 2 Grain Yamadanishiki::大嶺 2粒 山田錦
Mimurosugi Dio Abita::みむろ杉 Dio Abita
Mimurosugi Roman Yamadanishiki::みむろ杉 ろまんシリーズ 山田錦
Mimurosugi Bodaimoto::みむろ杉 菩提もと
Akabu Junmai Ginjo::赤武 純米吟醸
Akabu Junmai Daiginjo::赤武 純米大吟醸
Akabu F Ginjo::赤武 F 吟醸
Sharaku Junmai Ginjo::冩樂 純米吟醸
Sharaku Junmai::冩樂 純米酒
Sharaku Banshu Yamadanishiki::冩樂 播州山田錦
Miyakanbai Junmai Ginjo::宮寒梅 純米吟醸
Miyakanbai Mr Summer Time::宮寒梅 Mr. Summer Time
Miyakanbai Uguisu Saku::宮寒梅 鶯咲
Hououbiden Junmai Ginjo::鳳凰美田 純米吟醸
Hououbiden Black Phoenix::鳳凰美田 Black Phoenix
Hououbiden Heki Ban::鳳凰美田 碧判
Denshu Tokubetsu Junmai::田酒 特別純米酒
Denshu Junmai Daiginjo::田酒 純米大吟醸
Denshu Yamahai Junmai::田酒 山廃純米
Kido Junmai Daiginjo::紀土 純米大吟醸
Kido Junmai Ginjo::紀土 純米吟醸
Kido Karakuchi Junmai::紀土 カラクチキッド 純米
Kido Sparkling::紀土 スパークリング
Mutsu Hassen Red Label::陸奥八仙 赤ラベル
Mutsu Hassen Pink Label::陸奥八仙 ピンクラベル
Mutsu Hassen Isaribi::陸奥八仙 いさり火
Mutsu Hassen Hanaomoi 40::陸奥八仙 華想い40
Takachiyo 59 Omachi::たかちよ59 雄町
Takachiyo 59 Aiyama::たかちよ59 愛山
Takachiyo Custom Made Ipponjime::高千代 CUSTOM MADE 一本〆
Ryusei Tokubetsu Junmai::龍勢 特別純米
Ryusei Black Label::龍勢 黒ラベル
Ryusei Night Emperor::龍勢 夜の帝王
Gozenshu 9 Bodaimoto Junmai::御前酒 9 NINE 菩提もと純米
Gozenshu Junmai Daiginjo Kei::御前酒 純米大吟醸 馨
Gozenshu Bodaimoto Nigori::御前酒 菩提もとにごり
Kudoki Jozu Jr White Beauty::くどき上手 Jr. White Beauty
Kudoki Jozu Banshu Aiyama::くどき上手 播州愛山
Kudoki Jozu Bakuren::くどき上手 ばくれん
Yuki no Bijin Junmai Ginjo::ゆきの美人 純米吟醸
Yuki no Bijin Aiyama Kojimai::ゆきの美人 愛山麹米
Yuki no Bijin Yamadanishiki 6::ゆきの美人 山田錦6号酵母
Akitabare Shunsetsu::秋田晴 酔楽天
Manotsuru Maho::真野鶴 魔法
Manotsuru Karakuchi Tsuru::真野鶴 辛口鶴
Manotsuru Miku::真野鶴 実来
Sogen Samurai King::宗玄 Samurai King
Sogen Junmai Ishikawamon::宗玄 純米 石川門
Sogen Samurai Princess::宗玄 Samurai Princess
Hakutsuru Nishiki Junmai Daiginjo::白鶴錦 純米大吟醸
Hakutsuru Blanc::白鶴 Blanc
Hakutsuru Ukiyoe Junmai::白鶴 浮世絵純米
Kiku-Masamune Taru Sake::菊正宗 樽酒
Kiku-Masamune Koujo Kimoto::菊正宗 嘉宝蔵 生もと
Kiku-Masamune Shiboritate Gin Pack::菊正宗 しぼりたてギンパック
Kenbishi Zuisho::剣菱 瑞祥
Sawanotsuru Nada Jikomi::沢の鶴 灘仕込
Sawanotsuru Josen Honjozo::沢の鶴 上撰本醸造
Tatsuriki Kome no Sasayaki::龍力 米のささやき
Tatsuriki Yamadanishiki Tokubetsu Junmai::龍力 山田錦 特別純米
Chiyonosono Shared Promise::千代の園 Shared Promise
Chiyonosono Excel::千代の園 エクセル
Tedorigawa Kinka::手取川 吉田蔵u Kinka
Tedorigawa U Hyakumangoku::手取川 吉田蔵u 百万石乃白
Tedorigawa Shukon Junmai Ginjo::手取川 酒魂 純米吟醸
Kagatobi Yamahai Junmai::加賀鳶 山廃純米
Fukumitsuya Kuro Obi Do Do::黒帯 堂々 山廃純米
Fukumitsuya Kagatobi Gokkan Junmai::加賀鳶 極寒純米
Masumi Shiro::真澄 白妙 SHIRO
Masumi Kaya::真澄 茅色 KAYA
Masumi Origarami::真澄 うすにごり
Dewazakura Oka Ginjo::出羽桜 桜花吟醸酒
Dewazakura Ichiro::出羽桜 一路
Dewazakura Yukimegami 48::出羽桜 雪女神 四割八分
Gassan Izumo Junmai Ginjo::月山 出雲 純米吟醸
Gassan Houjun Karakuchi Junmai::月山 芳醇辛口純米
Otokoyama Kimoto Junmai::男山 生もと純米
Otokoyama Hokkaido Limited Junmai::男山 北海道限定純米
Kikusui Funaguchi::菊水 ふなぐち一番しぼり
Kikusui Junmai Ginjo::菊水 純米吟醸
Kikusui Karakuchi::菊水 辛口
Rihaku Wandering Poet::李白 Wandering Poet
Rihaku Dreamy Clouds::李白 Dreamy Clouds
Toko Ultraluxe Junmai Daiginjo::東光 ウルトラリュクス
Toko Ginga Shizuku::東光 洌 銀河雫
Kuzuryu Ippin::九頭龍 逸品
Kuzuryu Junmai::九頭龍 純米
  `,
);

add(
  'whisky',
  { subcategory: 'Single Malt', abv: 43, originCountry: 'Japan' },
  String.raw`
Yamazaki Distiller's Reserve::山崎 Distiller's Reserve
Yamazaki 18 Year Old::山崎 18年
Yamazaki 25 Year Old::山崎 25年
Hakushu Distiller's Reserve::白州 Distiller's Reserve
Hakushu 12 Year Old::白州 12年
Hakushu 18 Year Old::白州 18年
The Chita Single Grain::知多|Single Grain
Hibiki Blender's Choice::響 Blender's Choice|Blended
Hibiki Japanese Harmony Master's Select::響 Japanese Harmony Master's Select|Blended
Hibiki 17 Year Old::響 17年|Blended
Hibiki 21 Year Old::響 21年|Blended
Suntory Whisky Toki::サントリーウイスキー 季|Blended
Suntory World Whisky Ao::碧 Ao|Blended
Nikka From The Barrel::ニッカ フロム・ザ・バレル|Blended|51.4
Taketsuru Pure Malt::竹鶴 ピュアモルト|Blended Malt
Taketsuru 17 Year Old::竹鶴 17年|Blended Malt
Yoichi Single Malt::余市 シングルモルト|Single Malt|45
Miyagikyo Single Malt::宮城峡 シングルモルト|Single Malt|45
Nikka Coffey Grain::ニッカ カフェグレーン|Single Grain|45
Nikka Coffey Malt::ニッカ カフェモルト|Malt Whisky|45
Nikka Session::ニッカ セッション|Blended Malt
Fuji Single Grain::富士 シングルグレーン|Single Grain|46
Fuji Single Malt::富士 シングルモルト|Single Malt|46
Fuji Gotemba Signature Blend::富士山麓 Signature Blend|Blended|50
Mars Komagatake Single Malt::駒ヶ岳 シングルモルト|Single Malt|48
Mars Iwai Tradition::マルス 岩井トラディション|Blended|40
Mars Tsunuki Single Malt::津貫 シングルモルト|Single Malt|50
Akashi White Oak Blended::あかし ホワイトオーク|Blended|40
Akashi Single Malt::あかし シングルモルト|Single Malt|46
Ichiro's Malt Malt and Grain::イチローズモルト モルト＆グレーン|World Blended|46.5
Ichiro's Malt Wine Wood Reserve::イチローズモルト ワインウッドリザーブ|Blended Malt|46
Ichiro's Malt Mizunara Wood Reserve::イチローズモルト ミズナラウッドリザーブ|Blended Malt|46
Ichiro's Malt Double Distilleries::イチローズモルト ダブルディスティラリーズ|Blended Malt|46
Kanosuke Single Malt::嘉之助 シングルモルト|Single Malt|48
Kanosuke HIOKI Pot Still::嘉之助 HIOKI POT STILL|Single Grain|51
Sakurao Single Malt::桜尾 シングルモルト
Togouchi Premium Blended::戸河内 Premium|Blended|40
Amahagan World Malt Edition No 1::アマハガン ワールドモルト Edition No.1|World Blended Malt|47
  `,
);

add(
  'whisky',
  { subcategory: 'Single Malt', abv: 40, originCountry: 'Scotland' },
  String.raw`
Glenfiddich 12 Year Old
Glenfiddich 15 Year Old Solera
Glenfiddich 18 Year Old
The Glenlivet 12 Year Old
The Glenlivet 15 Year Old French Oak
The Glenlivet 18 Year Old
The Macallan Double Cask 12 Year Old
The Macallan Double Cask 15 Year Old
The Macallan 18 Year Old Sherry Oak|Single Malt|43
The Balvenie DoubleWood 12 Year Old
The Balvenie Caribbean Cask 14 Year Old|Single Malt|43
The Balvenie PortWood 21 Year Old
Laphroaig 10 Year Old
Laphroaig Quarter Cask|Single Malt|48
Laphroaig Lore|Single Malt|48
Ardbeg 10 Year Old|Single Malt|46
Ardbeg Uigeadail|Single Malt|54.2
Ardbeg An Oa|Single Malt|46.6
Ardbeg Corryvreckan|Single Malt|57.1
Lagavulin 16 Year Old|Single Malt|43
Talisker 10 Year Old|Single Malt|45.8
Talisker Storm|Single Malt|45.8
Talisker 18 Year Old|Single Malt|45.8
Oban 14 Year Old|Single Malt|43
Dalwhinnie 15 Year Old|Single Malt|43
Glenmorangie Original 10 Year Old
Glenmorangie Lasanta 12 Year Old|Single Malt|43
Glenmorangie Quinta Ruban 14 Year Old|Single Malt|46
Glenmorangie Nectar d'Or|Single Malt|46
Highland Park 12 Year Old Viking Honour
Highland Park 18 Year Old Viking Pride|Single Malt|43
Bowmore 12 Year Old
Bowmore 15 Year Old|Single Malt|43
Bruichladdich The Classic Laddie|Single Malt|50
Port Charlotte 10 Year Old|Single Malt|50
Springbank 10 Year Old|Single Malt|46
Springbank 15 Year Old|Single Malt|46
Kilkerran 12 Year Old|Single Malt|46
Arran 10 Year Old|Single Malt|46
Aberlour 12 Year Old
Aberlour A'bunadh|Single Malt|61.2
BenRiach The Original Ten|Single Malt|43
Deanston 12 Year Old|Single Malt|46.3
Bunnahabhain 12 Year Old|Single Malt|46.3
The GlenDronach Original 12 Year Old|Single Malt|43
The GlenDronach Revival 15 Year Old|Single Malt|46
The GlenDronach Allardice 18 Year Old|Single Malt|46
Caol Ila 12 Year Old|Single Malt|43
Clynelish 14 Year Old|Single Malt|46
Old Pulteney 12 Year Old
Royal Lochnagar 12 Year Old
Benromach 10 Year Old|Single Malt|43
Craigellachie 13 Year Old|Single Malt|46
  `,
);

add(
  'whisky',
  { subcategory: 'Blended', abv: 40, originCountry: 'Scotland' },
  String.raw`
Johnnie Walker Red Label
Johnnie Walker Black Label
Johnnie Walker Double Black
Johnnie Walker Green Label 15 Year Old|Blended Malt|43
Johnnie Walker Gold Label Reserve
Johnnie Walker Blue Label
Chivas Regal 12 Year Old
Chivas Regal Mizunara
Chivas Regal 18 Year Old
Ballantine's Finest
Ballantine's 17 Year Old
Ballantine's 21 Year Old
Dewar's White Label
Dewar's 12 Year Old
Dewar's 15 Year Old
The Famous Grouse
Monkey Shoulder|Blended Malt
Compass Box Peat Monster|Blended Malt|46
Compass Box Spice Tree|Blended Malt|46
Compass Box Orchard House|Blended Malt|46
  `,
);

add(
  'whisky',
  { subcategory: 'Bourbon', abv: 45, originCountry: 'United States' },
  String.raw`
Buffalo Trace Kentucky Straight Bourbon|Bourbon|40
Woodford Reserve Distiller's Select|Bourbon|43.2
Wild Turkey 101 Bourbon|Bourbon|50.5
Wild Turkey Rare Breed|Bourbon|58.4
Jim Beam White Label|Bourbon|40
Jim Beam Black Extra Aged|Bourbon|43
Four Roses Small Batch
Four Roses Single Barrel|Bourbon|50
Knob Creek 9 Year Old Bourbon|Bourbon|50
Bulleit Bourbon
Bulleit Rye|Rye
Eagle Rare 10 Year Old
Blanton's Original Single Barrel|Bourbon|46.5
Elijah Craig Small Batch|Bourbon|47
Evan Williams Black Label|Bourbon|43
Jack Daniel's Old No 7|Tennessee|40
Jack Daniel's Gentleman Jack|Tennessee|40
Jack Daniel's Single Barrel Select|Tennessee|47
Rittenhouse Rye|Rye|50
Sazerac Rye|Rye
Michter's US1 Bourbon|Bourbon|45.7
Michter's US1 Rye|Rye|42.4
WhistlePig 10 Year Old Rye|Rye|50
Maker's Mark 46|Bourbon|47
Old Forester 86 Proof|Bourbon|43
Old Forester 1920 Prohibition Style|Bourbon|57.5
George Dickel No 12|Tennessee
Heaven Hill Bottled in Bond 7 Year Old|Bourbon|50
  `,
);

add(
  'whisky',
  { subcategory: 'Single Malt', abv: 43, originCountry: 'Ireland' },
  String.raw`
Redbreast 12 Year Old|Single Pot Still|40
Redbreast 15 Year Old|Single Pot Still|46
Green Spot|Single Pot Still|40
Bushmills 10 Year Old|Single Malt|40
Bushmills Black Bush|Blended|40
Teeling Small Batch|Blended|46
Tullamore D.E.W. Original|Blended|40
Powers Gold Label|Blended|43.2
Crown Royal Deluxe|Canadian|40|Canada
Canadian Club 12 Year Old|Canadian|40|Canada
Lot No 40 Canadian Rye|Rye|43|Canada
Kavalan Classic Single Malt|Single Malt|40|Taiwan
Kavalan Solist Vinho Barrique|Single Malt|57.8|Taiwan
Kavalan Concertmaster Port Cask Finish|Single Malt|40|Taiwan
Amrut Fusion|Single Malt|50|India
Paul John Edited|Single Malt|46|India
Rampur Select|Single Malt|43|India
Penderyn Madeira Finish|Single Malt|46|Wales
Starward Nova|Single Malt|41|Australia
Starward Two-Fold|Double Grain|40|Australia
  `,
);

add(
  'whisky',
  { subcategory: 'Single Malt', abv: 46, originCountry: 'Scotland' },
  String.raw`
Glen Scotia Double Cask
Glen Scotia 15 Year Old
Ledaig 10 Year Old
Tobermory 12 Year Old
Kilchoman Machir Bay
Kilchoman Sanaig
Tomatin 12 Year Old|Single Malt|43
Tomatin 18 Year Old
GlenAllachie 12 Year Old
GlenAllachie 15 Year Old
Glen Grant 10 Year Old|Single Malt|40
Glen Grant 18 Year Old|Single Malt|43
Balblair 12 Year Old
Balblair 15 Year Old
Ben Nevis 10 Year Old
Glengoyne 10 Year Old|Single Malt|40
Glengoyne 18 Year Old|Single Malt|43
Tamdhu 12 Year Old|Single Malt|43
Tamdhu 15 Year Old
Auchentoshan Three Wood|Single Malt|43
Auchentoshan 12 Year Old|Single Malt|40
  `,
);

add(
  'beer',
  { subcategory: 'Lager', abv: 5, originCountry: 'Japan' },
  String.raw`
Asahi Maruef::アサヒ生ビール マルエフ|Lager|4.5
Asahi Black::アサヒ 黒生|Dark Lager|5
Kirin Ichiban Shibori::キリン 一番搾り
Kirin Lager Beer::キリン ラガービール
Kirin Classic Lager::キリン クラシックラガー|Lager|4.5
Kirin Heartland::ハートランドビール
Kirin Spring Valley Hojun 496::SPRING VALLEY 豊潤496|IPL|6
Kirin Spring Valley Silk Ale::SPRING VALLEY シルクエール|White Ale|5.5
Sapporo Black Label::サッポロ生ビール黒ラベル
Sapporo Classic::サッポロクラシック
Sapporo Lager Beer Akaboshi::サッポロラガービール 赤星
Yebisu Meister::ヱビス マイスター|Lager|5.5
Yebisu Premium Black::ヱビス プレミアムブラック|Dark Lager|5
The Premium Malt's::ザ・プレミアム・モルツ|Pilsner|5.5
The Premium Malt's Kaoru Ale::ザ・プレミアム・モルツ 香るエール|Ale|6
Tokyo Craft Pale Ale::東京クラフト ペールエール|Pale Ale|5
Orion The Draft::オリオン ザ・ドラフト
Orion 75 Beer IPA::オリオン 75BEER IPA|IPA|6
Hitachino Nest White Ale::常陸野ネスト ホワイトエール|Witbier|5.5
Hitachino Nest Red Rice Ale::常陸野ネスト レッドライスエール|Specialty Ale|7
Hitachino Nest Japanese Classic Ale::常陸野ネスト ジャパニーズクラシックエール|Pale Ale|7
Yona Yona Ale::よなよなエール|Pale Ale|5.5
India No Aooni::インドの青鬼|IPA|7
Suiyoubi No Neko::水曜日のネコ|Belgian White|5
Boku Beer Kimi Beer::僕ビール君ビール|Saison|4.5
Coedo Shiro::COEDO 白|Hefeweizen|5.5
Coedo Ruri::COEDO 瑠璃|Pilsner|5
Coedo Kyara::COEDO 伽羅|IPL|5.5
Coedo Beniaka::COEDO 紅赤|Imperial Amber|7
Baird Rising Sun Pale Ale::ベアード ライジングサン ペールエール|Pale Ale|5.5
Baird Suruga Bay Imperial IPA::ベアード 駿河ベイ インペリアルIPA|IPA|8
Shiga Kogen IPA::志賀高原 IPA|IPA|6
Shiga Kogen Miyama Blonde::志賀高原 みやまブロンド|Saison|6.5
Fujizakura Heights Weizen::富士桜高原麦酒 ヴァイツェン|Weizen|5.5
Minoh W-IPA::箕面ビール W-IPA|Double IPA|9
Minoh Stout::箕面ビール スタウト|Stout|5.5
Kyoto Brewing Ichigo Ichie::京都醸造 一期一会|Saison|5.5
Far Yeast Tokyo White::Far Yeast 東京ホワイト|Saison|5
Far Yeast Tokyo IPA::Far Yeast 東京IPA|IPA|6
  `,
);

add(
  'beer',
  { subcategory: 'Lager', abv: 5, originCountry: 'United States' },
  String.raw`
Budweiser
Bud Light|Light Lager|4.2
Coors Light|Light Lager|4.2
Miller Lite|Light Lager|4.2
Pabst Blue Ribbon|Lager|4.8
Samuel Adams Boston Lager
Anchor Steam Beer|California Common|4.9
Blue Moon Belgian White|Witbier|5.4
Sierra Nevada Pale Ale|Pale Ale|5.6
Sierra Nevada Torpedo Extra IPA|IPA|7.2
Sierra Nevada Hazy Little Thing|Hazy IPA|6.7
Lagunitas IPA|IPA|6.2
Stone IPA|IPA|6.9
Stone Delicious IPA|IPA|7.7
Goose Island IPA|IPA|5.9
Goose Island Bourbon County Stout|Imperial Stout|14.7
Founders All Day IPA|Session IPA|4.7
Founders Breakfast Stout|Imperial Stout|8.3
Bell's Two Hearted Ale|IPA|7
New Belgium Fat Tire|Amber Ale|5.2
New Belgium Voodoo Ranger IPA|IPA|7
Deschutes Fresh Squeezed IPA|IPA|6.4
Deschutes Black Butte Porter|Porter|5.5
Firestone Walker Union Jack IPA|IPA|7
Dogfish Head 60 Minute IPA|IPA|6
Allagash White|Witbier|5.2
Brooklyn Lager|Lager|5.2
Brooklyn East IPA|IPA|6.9
Oskar Blues Dale's Pale Ale|Pale Ale|6.5
Left Hand Milk Stout Nitro|Milk Stout|6
Modern Times Orderville|Hazy IPA|7.2
Ballast Point Sculpin IPA|IPA|7
Russian River Pliny the Elder|Double IPA|8
Tree House Julius|Hazy IPA|6.8
The Alchemist Heady Topper|Double IPA|8
Lawson's Sip of Sunshine|IPA|8
Trillium Fort Point Pale Ale|Pale Ale|6.6
Other Half Green City|IPA|7
  `,
);

add(
  'beer',
  { subcategory: 'Pilsner', abv: 5, originCountry: 'Belgium' },
  String.raw`
Heineken|Lager|5|Netherlands
Amstel Lager|Lager|5|Netherlands
Corona Extra|Lager|4.5|Mexico
Modelo Especial|Lager|4.4|Mexico
Negra Modelo|Dark Lager|5.4|Mexico
Pacifico Clara|Lager|4.5|Mexico
Dos Equis Lager Especial|Lager|4.2|Mexico
Sol Cerveza|Lager|4.5|Mexico
Pilsner Urquell|Pilsner|4.4|Czech Republic
Budvar Original Czech Lager|Lager|5|Czech Republic
Stella Artois|Pilsner|5
Hoegaarden White|Witbier|4.9
Leffe Blonde|Belgian Blonde|6.6
Leffe Brune|Dubbel|6.5
Chimay Blue|Belgian Strong Ale|9
Chimay Red|Dubbel|7
Chimay White|Tripel|8
Duvel|Belgian Strong Ale|8.5
Delirium Tremens|Belgian Strong Ale|8.5
Westmalle Dubbel|Dubbel|7
Westmalle Tripel|Tripel|9.5
Rochefort 10|Quadrupel|11.3
Orval|Belgian Pale Ale|6.2
Weihenstephaner Hefeweissbier|Hefeweizen|5.4|Germany
Paulaner Hefe-Weissbier Naturtrub|Hefeweizen|5.5|Germany
Erdinger Weissbier|Hefeweizen|5.3|Germany
Franziskaner Hefe-Weissbier|Hefeweizen|5|Germany
Augustiner Lagerbier Hell|Helles|5.2|Germany
Warsteiner Premium Verum|Pilsner|4.8|Germany
Bitburger Premium Pils|Pilsner|4.8|Germany
Beck's|Pilsner|4.9|Germany
Carlsberg Danish Pilsner|Pilsner|5|Denmark
Tuborg Green|Pilsner|4.6|Denmark
Peroni Nastro Azzurro|Pilsner|5.1|Italy
Birra Moretti|Lager|4.6|Italy
Guinness Extra Stout|Stout|5.6|Ireland
Guinness Foreign Extra Stout|Stout|7.5|Ireland
Murphy's Irish Stout|Stout|4|Ireland
Kilkenny Irish Cream Ale|Cream Ale|4.3|Ireland
Newcastle Brown Ale|Brown Ale|4.7|England
Samuel Smith Oatmeal Stout|Stout|5|England
Fuller's London Pride|Bitter|4.7|England
Fuller's ESB|Bitter|5.9|England
Camden Hells Lager|Helles|4.6|England
BrewDog Elvis Juice|IPA|6.5|Scotland
BrewDog Hazy Jane|Hazy IPA|5|Scotland
Cloudwater DIPA|Double IPA|8|England
Mikkeller Beer Geek Breakfast|Imperial Stout|7.5|Denmark
To Ol Gose To Hollywood|Gose|3.8|Denmark
Omnipollo Nebuchadnezzar|Double IPA|8.5|Sweden
Garage Beer Soup IPA|IPA|6|Spain
Estrella Damm|Lager|5.4|Spain
Mahou Cinco Estrellas|Lager|5.5|Spain
San Miguel Pale Pilsen|Pale Lager|5|Philippines
Tsingtao Beer|Lager|4.7|China
Singha|Lager|5|Thailand
Chang Classic|Lager|5|Thailand
Tiger Beer|Lager|5|Singapore
Bintang Pilsener|Pilsner|4.7|Indonesia
Saigon Special|Lager|4.9|Vietnam
Beerlao Lager|Lager|5|Laos
Kingfisher Premium Lager|Lager|4.8|India
Coopers Original Pale Ale|Pale Ale|4.5|Australia
Victoria Bitter|Lager|4.9|Australia
Little Creatures Pale Ale|Pale Ale|5.2|Australia
Steinlager Classic|Lager|5|New Zealand
Quilmes Cristal|Lager|4.9|Argentina
Presidente Pilsener|Pilsner|5|Dominican Republic
Red Stripe|Lager|4.7|Jamaica
  `,
);

add(
  'wine',
  { subcategory: 'White', abv: 12.5, originCountry: 'Japan' },
  String.raw`
Grace Gris de Koshu::グレイス グリド甲州
Katsunuma Jozo Koshu Terroir Selection::勝沼醸造 甲州テロワールセレクション
Chateau Mercian Koshu Kiiroka::シャトー・メルシャン 甲州きいろ香
Suntory Tomi No Oka Koshu::登美の丘 甲州
Lumiere Koshu Sur Lie::ルミエール 甲州シュールリー
Coco Farm Noumin Dry::ココ・ファーム 農民ドライ
Kurambon Koshu Sur Lie::くらむぼん 甲州シュールリー
Sogga Pere et Fils Ordinaire Merlot Cabernet::小布施ワイナリー オーディネール メルロ カベルネ|Red|13
Beau Paysage Tsugane La Montagne::ボー・ペイサージュ ツガネ ラ・モンターニュ|Red|12.5
  `,
);

add(
  'wine',
  { subcategory: 'Red', abv: 13.5, originCountry: 'France' },
  String.raw`
Chateau Lafite Rothschild 2018
Chateau Latour 2015
Chateau Mouton Rothschild 2018
Chateau Haut-Brion 2016
Chateau Cheval Blanc 2016|Red|14
Petrus 2018|Red|14.5
Chateau Ausone 2016|Red|14
Chateau Leoville Las Cases 2016
Chateau Pontet-Canet 2016
Chateau Lynch-Bages 2016
Chateau Palmer 2016
Chateau Cos d'Estournel 2016|Red|14
Chateau Montrose 2016
Chateau Pichon Baron 2016
Chateau Pichon Longueville Comtesse de Lalande 2016
Chateau Ducru-Beaucaillou 2016
Domaine de la Romanee-Conti Romanee-Conti 2019
Domaine de la Romanee-Conti La Tache 2019
Armand Rousseau Chambertin Grand Cru 2019
Domaine Leroy Bourgogne Rouge 2018
Joseph Drouhin Beaune Clos des Mouches Rouge 2019
Louis Jadot Pommard 2019
Bouchard Pere et Fils Meursault Les Clous 2020|White
William Fevre Chablis Premier Cru Vaulorent 2020|White|13
Louis Latour Corton-Charlemagne Grand Cru 2019|White
Jacques Prieur Montrachet Grand Cru 2019|White
E Guigal Cote Rotie Brune et Blonde 2018
E Guigal Condrieu La Doriane 2020|White|14
Chateau de Beaucastel Chateauneuf du Pape Rouge 2019|Red|14.5
Clos des Papes Chateauneuf du Pape Rouge 2019|Red|15
Trimbach Riesling Cuvee Frederic Emile 2016|White|13
Zind-Humbrecht Gewurztraminer Herrenweg 2018|White
Dom Perignon 2013|Sparkling|12.5
Krug Grande Cuvee|Sparkling|12.5
Moet et Chandon Brut Imperial|Sparkling|12
Veuve Clicquot Yellow Label Brut|Sparkling|12
Bollinger Special Cuvee|Sparkling|12
Louis Roederer Collection|Sparkling|12
Louis Roederer Cristal 2015|Sparkling|12
Taittinger Comtes de Champagne 2012|Sparkling|12.5
Laurent-Perrier La Cuvee Brut|Sparkling|12
Ruinart Blanc de Blancs|Sparkling|12.5
Billecart-Salmon Brut Rose|Sparkling|12
Perrier-Jouet Belle Epoque 2014|Sparkling|12.5
  `,
);

add(
  'wine',
  { subcategory: 'Red', abv: 14, originCountry: 'Italy' },
  String.raw`
Antinori Tignanello 2020
Antinori Solaia 2019
Tenuta San Guido Sassicaia 2020
Ornellaia Bolgheri Superiore 2020|Red|14.5
Masseto 2019|Red|15
Gaja Barbaresco 2019
Gaja Darmagi 2019
Vietti Barolo Castiglione 2019|Red|14.5
Giuseppe Rinaldi Barolo Brunate 2018|Red|14.5
Biondi-Santi Brunello di Montalcino 2017|Red|13.5
Castello Banfi Brunello di Montalcino 2018
Allegrini Amarone della Valpolicella Classico 2018|Red|15.5
Planeta Chardonnay Sicilia 2020|White|13.5
Santa Margherita Pinot Grigio|White|12.5
Mionetto Prosecco Brut|Sparkling|11
  `,
);

add(
  'wine',
  { subcategory: 'Red', abv: 14, originCountry: 'Spain' },
  String.raw`
Vega Sicilia Unico 2012
Vega Sicilia Valbuena 5 2018
Pingus 2019|Red|14.5
Alvaro Palacios L'Ermita 2019|Red|14.5
Marques de Riscal Reserva 2018
La Rioja Alta Vina Ardanza Reserva 2016|Red|14.5
Torres Mas La Plana 2018|Red|14.5
Gramona Imperial Brut Corpinnat|Sparkling|12
Taylor Fladgate 20 Year Old Tawny Port|Fortified|20|Portugal
Graham's Six Grapes Reserve Port|Fortified|20|Portugal
Niepoort Redoma Branco 2020|White|12.5|Portugal
Quinta do Crasto Reserva Old Vines 2019|Red|14.5|Portugal
Egon Muller Scharzhofberger Riesling Kabinett 2020|White|8.5|Germany
Dr Loosen Erdener Treppchen Riesling Kabinett 2020|White|8|Germany
Joh Jos Prum Wehlener Sonnenuhr Spatlese 2020|White|8|Germany
Fritz Haag Brauneberger Juffer Riesling Kabinett 2020|White|8|Germany
  `,
);

add(
  'wine',
  { subcategory: 'Red', abv: 14.5, originCountry: 'Australia' },
  String.raw`
Penfolds Grange 2018
Penfolds Bin 389 Cabernet Shiraz 2020
Henschke Hill of Grace 2017
Torbreck The Struie 2020|Red|15
Mollydooker The Boxer Shiraz 2021|Red|16
Leeuwin Estate Art Series Chardonnay 2020|White|13.5
Yellow Tail Chardonnay|White|13
Yellow Tail Shiraz|Red|13.5
Cloudy Bay Te Koko Sauvignon Blanc 2019|White|13.5|New Zealand
Villa Maria Private Bin Sauvignon Blanc|White|13|New Zealand
Felton Road Bannockburn Pinot Noir 2020|Red|14|New Zealand
Craggy Range Te Muna Sauvignon Blanc 2021|White|13|New Zealand
  `,
);

add(
  'wine',
  { subcategory: 'Red', abv: 14.5, originCountry: 'United States' },
  String.raw`
Screaming Eagle Cabernet Sauvignon 2019
Dominus Estate 2019
Caymus Cabernet Sauvignon 2021
Silver Oak Alexander Valley Cabernet Sauvignon 2019
Ridge Monte Bello 2019|Red|13.5
Duckhorn Napa Valley Merlot 2019
Au Bon Climat Santa Barbara Chardonnay 2020|White|13.5
Rombauer Carneros Chardonnay 2020
Kistler Les Noisetiers Chardonnay 2020|White|14.1
Cakebread Cellars Chardonnay 2020|White|14.1
Stag's Leap Wine Cellars Artemis Cabernet Sauvignon 2019
Chateau Ste Michelle Riesling|White|12
Kendall-Jackson Vintner's Reserve Chardonnay|White|13.5
Robert Mondavi Napa Valley Cabernet Sauvignon 2019
The Prisoner Red Blend 2021|Red|15.2
Meiomi Pinot Noir 2021|Red|13.7
Concha y Toro Don Melchor 2019|Red|14.5|Chile
Almaviva 2020|Red|14.5|Chile
Montes Alpha M Cabernet Sauvignon 2019|Red|14.5|Chile
Casillero del Diablo Cabernet Sauvignon|Red|13.5|Chile
Catena Zapata Adrianna Vineyard Mundus Bacillus Terrae 2019|Red|14|Argentina
Catena Alta Malbec 2019|Red|13.5|Argentina
Trapiche Terroir Series Malbec 2018|Red|14|Argentina
Zuccardi Concreto Malbec 2020|Red|14|Argentina
  `,
);

add(
  'wine',
  { subcategory: 'White', abv: 13, originCountry: 'Austria' },
  String.raw`
F X Pichler Durnsteiner Kellerberg Riesling 2020
Nikolaihof Vinothek Riesling 2002
Domane Wachau Gruner Veltliner Federspiel Terrassen
Brundlmayer Gruner Veltliner Kamptaler Terrassen
Loimer Lois Gruner Veltliner
Marcel Deiss Alsace Blanc 2020|White|13|France
Domaine Weinbach Riesling Cuvee Theo 2020|White|13|France
Clos Ste Magdeleine Cassis Blanc 2020|White|13|France
Domaines Ott Chateau de Selle Rose 2020|Rose|13|France
Chateau d'Esclans Whispering Angel Rose|Rose|13|France
Miraval Rose Cotes de Provence|Rose|13|France
Domaine Tempier Bandol Rouge 2019|Red|14|France
Domaine Tempier Bandol Rose 2020|Rose|13|France
Chateau Musar Red 2017|Red|14|Lebanon
Chateau Musar White 2016|White|12|Lebanon
Klein Constantia Vin de Constance 2018|Dessert|14|South Africa
Kanonkop Pinotage 2019|Red|14|South Africa
Hamilton Russell Chardonnay 2020|White|13.5|South Africa
Sadie Family Columella 2019|Red|14|South Africa
Nederburg The Winemasters Chenin Blanc|White|13|South Africa
Clos Mogador Priorat 2019|Red|14.5|Spain
El Nido Clio 2019|Red|15|Spain
Tyrrell's Vat 1 Semillon 2016|White|11.5|Australia
Yalumba The Signature Cabernet Shiraz 2018|Red|14|Australia
Chacra Treinta y Dos Pinot Noir 2019|Red|13.5|Argentina
Seghesio Sonoma Zinfandel 2020|Red|14.8|United States
  `,
);

add(
  'shochu',
  { subcategory: 'Imo', abv: 25, originCountry: 'Japan' },
  String.raw`
Iichiko Silhouette::いいちこ シルエット|Mugi
Iichiko Special::いいちこ スペシャル|Mugi|30
Iichiko Seirin::いいちこ 清凛|Mugi
Nikaido Mugi::二階堂 麦焼酎|Mugi
Nikaido Kitchomu::吉四六|Mugi
Kanoka Mugi::麦焼酎 かのか|Mugi
Kannoko::神の河|Mugi
Ginza Suzume Kohaku::銀座のすずめ 琥珀|Mugi
Hyakunen no Kodoku::百年の孤独|Mugi|40
Nakanaka::中々|Mugi
Yamaneko::山ねこ|Imo
Yamazaru::山猿|Mugi
Kuro Kirishima::黒霧島
Aka Kirishima::赤霧島
Shiro Kirishima::白霧島
Akane Kirishima::茜霧島
Kuro Kirishima EX::黒霧島EX
Satsuma Shiranami::さつま白波
Kuro Shiranami::黒白波
Murao::村尾
Maou::魔王
Isami::伊佐美
Tomino Hozan::富乃宝山
Kiccho Hozan::吉兆宝山
Shiroten Hozan::白天宝山
Sato Kuro::佐藤 黒
Sato Shiro::佐藤 白
Sato Mugi::佐藤 麦|Mugi
Tenshi no Yuwaku::天使の誘惑|Imo|40
Umi::海
Kujira no Bottle::くじらのボトル
Mitake::三岳
Sekitoba::赤兎馬
Kura no Shikon::蔵の師魂
Kozuru Kuro::小鶴くろ
Kozuru Yellow::小鶴黄麹
Mogura::もぐら
Kuro Isanishiki::黒伊佐錦
Seikouudoku::晴耕雨読
Dassai Shochu::獺祭 焼酎|Kasu-tori|39
Hakutake Shiro::白岳しろ|Kome
Hakutake Ginrei Shiro::白岳 銀しろ|Kome
Hakutake Kin Shiro::白岳 金しろ|Kome
Torikai::吟香 鳥飼|Kome
Kawabe::川辺|Kome
Senchu::繊月|Kome
Yokaichi Kome::よかいち 米|Kome
Yokaichi Mugi::よかいち 麦|Mugi
Kuro Yokaichi Imo::黒よかいち 芋
Unkai Soba::雲海 そば焼酎|Soba
Towari::十割|Soba
Kumo no Ue::雲の上|Soba
Rento::れんと|Kokuto
Amami::奄美|Kokuto|30
Mankoi::まんこい|Kokuto|30
Takakura::高倉|Kokuto|30
Hama Chidori no Uta::浜千鳥乃詩|Kokuto|30
Asahi Kokuto::朝日|Kokuto|30
Ryugu::龍宮|Kokuto|30
Zanpa White::残波 ホワイト|Awamori
Zanpa Black::残波 ブラック|Awamori|30
Kumesen Brown::久米仙 ブラウン|Awamori|30
Kumesen Green::久米仙 グリーン|Awamori
Ryukyu Ohcho::琉球王朝|Awamori|30
Taragawa Brown::多良川 ブラウン|Awamori|30
Seifuku::請福|Awamori|30
Harusame Kari::春雨 カリー|Awamori|30
Shirayuri::白百合|Awamori|30
Kikunotsuyu VIP Gold::菊之露 VIPゴールド|Awamori|30
Miyanotsuru::宮之鶴|Awamori|30
Yaesen Black Pearl::八重泉 黒真珠|Awamori|43
Kura Awamori::くら|Awamori
Yukko Mugi::壱岐っ娘|Mugi
Iki Super Gold 22::壱岐スーパーゴールド22|Mugi|22
Saruko::猿川|Mugi
Jinkoo::尽空|Imo
Kuro Satsuma::黒さつま|Imo
Satsuma Kuro Godai::さつま黒五代|Imo
Satsuma Chaya::薩摩茶屋|Imo
Kinmiya Shochu::キンミヤ焼酎|Koruiju
Takara Jun::宝焼酎 純|Koruiju
Takara Gokujo::宝焼酎 極上|Koruiju
Kurokoji Jikomi Satsuma Shima Bijin::さつま島美人|Imo
Kurokoji Jikomi Satsuma Mura::さつま島美人 黒麹|Imo
Kuro Koji Asahi Mugi::黒麹旭萬年 麦|Mugi
Asahi Mannen Imo::旭萬年 芋|Imo
Tsukushi Kuro::つくし 黒|Mugi
Tsukushi Shiro::つくし 白|Mugi
Kanehachi::兼八|Mugi
Taimei::泰明|Mugi
Musou Sengetsu::無双仙楽|Mugi
Kuro Sesen::黒さそり|Mugi
Mizuho Kome Shochu::瑞穂 米焼酎|Kome
Hakkaisan Yoroshiku Senman Arubeshi::よろしく千萬あるべし|Kome
Tantakatan Shiso Shochu::鍛高譚|Shiso
Shiso Shochu Wakamurasaki no Kimi::若紫ノ君|Shiso
Kumejima no Kumesen::久米島の久米仙|Awamori|30
Tamanohikari Junmai Daiginjo Shochu::玉乃光 純米大吟醸焼酎|Kasu-tori|35
  `,
);

add(
  'gin',
  { subcategory: 'London Dry', abv: 40, originCountry: 'England' },
  String.raw`
Bombay Sapphire|London Dry|47
Bombay Dry Gin
Tanqueray London Dry Gin|London Dry|47.3
Tanqueray No Ten|New Western|47.3
Tanqueray Rangpur|Flavoured Gin|41.3
Beefeater London Dry Gin
Beefeater 24|London Dry|45
Plymouth Gin|Plymouth|41.2
Plymouth Navy Strength|Navy Strength|57
Gordon's London Dry Gin|London Dry|37.5
Hayman's London Dry Gin|London Dry|41.2
Hayman's Old Tom Gin|Old Tom|41.4
Sipsmith London Dry Gin|London Dry|41.6
Sipsmith VJOP|Navy Strength|57.7
Broker's London Dry Gin
Martin Miller's Gin
Portobello Road No 171|London Dry|42
Whitley Neill London Dry Gin|London Dry|43
Whitley Neill Rhubarb and Ginger Gin|Flavoured Gin|43
Silent Pool Gin|New Western|43
The Botanist Islay Dry Gin|New Western|46|Scotland
Caorunn Small Batch Scottish Gin|New Western|41.8|Scotland
Edinburgh Gin Classic|London Dry|43|Scotland
Harris Gin|New Western|45|Scotland
Hendrick's Orbium|New Western|43.4|Scotland
Hendrick's Neptunia|New Western|43.4|Scotland
Monkey 47 Schwarzwald Dry Gin|New Western|47|Germany
Ferdinand's Saar Dry Gin|New Western|44|Germany
Elephant London Dry Gin|London Dry|45|Germany
Gin Mare|Mediterranean|42.7|Spain
Nordes Atlantic Galician Gin|New Western|40|Spain
Larios 12|London Dry|40|Spain
Citadelle Original Gin|London Dry|44|France
G'Vine Floraison|New Western|40|France
Generous Gin|New Western|44|France
Nolet's Silver Dry Gin|New Western|47.6|Netherlands
Bols Genever|Genever|42|Netherlands
Filliers Dry Gin 28|London Dry|46|Belgium
Malfy Gin Originale|London Dry|41|Italy
Malfy Gin Rosa|Flavoured Gin|41|Italy
Engine Organic Gin|London Dry|42|Italy
Four Pillars Rare Dry Gin|New Western|41.8|Australia
Four Pillars Bloody Shiraz Gin|Flavoured Gin|37.8|Australia
Archie Rose Signature Dry Gin|New Western|42|Australia
Scapegrace Classic Gin|London Dry|42.2|New Zealand
Strange Nature Gin|New Western|44|New Zealand
Aviation American Gin|New Western|42|United States
Bluecoat American Dry Gin|American Dry|47|United States
St George Botanivore Gin|New Western|45|United States
St George Terroir Gin|New Western|45|United States
Junipero Gin|London Dry|49.3|United States
No 209 Gin|New Western|46|United States
Barr Hill Gin|New Western|45|United States
Brooklyn Gin|New Western|40|United States
Ki No Bi Kyoto Dry Gin::季の美 京都ドライジン|New Western|45.7|Japan
Ki No Tea Kyoto Dry Gin::季のTEA 京都ドライジン|New Western|45.1|Japan
Ki No Tou Old Tom Gin::季の糖島|Old Tom|47.4|Japan
Sakurao Gin Original::桜尾ジン オリジナル|New Western|47|Japan
Sakurao Gin Hamagou::桜尾ジン 浜ゴウ|New Western|47|Japan
Nikka Coffey Gin::ニッカ カフェジン|New Western|47|Japan
Suntory Sui Gin::翠ジン|New Western|40|Japan
Komasa Gin Hojicha::小正ジン ほうじ茶|New Western|45|Japan
Komasa Gin Sakurajima Komikan::小正ジン 桜島小みかん|New Western|45|Japan
Masahiro Okinawa Gin::まさひろオキナワジン|New Western|47|Japan
Etsu Gin::エツ ジン|New Western|43|Japan
Yuzugin Japanese Craft Gin::油津吟 Yuzugin|New Western|47|Japan
9148 Gin Original::9148 ジン オリジナル|New Western|45|Japan
9148 Gin Lavender::9148 ジン ラベンダー|New Western|45|Japan
Akayane Craft Gin Heart Summer::赤屋根 クラフトジン ハート 夏|New Western|45|Japan
Akayane Craft Gin Heart Winter::赤屋根 クラフトジン ハート 冬|New Western|45|Japan
Japanese GIN Wabijin::Japanese GIN 和美人|New Western|47|Japan
Kokoro Gin|New Western|42
Drumshanbo Gunpowder Irish Gin|New Western|43|Ireland
Dingle Original Gin|London Dry|42.5|Ireland
Glendalough Wild Botanical Gin|New Western|41|Ireland
Ungava Canadian Premium Gin|New Western|43.1|Canada
Empress 1908 Indigo Gin|New Western|42.5|Canada
Herno Gin|London Dry|40.5|Sweden
Herno Old Tom Gin|Old Tom|43|Sweden
Bareksten Botanical Gin|New Western|46|Norway
Harahorn Norwegian Gin|New Western|46|Norway
Kyrö Napue Gin|New Western|46.3|Finland
Mackintosh Scottish Gin|London Dry|42|Scotland
Rock Rose Gin|New Western|41.5|Scotland
Mombasa Club London Dry Gin|London Dry|41.5|England
Opihr Oriental Spiced Gin|Spiced Gin|40|England
Bloom London Dry Gin|London Dry|40|England
Seagram's Extra Dry Gin|American Dry|40|United States
  `,
);

add(
  'vodka',
  { subcategory: 'Plain', abv: 40, originCountry: 'Sweden' },
  String.raw`
Absolut Vodka
Absolut Elyx|Plain|42.3
Absolut Citron|Flavoured
Absolut Vanilia|Flavoured|38
Absolut Mandarin|Flavoured
Ketel One Vodka|Plain|40|Netherlands
Ketel One Citroen|Flavoured|40|Netherlands
Belvedere Vodka|Plain|40|Poland
Belvedere Smogory Forest|Plain|40|Poland
Belvedere Lake Bartezek|Plain|40|Poland
Chopin Potato Vodka|Plain|40|Poland
Chopin Rye Vodka|Plain|40|Poland
Zubrowka Bison Grass Vodka|Flavoured|37.5|Poland
Wyborowa Vodka|Plain|40|Poland
Luksusowa Vodka|Plain|40|Poland
Finlandia Vodka|Plain|40|Finland
Finlandia Cranberry|Flavoured|37.5|Finland
Koskenkorva Vodka|Plain|40|Finland
Reyka Vodka|Plain|40|Iceland
Icelandic Mountain Vodka|Plain|40|Iceland
Tito's Handmade Vodka|Plain|40|United States
Skyy Vodka|Plain|40|United States
New Amsterdam Vodka|Plain|40|United States
Hangar 1 Vodka|Plain|40|United States
Hangar 1 Buddha's Hand Citron|Flavoured|40|United States
Crystal Head Vodka|Plain|40|Canada
Crystal Head Aurora|Plain|40|Canada
Polar Ice Vodka|Plain|40|Canada
Smirnoff No 21 Vodka|Plain|40|United Kingdom
Smirnoff Black No 55|Plain|40|United Kingdom
Smirnoff Raspberry|Flavoured|37.5|United Kingdom
Ciroc Vodka|Grape|40|France
Ciroc Red Berry|Flavoured|37.5|France
Ciroc Pineapple|Flavoured|37.5|France
Grey Goose Le Citron|Flavoured|40|France
Grey Goose La Poire|Flavoured|40|France
Grey Goose VX|Vodka Spirit Drink|40|France
Eristoff Vodka|Plain|37.5|France
Russian Standard Original|Plain|40|Russia
Russian Standard Platinum|Plain|40|Russia
Stolichnaya Premium Vodka|Plain|40|Latvia
Stolichnaya Elit|Plain|40|Latvia
Moskovskaya Vodka|Plain|38|Latvia
Beluga Noble Russian Vodka|Plain|40|Montenegro
Beluga Gold Line|Plain|40|Montenegro
Nemiroff De Luxe|Plain|40|Ukraine
Nemiroff Honey Pepper|Flavoured|40|Ukraine
Khortytsa Platinum|Plain|40|Ukraine
Haku Vodka::白 Haku Vodka|Rice|40|Japan
Nikka Coffey Vodka::ニッカ カフェウォッカ|Grain|40|Japan
Okuhida Vodka::奥飛騨ウォッカ|Rice|40|Japan
Hakutsuru Tanrei Junmai Vodka::白鶴 淡麗純米ウォッカ|Rice|40|Japan
Ukiyo Japanese Rice Vodka|Rice|40|Japan
Nikka Wilkinson Vodka::ウヰルキンソン ウォッカ|Plain|40|Japan
Suntory Vodka 80 Proof::サントリー ウォッカ 80プルーフ|Plain|40|Japan
42 Below Vodka|Plain|40|New Zealand
Vdka 6100|Plain|40|New Zealand
Sauvelle Vodka|Plain|40|France
Jean-Marc XO Vodka|Plain|40|France
Purity Vodka 34|Plain|40|Sweden
Svedka Vodka|Plain|40|Sweden
Level Vodka|Plain|40|Sweden
Karlsson's Gold Vodka|Potato|40|Sweden
Three Olives Vodka|Plain|40|United Kingdom
Chase Original Potato Vodka|Potato|40|England
Black Cow Vodka|Milk|40|England
Sapling Vodka|Plain|40|England
Broken Shed Vodka|Plain|40|New Zealand
Wheatley Vodka|Plain|41|United States
Deep Eddy Vodka|Plain|40|United States
Prairie Organic Vodka|Plain|40|United States
Ocean Organic Vodka|Plain|40|United States
Boyd and Blair Potato Vodka|Potato|40|United States
Square One Organic Vodka|Plain|40|United States
  `,
);

for (const [brand, variants] of [
  ['Patron', ['Silver|Blanco', 'Reposado', 'Anejo', 'Extra Anejo', 'El Cielo|Blanco']],
  ['Don Julio', ['Blanco|Blanco|38', 'Reposado|Reposado|38', 'Anejo|Anejo|38', '70 Cristalino|Cristalino|35', 'Primavera|Reposado']],
  ['Jose Cuervo', ['Especial Silver|Blanco|38', 'Especial Gold|Joven|38', 'Tradicional Silver|Blanco|38', 'Tradicional Reposado|Reposado|38']],
  ['1800', ['Silver|Blanco', 'Reposado', 'Anejo', 'Cristalino']],
  ['Herradura', ['Silver|Blanco', 'Reposado', 'Anejo', 'Ultra|Cristalino']],
  ['El Jimador', ['Blanco', 'Reposado', 'Anejo']],
  ['Olmeca Altos', ['Plata|Blanco|38', 'Reposado|Reposado|38', 'Anejo|Anejo|38']],
  ['Casamigos', ['Blanco', 'Reposado', 'Anejo', 'Cristalino']],
  ['Clase Azul', ['Plata|Blanco', 'Reposado', 'Gold|Joven', 'Anejo']],
  ['Codigo 1530', ['Blanco', 'Rosa|Reposado', 'Reposado', 'Anejo']],
  ['Fortaleza', ['Blanco', 'Reposado', 'Anejo']],
  ['Ocho', ['Plata|Blanco', 'Reposado', 'Anejo']],
  ['Siete Leguas', ['Blanco', 'Reposado', 'Anejo']],
  ['Tapatio', ['Blanco', 'Reposado', 'Anejo']],
  ['Espolon', ['Blanco', 'Reposado', 'Anejo']],
  ['Milagro', ['Silver|Blanco', 'Reposado', 'Anejo']],
  ['Teremana', ['Blanco', 'Reposado', 'Anejo']],
  ['Avion', ['Silver|Blanco', 'Reposado', 'Anejo']],
  ['Cazadores', ['Blanco', 'Reposado', 'Anejo']],
  ['Sauza Hornitos', ['Plata|Blanco', 'Reposado', 'Anejo']],
  ['Gran Centenario', ['Plata|Blanco', 'Reposado', 'Anejo']],
  ['Kah', ['Blanco', 'Reposado', 'Anejo']],
  ['Casa Noble', ['Blanco', 'Reposado', 'Anejo']],
]) {
  addVariants('tequila', { subcategory: 'Tequila', abv: 40, originCountry: 'Mexico' }, brand, variants);
}

for (const [brand, variants, country = 'France'] of [
  ['Bacardi', ['Carta Blanca|White Rum', 'Carta Oro|Gold Rum', 'Ocho|Aged Rum', 'Reserva Diez|Aged Rum'], 'Puerto Rico'],
  ['Havana Club', ['3 Year Old|White Rum', '7 Year Old|Aged Rum', 'Seleccion de Maestros|Aged Rum|45'], 'Cuba'],
  ['Appleton Estate', ['Signature|Aged Rum', '8 Year Old Reserve|Aged Rum|43', '12 Year Old Rare Casks|Aged Rum|43', '21 Year Old|Aged Rum|43'], 'Jamaica'],
  ['Hampden Estate', ['8 Year Old|Aged Rum|46', 'Overproof|Overproof|60'], 'Jamaica'],
  ['Mount Gay', ['Eclipse|Gold Rum', 'Black Barrel|Aged Rum|43', 'XO|Aged Rum|43'], 'Barbados'],
  ['Doorly', ['XO|Aged Rum', '12 Year Old|Aged Rum'], 'Barbados'],
  ['Plantation', ['3 Stars|White Rum|41.2', 'Original Dark|Dark Rum', 'XO 20th Anniversary|Aged Rum'], 'Barbados'],
  ['Diplomatico', ['Reserva Exclusiva|Aged Rum', 'Mantuano|Aged Rum', 'Planas|White Rum|47'], 'Venezuela'],
  ['El Dorado', ['8 Year Old|Aged Rum', '12 Year Old|Aged Rum', '15 Year Old|Aged Rum|43'], 'Guyana'],
  ['Angostura', ['7 Year Old|Aged Rum', '1919|Aged Rum', '1824|Aged Rum'], 'Trinidad and Tobago'],
  ['Don Q', ['Cristal|White Rum', 'Gold|Gold Rum', 'Gran Reserva Anejo XO|Aged Rum'], 'Puerto Rico'],
  ['Flor de Cana', ['4 Extra Seco|White Rum', '7 Gran Reserva|Aged Rum', '12|Aged Rum', '18|Aged Rum'], 'Nicaragua'],
  ['Brugal', ['Anejo|Aged Rum|38', '1888|Aged Rum'], 'Dominican Republic'],
  ['Ron Abuelo', ['7 Anos|Aged Rum', '12 Anos|Aged Rum', 'Centuria|Aged Rum'], 'Panama'],
  ['Ron Botran', ['Reserva Blanca|White Rum', '15|Aged Rum', '18|Aged Rum'], 'Guatemala'],
  ['Rhum J.M', ['Blanc|Rhum Agricole|50', 'Vieux VSOP|Rhum Agricole|43'], 'Martinique'],
  ['Rhum Clement', ['VSOP|Rhum Agricole'], 'Martinique'],
  ['Chairman\'s Reserve', ['Original|Aged Rum', 'Spiced|Spiced Rum'], 'Saint Lucia'],
]) {
  addVariants('rum', { subcategory: 'Aged Rum', abv: 40, originCountry: country }, brand, variants);
}

add(
  'rum',
  { subcategory: 'Dark Rum', abv: 40, originCountry: 'Jamaica' },
  String.raw`
Myers's Original Dark
Smith and Cross Traditional Jamaica Rum|Navy Strength|57
Wray and Nephew White Overproof|Overproof|63
Santa Teresa 1796|Aged Rum|40|Venezuela
Pampero Aniversario|Aged Rum|40|Venezuela
Lemon Hart 151|Overproof|75.5|Guyana
Pusser's Blue Label|Navy Rum|40|Guyana
Barcelo Imperial|Aged Rum|38|Dominican Republic
Matusalem Gran Reserva 15|Aged Rum|40|Dominican Republic
Zafra Master Reserve 21|Aged Rum|40|Panama
Ron Centenario 20 Fundacion|Aged Rum|40|Costa Rica
Clairin Sajous|Clairin|54.3|Haiti
Clairin Vaval|Clairin|50|Haiti
Rhum Barbancourt 8 Year Old|Aged Rum|43|Haiti
Trois Rivieres Cuvee de l'Ocean|Rhum Agricole|42|Martinique
Neisson Blanc|Rhum Agricole|50|Martinique
Saint James Royal Ambre|Rhum Agricole|45|Martinique
English Harbour 5 Year Old|Aged Rum|40|Antigua and Barbuda
Goslings Black Seal|Black Rum|40|Bermuda
Kraken Black Spiced Rum|Spiced Rum|40|Trinidad and Tobago
Sailor Jerry Spiced Rum|Spiced Rum|40|United States
Captain Morgan Original Spiced Gold|Spiced Rum|35|Jamaica
Lamb's Navy Rum|Navy Rum|40|Caribbean
Nine Leaves Clear::ナインリーヴズ クリア|White Rum|50|Japan
Nine Leaves Angel's Half::ナインリーヴズ エンジェルズハーフ|Aged Rum|48|Japan
Cor Cor Red::コルコル レッド|Aged Rum|40|Japan
Cor Cor Green::コルコル グリーン|White Rum|40|Japan
Ryoma 7 Year Old Rum::龍馬 7年 ラム|Aged Rum|40|Japan
  `,
);

for (const [brand, variants] of [
  ['Hennessy', ['VS|Cognac', 'VSOP|Cognac', 'Paradis|Cognac']],
  ['Remy Martin', ['VSOP|Cognac', '1738 Accord Royal|Cognac', 'XO|Cognac', 'Louis XIII|Cognac']],
  ['Martell', ['VS|Cognac', 'Blue Swift|Cognac', 'Cordon Bleu|Cognac', 'XO|Cognac']],
  ['Courvoisier', ['VS|Cognac', 'VSOP|Cognac', 'XO|Cognac']],
  ['Camus', ['VSOP Elegance|Cognac', 'XO Elegance|Cognac', 'Borderies VSOP|Cognac']],
  ['Otard', ['VSOP|Cognac', 'XO Gold|Cognac']],
  ['Delamain', ['Pale and Dry XO|Cognac', 'Vesper XO|Cognac']],
  ['Hine', ['Rare VSOP|Cognac', 'Antique XO|Cognac']],
  ['Frapin', ['VSOP|Cognac', 'Chateau Fontpinot XO|Cognac|41']],
  ['Pierre Ferrand', ['1840 Original Formula|Cognac|45', 'Ambre|Cognac', 'Reserve Double Cask|Cognac|42.3']],
  ['Larsen', ['VSOP|Cognac', 'XO|Cognac']],
  ['Meukow', ['VS|Cognac', 'VSOP|Cognac', 'XO|Cognac']],
  ['Bache-Gabrielsen', ['Tre Kors|Cognac', 'VSOP|Cognac']],
  ['Armagnac de Montal', ['VSOP|Armagnac', 'XO|Armagnac']],
  ['Castarede', ['VSOP Armagnac|Armagnac', 'XO Armagnac|Armagnac']],
  ['Darroze Les Grands Assemblages', ['12 Ans|Armagnac|43', '20 Ans|Armagnac|43']],
  ['Janneau', ['VSOP Armagnac|Armagnac', 'XO Armagnac|Armagnac']],
  ['Calvados Boulard', ['VSOP|Calvados', 'XO|Calvados']],
  ['Pere Magloire', ['VSOP Calvados|Calvados', 'XO Calvados|Calvados']],
  ['Christian Drouin', ['Selection Calvados|Calvados', 'XO Calvados|Calvados']],
]) {
  addVariants('brandy', { subcategory: 'Brandy', abv: 40, originCountry: 'France' }, brand, variants);
}

add(
  'brandy',
  { subcategory: 'Brandy', abv: 40, originCountry: 'Spain' },
  String.raw`
Laird's Applejack|Apple Brandy|40|United States
Laird's Straight Apple Brandy|Apple Brandy|50|United States
Clear Creek Pear Brandy|Fruit Brandy|40|United States
Germain-Robin Craft-Method Brandy|Brandy|40|United States
Korbel Brandy|Brandy|40|United States
EJ VS Brandy|Brandy|40|United States
EJ VSOP Brandy|Brandy|40|United States
Torres 10 Gran Reserva|Brandy de Jerez|38|Spain
Torres 15 Reserva Privada|Brandy de Jerez|40|Spain
Cardenal Mendoza Solera Gran Reserva|Brandy de Jerez|40|Spain
Lepanto Solera Gran Reserva|Brandy de Jerez|36|Spain
Fundador Solera Reserva|Brandy de Jerez|36|Spain
Osborne Veterano|Brandy de Jerez|30|Spain
Vecchia Romagna Etichetta Nera|Brandy|38|Italy
Stock 84|Brandy|38|Italy
Metaxa 5 Stars|Greek Brandy|38|Greece
Metaxa 7 Stars|Greek Brandy|40|Greece
Metaxa 12 Stars|Greek Brandy|40|Greece
Asbach Uralt|Weinbrand|38|Germany
St-Remy VSOP|Brandy|40|France
St-Remy XO|Brandy|40|France
  `,
);

add(
  'brandy',
  { subcategory: 'Pisco', abv: 40, originCountry: 'Peru' },
  String.raw`
Barsol Pisco Quebranta
Barsol Pisco Italia
Macchu Pisco
Caravedo Pisco Puro Quebranta
Capel Pisco Reservado|Pisco|40|Chile
Mistral Nobel Pisco|Pisco|40|Chile
  `,
);

add(
  'liqueur',
  { subcategory: 'Bitter', abv: 25, originCountry: 'Italy' },
  String.raw`
Campari
Aperol|Aperitivo|11
Cynar|Amaro|16.5
Select Aperitivo|Aperitivo|17.5
Montenegro Amaro Italiano|Amaro|23
Averna Amaro Siciliano|Amaro|29
Fernet-Branca|Amaro|39
Branca Menta|Amaro|28
Ramazzotti Amaro|Amaro|30
Lucano Amaro|Amaro|28
Nonino Amaro Quintessentia|Amaro|35
Disaronno Originale|Amaretto|28
Lazzaroni Amaretto|Amaretto|24
Frangelico|Hazelnut|20
Galliano L'Autentico|Herbal|42.3
Galliano Vanilla|Vanilla|30
Luxardo Maraschino|Maraschino|32
Luxardo Limoncello|Limoncello|27
Villa Massa Limoncello|Limoncello|30
Cointreau|Orange|40|France
Grand Marnier Cordon Rouge|Orange|40|France
Pierre Ferrand Dry Curacao|Orange|40|France
Combier L'Original Triple Sec|Orange|40|France
Chambord|Raspberry|16.5|France
Chartreuse Green|Herbal|55|France
Chartreuse Yellow|Herbal|43|France
Benedictine DOM|Herbal|40|France
St-Germain Elderflower Liqueur|Elderflower|20|France
Mathilde Poire|Pear|18|France
Giffard Creme de Violette|Floral|16|France
Giffard Pamplemousse Rose|Grapefruit|16|France
Giffard Menthe Pastille|Mint|24|France
Merlet Creme de Cassis|Cassis|20|France
Lejay Creme de Cassis|Cassis|18|France
Pernod Anise|Anise|40|France
Ricard Pastis|Anise|45|France
Jagermeister|Herbal|35|Germany
Berentzen Apple Korn|Apple|18|Germany
Killepitsch|Herbal|42|Germany
Drambuie|Whisky Liqueur|40|Scotland
Glayva|Whisky Liqueur|35|Scotland
Southern Comfort|Whiskey Liqueur|35|United States
Fireball Cinnamon Whisky|Cinnamon Whisky Liqueur|33|Canada
Jack Daniel's Tennessee Honey|Whiskey Liqueur|35|United States
Jack Daniel's Tennessee Fire|Whiskey Liqueur|35|United States
Wild Turkey American Honey|Whiskey Liqueur|35.5|United States
Yukon Jack|Honey Liqueur|50|Canada
Malibu Original|Coconut Rum Liqueur|21|Barbados
Malibu Pineapple|Rum Liqueur|21|Barbados
Passoa Passion Fruit Liqueur|Passion Fruit|17|France
Midori Melon Liqueur::ミドリ メロンリキュール|Melon|20|Japan
Heering Cherry Liqueur|Cherry|24|Denmark
Cherry Marnier|Cherry|24|France
De Kuyper Blue Curacao|Curacao|20|Netherlands
De Kuyper Peachtree|Peach|20|Netherlands
Bols Blue Curacao|Curacao|21|Netherlands
Bols Apricot Brandy|Apricot|24|Netherlands
Bols Creme de Cacao White|Cacao|24|Netherlands
Bols Peppermint Green|Mint|24|Netherlands
Tia Maria|Coffee|20|Italy
Mr Black Cold Brew Coffee Liqueur|Coffee|23|Australia
Patron XO Cafe|Coffee Tequila Liqueur|35|Mexico
Sheridan's Coffee Layered Liqueur|Coffee Cream|15.5|Ireland
Carolans Irish Cream|Cream|17|Ireland
Five Farms Irish Cream|Cream|17|Ireland
Amarula Cream|Cream|17|South Africa
Mozart Chocolate Cream|Chocolate Cream|17|Austria
Mozart White Chocolate Cream|Chocolate Cream|15|Austria
Licor 43|Vanilla|31|Spain
Ancho Reyes Chile Liqueur|Chile|40|Mexico
Ancho Reyes Verde|Chile|40|Mexico
Nixta Licor de Elote|Corn|30|Mexico
Agavero Tequila Liqueur|Agave|32|Mexico
Pimm's No 1 Cup|Gin Liqueur|25|England
Choya Umeshu::チョーヤ 梅酒|Umeshu|10|Japan
Choya Extra Years::チョーヤ エクストラ・イヤーズ|Umeshu|17|Japan
Choya Royal Honey::チョーヤ ロイヤルハニー|Umeshu|15|Japan
Kishu Umeshu Beninanko::紀州梅酒 紅南高|Umeshu|20|Japan
Kokuto Umeshu::黒糖梅酒|Umeshu|14|Japan
Suntory Plum Liqueur Yamazaki Cask Blend::サントリー梅酒 山崎樽熟成|Umeshu|20|Japan
Hoshiko Umeshu::星子 梅酒|Umeshu|14|Japan
Tsuruume Yuzu Liqueur::鶴梅 ゆず|Fruit Liqueur|7|Japan
Tsuruume Lemon Liqueur::鶴梅 れもん|Fruit Liqueur|7|Japan
Kawaii Shiroi Lychee::かわいい白いライチ|Fruit Liqueur|6|Japan
Kawaii Shiroi La France::かわいい白いラ・フランス|Fruit Liqueur|6|Japan
Kawaii Shiroi Umeshu::かわいい白い梅酒|Umeshu|8|Japan
Hakkaisan Umeshu::八海山 梅酒|Umeshu|13|Japan
Kirin Hyoketsu Mottainai Hamaguri no Umeshu::氷結 mottainai 梅酒|Umeshu|10|Japan
De Kuyper Creme de Banana|Banana|24|Netherlands
Bols Strawberry|Strawberry|17|Netherlands
Bols Yogurt|Yogurt|15|Netherlands
Marie Brizard Apry|Apricot|20|France
Marie Brizard Parfait Amour|Floral|25|France
Maraska Maraschino|Maraschino|32|Croatia
Zwack Unicum|Herbal|40|Hungary
Becherovka Original|Herbal|38|Czech Republic
Goldschlager Cinnamon Schnapps|Cinnamon|43.5|Switzerland
Hpnotiq Liqueur|Fruit Liqueur|17|France
  `,
);

add(
  'other',
  { subcategory: 'Cider', abv: 5, originCountry: 'United Kingdom' },
  String.raw`
Strongbow Original Dry Cider
Strongbow Dark Fruit Cider|Cider|4
Magners Original Irish Cider|Cider|4.5|Ireland
Bulmers Original Cider|Cider|4.5|Ireland
Kopparberg Premium Pear Cider|Cider|4.5|Sweden
Kopparberg Strawberry and Lime Cider|Cider|4|Sweden
Rekorderlig Strawberry-Lime Cider|Cider|4.5|Sweden
Rekorderlig Wild Berries Cider|Cider|4.5|Sweden
Thatchers Gold Cider
Thatchers Haze Cider|Cider|4.5
Aspall Premier Cru Cyder|Cider|6.8
Westons Old Rosie Cloudy Cider|Cider|6.8
Samuel Smith Organic Cider|Cider|5
Sheppy's 200 Special Edition Cider|Cider|5
Orchard Pig Reveller Cider|Cider|4.5
Henry Westons Vintage Cider|Cider|8.2
Hogan's Medium Cider|Cider|5.4
Angry Orchard Crisp Apple|Cider|5|United States
Angry Orchard Green Apple|Cider|5|United States
Woodchuck Amber Cider|Cider|5|United States
Woodchuck Granny Smith Cider|Cider|5|United States
Ace Pineapple Cider|Cider|5|United States
Ace Perry Cider|Perry|5|United States
Original Sin Hard Cider|Cider|6|United States
Downeast Original Blend Cider|Cider|5.1|United States
Citizen Cider Unified Press|Cider|5.2|United States
Seattle Cider Semi Sweet|Cider|6.5|United States
Schilling Grapefruit and Chill|Cider|6|United States
Tieton Wild Washington Apple Cider|Cider|6.9|United States
2 Towns BrightCider|Cider|6|United States
Finnriver Farmstead Cider|Cider|6.5|United States
Eden Imperial 11 Rose|Ice Cider|11|United States
Domaine Dupont Cidre Bouche Brut|Cider|5.5|France
Eric Bordelet Sidre Brut Tendre|Cider|4|France
Loic Raison Cidre Doux|Cider|2.5|France
Kerisac Cidre Breton Brut|Cider|5|France
Lepere Cidre Brut|Cider|5|France
Sidra El Gaitero|Cider|4.1|Spain
Sidra Trabanco Avalon|Cider|5.5|Spain
Maeloc Dry Cider|Cider|4.5|Spain
Kirin Hard Cidre::キリン ハードシードル|Cider|4.5|Japan
Nikka Cidre Sweet::ニッカ シードル スイート|Cider|3|Japan
Nikka Cidre Dry::ニッカ シードル ドライ|Cider|5|Japan
Aomori Apple Cider Kimori::弘前シードル工房 kimori|Cider|5|Japan
Tono Cider Dry::遠野シードル ドライ|Cider|6|Japan
Kikusui Cidre::菊水 シードル|Cider|5|Japan
Mead Makana Honey Wine::マカナ はちみつ酒|Mead|12|Japan
Kuhachi Mead Sparkling::くはち ミード スパークリング|Mead|8|Japan
Moonlight Meadery Desire|Mead|14|United States
Schramm's The Statement|Mead|14|United States
Dansk Mjod Viking Blod|Mead|19|Denmark
Lindisfarne Mead|Mead|14.5|United Kingdom
Gosnells London Mead|Mead|5.5|United Kingdom
Charm City Meadworks Original Dry|Mead|6.9|United States
B Nektar Zombie Killer|Mead|5.5|United States
Superstition Meadery Marion|Mead|13|United States
Sap House Meadery Hopped Blueberry Maple|Mead|12|United States
Oliver's Gold Rush Cider|Cider|6.5|United Kingdom
Ross on Wye Raison d'Etre Cider|Cider|7|United Kingdom
  `,
);

const catalog = buildCatalog();

mkdirSync(BATCH_DIR, { recursive: true });
mkdirSync(DRINK_DIR, { recursive: true });

const writtenBatches = [];
let individualWritten = 0;
let individualSkipped = 0;

for (const [category, count] of Object.entries(phase1Counts)) {
  assertEnough(catalog, category, count + (phase2Counts[category] || 0));
  const batch = catalog.get(category).slice(0, count);
  writeJson(path.join(BATCH_DIR, `phase1-${category}.json`), batch);
  writtenBatches.push([`phase1-${category}.json`, batch.length]);
}

for (const [category, count] of Object.entries(phase2Counts)) {
  assertEnough(catalog, category, (phase1Counts[category] || 0) + count);
  const offset = phase1Counts[category] || 0;
  const batch = catalog.get(category).slice(offset, offset + count);
  writeJson(path.join(BATCH_DIR, `phase2-${category}.json`), batch);
  writtenBatches.push([`phase2-${category}.json`, batch.length]);
}

for (const [fileName] of writtenBatches) {
  const batch = JSON.parse(readFileSync(path.join(BATCH_DIR, fileName), 'utf8'));
  for (const drink of batch) {
    const filePath = path.join(DRINK_DIR, `${drink.slug}.json`);
    if (existsSync(filePath)) {
      individualSkipped++;
      continue;
    }
    writeJson(filePath, drink);
    individualWritten++;
  }
}

console.log('Batch counts:');
for (const [fileName, count] of writtenBatches) {
  console.log(`  ${fileName}: ${count}`);
}
console.log(`Individual drink files: wrote ${individualWritten}, skipped ${individualSkipped}`);
console.log('Final category counts from data/drinks:');
for (const [category, count] of Object.entries(countDrinksByCategory())) {
  console.log(`  ${category}: ${count}`);
}
