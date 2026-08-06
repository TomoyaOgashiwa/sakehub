-- =============================================================================
-- packages/drink-seed（src/build-seed.ts）が自動生成。
-- 手編集しないこと。再生成: pnpm seed:drinks:build
-- 生成日時: 2026-08-06T21:36:57.415Z
-- 件数: 30
--
-- aliases: かな読み・ローマ字表記などの別名候補。「獺祭」で登録されていても
-- 「だっさい」で検索するとヒットしない、といった表記ゆれを吸収するために
-- drinks.search_vector に合流させている
-- (migrations/20260806100000_add_drink_cocktail_aliases.sql)。
-- =============================================================================

-- asahi-super-dry
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'asahi-super-dry',
  'アサヒスーパードライ',
  'Asahi Super Dry',
  'beer',
  'Lager',
  '辛口でキレのある味わいが特徴の日本を代表するドライビール。すっきりとした後味で、どんな料理にも合わせやすい。',
  NULL,
  5,
  'Japan',
  'アサヒビール',
  ARRAY['あさひすーぱーどらい', 'あさひびーる']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- baileys-original
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'baileys-original',
  'ベイリーズ オリジナル アイリッシュクリーム',
  'Baileys Original Irish Cream',
  'liqueur',
  'Cream',
  'アイリッシュウイスキーとクリームを融合させた世界で最も人気のクリームリキュール。甘くリッチな味わい。',
  NULL,
  17,
  'Ireland',
  'Baileys',
  ARRAY['べいりーず']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- brewdog-punk-ipa
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'brewdog-punk-ipa',
  'ブリュードッグ パンクIPA',
  'BrewDog Punk IPA',
  'beer',
  'IPA',
  'トロピカルフルーツとキャラメルモルトが調和したスコットランド発のクラフトIPA。ホップの香りが爆発的に広がる。',
  NULL,
  5.4,
  'United Kingdom',
  'BrewDog',
  ARRAY['ぶりゅーどっぐ', 'ぱんくいぱ']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- chateau-margaux-2015
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'chateau-margaux-2015',
  'シャトー・マルゴー 2015',
  'Chateau Margaux 2015',
  'wine',
  'Red',
  'ボルドー五大シャトーの一つ。繊細でエレガントな味わいと長い余韻が世界中のワインラバーを魅了する。',
  NULL,
  13.5,
  'France',
  'Chateau Margaux',
  ARRAY['しゃとーまるごー']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- cloudy-bay-sauvignon-blanc
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'cloudy-bay-sauvignon-blanc',
  'クラウディー・ベイ ソーヴィニヨン・ブラン',
  'Cloudy Bay Sauvignon Blanc',
  'wine',
  'White',
  'ニュージーランド・マールボロ地方の代表的白ワイン。柑橘系の爽やかなアロマとミネラル感が際立つ。',
  NULL,
  13,
  'New Zealand',
  'Cloudy Bay',
  ARRAY['くらうでぃーべい']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- dassai-23
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'dassai-23',
  '獺祭 純米大吟醸 磨き二割三分',
  'Dassai 23 Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '山田錦を23%まで磨き上げた究極の純米大吟醸。華やかな吟醸香と透明感のある甘みが広がる。',
  NULL,
  16,
  'Japan',
  '旭酒造',
  ARRAY['だっさい', 'だっさい23', 'だっさいにわりさんぶ']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- don-julio-1942
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'don-julio-1942',
  'ドン・フリオ 1942',
  'Don Julio 1942',
  'tequila',
  'Anejo',
  '最低2年半熟成のプレミアムアネホテキーラ。キャラメル、バニラ、トフィーの芳醇な風味とシルキーな舌触り。',
  NULL,
  38,
  'Mexico',
  'Don Julio',
  ARRAY['どんふりお']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- grace-koshu
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'grace-koshu',
  'グレイス 甲州',
  'Grace Koshu',
  'wine',
  'White',
  '日本固有品種「甲州」で造られた繊細な白ワイン。和食との相性は抜群で、柚子やかぼすを思わせる上品な酸味。',
  NULL,
  12,
  'Japan',
  '中央葡萄酒',
  ARRAY['ぐれいすこうしゅう']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- grey-goose
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'grey-goose',
  'グレイグース',
  'Grey Goose',
  'vodka',
  NULL,
  'フランス・コニャック地方の冬小麦と天然湧水で造られたプレミアムウォッカ。シルクのようになめらかな口当たり。',
  NULL,
  40,
  'France',
  'Grey Goose',
  ARRAY['ぐれいぐーす']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- guinness-draught
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'guinness-draught',
  'ギネス ドラフト',
  'Guinness Draught',
  'beer',
  'Stout',
  'アイルランド生まれの世界的スタウトビール。クリーミーな泡立ちとローストモルトのほのかな苦味が特徴。',
  NULL,
  4.2,
  'Ireland',
  'Guinness',
  ARRAY['ぎねす', 'ぎねすどらふと']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- hakkaisan-junmai-daiginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'hakkaisan-junmai-daiginjo',
  '八海山 純米大吟醸',
  'Hakkaisan Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '新潟の名水と厳選された酒米で醸した淡麗辛口の代表格。すっきりとした飲み口でどんな料理にも寄り添う。',
  NULL,
  15.5,
  'Japan',
  '八海醸造',
  ARRAY['はっかいさん']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- hendricks-gin
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'hendricks-gin',
  'ヘンドリックス ジン',
  'Hendrick''s Gin',
  'gin',
  NULL,
  'バラときゅうりのエッセンスが特徴的なスコットランド産プレミアムジン。個性的だが万人に愛されるフローラルな香り。',
  NULL,
  41.4,
  'United Kingdom',
  'Hendrick''s',
  ARRAY['へんどりっくす']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- hennessy-xo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'hennessy-xo',
  'ヘネシー X.O',
  'Hennessy X.O',
  'brandy',
  'Cognac',
  '最低10年熟成の約100種のオー・ド・ヴィーをブレンド。スパイス、ドライフルーツ、チョコレートが重層的に広がる。',
  NULL,
  40,
  'France',
  'Hennessy',
  ARRAY['へねしー']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- hibiki-harmony
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'hibiki-harmony',
  '響 JAPANESE HARMONY',
  'Hibiki Japanese Harmony',
  'whisky',
  'Blended',
  '山崎・白州・知多のモルトとグレーンを匠の技でブレンド。華やかな香りと繊細な甘みが調和した日本の美意識。',
  NULL,
  43,
  'Japan',
  'サントリー',
  ARRAY['ひびき', 'ひびきはーもにー']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- iichiko-frasco
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'iichiko-frasco',
  'いいちこ フラスコボトル',
  'Iichiko Frasco',
  'shochu',
  'Mugi (Barley)',
  '大分の名門・三和酒類が造る本格麦焼酎。減圧蒸留によるクリアでフルーティーな味わいが人気。',
  NULL,
  25,
  'Japan',
  '三和酒類',
  ARRAY['いいちこ', 'ふらすこぼとる']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- jameson
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'jameson',
  'ジェムソン',
  'Jameson Irish Whiskey',
  'whisky',
  'Blended',
  '3回蒸留のスムースなアイリッシュウイスキー。バニラ、ナッツ、かすかなスパイスが織りなす軽やかな味わい。',
  NULL,
  40,
  'Ireland',
  'Jameson',
  ARRAY['じぇむそん']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- juyondai-honmaru
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'juyondai-honmaru',
  '十四代 本丸 秘伝玉返し',
  'Juyondai Honmaru',
  'sake',
  'Tokubetsu Honjozo',
  '入手困難な幻の銘酒。フルーティーな香りと米の旨みが絶妙に調和し、一口で虜になる味わい。',
  NULL,
  15,
  'Japan',
  '高木酒造',
  ARRAY['じゅうよんだい', 'じゅうよんだいほんまる']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- kahlua
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'kahlua',
  'カルーア コーヒーリキュール',
  'Kahlua',
  'liqueur',
  'Coffee',
  'アラビカ種コーヒー豆とサトウキビスピリッツをベースにしたリキュール。カクテルのベースとしても絶大な人気。',
  NULL,
  20,
  'Mexico',
  'Kahlua',
  ARRAY['かるーあ']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- kokuryu-ryu
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'kokuryu-ryu',
  '黒龍 龍',
  'Kokuryu Ryu',
  'sake',
  'Daiginjo',
  '福井の銘酒・黒龍の中でも特別な大吟醸。洗練された吟醸香と気品ある味わいが特徴。',
  NULL,
  15,
  'Japan',
  '黒龍酒造',
  ARRAY['こくりゅう']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- kubota-manju
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'kubota-manju',
  '久保田 萬寿',
  'Kubota Manju',
  'sake',
  'Junmai Daiginjo',
  '久保田シリーズの最高峰。柔らかな口当たりと上品で深い味わい。余韻が長く続く贅沢な一杯。',
  NULL,
  15.5,
  'Japan',
  '朝日酒造',
  ARRAY['くぼた', 'くぼたまんじゅ']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- macallan-12-sherry-oak
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'macallan-12-sherry-oak',
  'ザ・マッカラン 12年 シェリーオーク',
  'The Macallan 12 Year Old Sherry Oak',
  'whisky',
  'Single Malt',
  'シェリー樽由来のリッチなドライフルーツとスパイスの風味。スコッチウイスキーの王道とも言える深い琥珀色の一杯。',
  NULL,
  40,
  'United Kingdom',
  'The Macallan',
  ARRAY['まっからん']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- makers-mark
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'makers-mark',
  'メーカーズマーク',
  'Maker''s Mark',
  'whisky',
  'Bourbon',
  '冬小麦を使用したまろやかなバーボン。キャラメルとバニラの甘い香りに、口当たりの柔らかさが際立つ。',
  NULL,
  45,
  'United States',
  'Maker''s Mark Distillery',
  ARRAY['めーかーずまーく']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- mori-izo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'mori-izo',
  '森伊蔵',
  'Mori Izo',
  'shochu',
  'Imo (Sweet Potato)',
  'プレミアム芋焼酎の代名詞。かめ壺仕込みが生む、まろやかで上品な甘みと深いコク。入手困難な幻の一本。',
  NULL,
  25,
  'Japan',
  '森伊蔵酒造',
  ARRAY['もりいぞう']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- opus-one-2020
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'opus-one-2020',
  'オーパス・ワン 2020',
  'Opus One 2020',
  'wine',
  'Red',
  'ナパ・ヴァレーが誇るプレミアムワイン。カベルネ・ソーヴィニヨン主体のブレンドで、深みのある果実味とエレガントなタンニンが特徴。',
  NULL,
  14.5,
  'United States',
  'Opus One Winery',
  ARRAY['おーぱすわん']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- roku-gin
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'roku-gin',
  'ROKU ジン',
  'Roku Gin',
  'gin',
  NULL,
  '桜花、桜葉、煎茶、玉露、山椒、柚子という6つの日本素材を使用した和のクラフトジン。繊細で複雑な香り。',
  NULL,
  47,
  'Japan',
  'サントリー',
  ARRAY['ろくじん', '六']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- ron-zacapa-23
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'ron-zacapa-23',
  'ロン サカパ 23',
  'Ron Zacapa Centenario 23',
  'rum',
  'Aged',
  '海抜2,300mの高地で熟成されたグアテマラの最高級ラム。バニラ、チョコレート、スパイスの豊かな層が楽しめる。',
  NULL,
  40,
  'Guatemala',
  'Ron Zacapa',
  ARRAY['ろんさかぱ']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- sapporo-premium
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sapporo-premium',
  'サッポロ生ビール 黒ラベル',
  'Sapporo Premium Beer',
  'beer',
  'Lager',
  '完璧なバランスを追求した「大人の生ビール」。麦のうまみと爽やかな後味が調和した一杯。',
  NULL,
  5,
  'Japan',
  'サッポロビール',
  ARRAY['さっぽろくろらべる', 'くろらべる']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- somersby-apple-cider
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'somersby-apple-cider',
  'サマースビー アップルサイダー',
  'Somersby Apple Cider',
  'other',
  'Cider',
  'りんごの爽やかな甘みと微炭酸が心地よいデンマーク生まれのアップルサイダー。お酒初心者にもおすすめ。',
  NULL,
  4.5,
  'Denmark',
  'Carlsberg',
  ARRAY['さまーすびー']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- yamazaki-12
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'yamazaki-12',
  '山崎 12年',
  'Yamazaki 12 Year Old',
  'whisky',
  'Single Malt',
  '日本初のモルトウイスキー蒸留所が生んだ至宝。繊細で複雑な味わいに、ほのかなミズナラの香りが漂う。',
  NULL,
  43,
  'Japan',
  'サントリー',
  ARRAY['やまざき', 'やまざき12ねん']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

-- yebisu-premium
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'yebisu-premium',
  'ヱビスビール',
  'Yebisu Beer',
  'beer',
  'Pilsner',
  'ドイツ「ビール純粋令」に則った麦芽100%の本格プレミアムビール。深いコクと豊かな香りが楽しめる。',
  NULL,
  5,
  'Japan',
  'サッポロビール',
  ARRAY['えびすびーる', 'えびす']::TEXT[]
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  name_en = EXCLUDED.name_en,
  category = EXCLUDED.category,
  subcategory = EXCLUDED.subcategory,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  abv = EXCLUDED.abv,
  origin_country = EXCLUDED.origin_country,
  manufacturer = EXCLUDED.manufacturer,
  aliases = EXCLUDED.aliases,
  updated_at = now();

