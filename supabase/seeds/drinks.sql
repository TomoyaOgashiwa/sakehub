-- =============================================================================
-- packages/drink-seed（src/build-seed.ts）が自動生成。
-- 手編集しないこと。再生成: pnpm seed:drinks:build
-- 生成日時: 2026-08-09T20:31:20.018Z
-- 件数: 125
--
-- aliases: かな読み・ローマ字表記などの別名候補。「獺祭」で登録されていても
-- 「だっさい」で検索するとヒットしない、といった表記ゆれを吸収するために
-- drinks.search_vector に合流させている
-- (migrations/20260806100000_add_drink_cocktail_aliases.sql)。
-- =============================================================================

-- amanoto-tokubetsu-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'amanoto-tokubetsu-junmai',
  '天の戸 特別純米',
  'Amanoto Tokubetsu Junmai',
  'sake',
  'Tokubetsu Junmai',
  '秋田・浅舞酒造の特別純米。柔らかな甘みと綺麗な後味。',
  NULL,
  15,
  'Japan',
  '浅舞酒造',
  ARRAY['あまのととくべつじゅんまい', '天の戸']::TEXT[]
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

-- ao-tokubetsu-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'ao-tokubetsu-junmai',
  '阿櫻 特別純米',
  'Ao Tokubetsu Junmai',
  'sake',
  'Tokubetsu Junmai',
  '秋田・阿櫻の特別純米。柔らかな米の旨みと穏やかな酸がバランス良い。',
  NULL,
  15,
  'Japan',
  '阿櫻酒造',
  ARRAY['あおうとくべつじゅんまい', '阿櫻']::TEXT[]
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

-- aramasa-no-6
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'aramasa-no-6',
  '新政 No.6 X-type',
  'Aramasa No.6 X-type',
  'sake',
  'Junmai',
  '6号酵母由来のフレッシュな酸と炭酸感が特徴の人気シリーズ。',
  NULL,
  13,
  'Japan',
  '新政酒造',
  ARRAY['あらまさナンバーシックス', 'No.6']::TEXT[]
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

-- aromassei-junmai-ginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'aromassei-junmai-ginjo',
  '新政 陽乃鳥',
  'Aramasa Aperitif Hinotori',
  'sake',
  'Junmai',
  '秋田・新政の貴醸酒系。濃厚な甘みと酸が絡む個性派。',
  NULL,
  13,
  'Japan',
  '新政酒造',
  ARRAY['あらまさひのとり', '陽乃鳥']::TEXT[]
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

-- bijofu-mai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'bijofu-mai',
  '美丈夫 純米吟醸 舞',
  'Bijofu Junmai Ginjo Mai',
  'sake',
  'Junmai Ginjo',
  '高知・濱川商店の美丈夫。華やかな香りと軽快な口当たり。',
  NULL,
  15,
  'Japan',
  '濱川商店',
  ARRAY['びじょうふまい', '美丈夫']::TEXT[]
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

-- born-tokusen
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'born-tokusen',
  '梵 特選',
  'Born Tokusen',
  'sake',
  'Junmai Daiginjo',
  '福井・梵の定番純米大吟醸。まろやかで香り高い国際評価の高い銘柄。',
  NULL,
  15,
  'Japan',
  '加藤吉平商店',
  ARRAY['ぼんとくせん', '梵特選']::TEXT[]
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

-- born-yumahai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'born-yumahai',
  '梵 純米大吟醸 夢吟香',
  'Born Junmai Daiginjo Yumeginjo',
  'sake',
  'Junmai Daiginjo',
  '夢吟香を使用した梵の純米大吟醸。華やかな香りと滑らかな口当たり。',
  NULL,
  15,
  'Japan',
  '加藤吉平商店',
  ARRAY['ぼんゆめぎんこう']::TEXT[]
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

-- daishichi-kimoto-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'daishichi-kimoto-junmai',
  '大七 生もと純米',
  'Daishichi Kimoto Junmai',
  'sake',
  'Junmai',
  '伝統的な生もと造りによる純米酒。温めても味わいが崩れにくい。',
  NULL,
  15,
  'Japan',
  '大七酒造',
  ARRAY['だいしちきもとじゅんまい']::TEXT[]
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

-- dassai-39
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'dassai-39',
  '獺祭 純米大吟醸 磨き三割九分',
  'Dassai 39 Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '山田錦を39%まで磨いた中核商品。華やかな香りとまろやかな旨みのバランスが良い。',
  NULL,
  16,
  'Japan',
  '旭酒造',
  ARRAY['だっさい39', 'だっさいさんわりきゅうぶ']::TEXT[]
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

-- dassai-45
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'dassai-45',
  '獺祭 純米大吟醸 磨き四割五分',
  'Dassai 45 Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '山田錦を45%まで磨いた獺祭のエントリークラス。穏やかな吟醸香と飲みやすさが特徴。',
  NULL,
  16,
  'Japan',
  '旭酒造',
  ARRAY['だっさい45', 'だっさいよんわりごぶ']::TEXT[]
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

-- denshin-rin
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'denshin-rin',
  '伝心 凛',
  'Denshin Rin',
  'sake',
  'Junmai Daiginjo',
  '福井・一本義久保本店の純米大吟醸。透明感のある味わいと爽やかな香り。',
  NULL,
  16,
  'Japan',
  '一本義久保本店',
  ARRAY['でんしんりん', '伝心凛']::TEXT[]
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

-- denshin-yuki
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'denshin-yuki',
  '伝心 雪',
  'Denshin Yuki',
  'sake',
  'Junmai',
  'みずみずしく軽快な純米酒。冷やから冷酒向きの爽やかさ。',
  NULL,
  15,
  'Japan',
  '一本義久保本店',
  ARRAY['でんしんゆき', '伝心雪']::TEXT[]
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

-- dewazakura-dewasansan
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'dewazakura-dewasansan',
  '出羽桜 出羽燦々 純米吟醸',
  'Dewazakura Dewa Sansan Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '山形県産米・出羽燦々を使った純米吟醸。クリアで爽やかな味わい。',
  NULL,
  15,
  'Japan',
  '出羽桜酒造',
  ARRAY['でわざくらでわさんさん']::TEXT[]
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

-- dewazakura-okinajozo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'dewazakura-okinajozo',
  '出羽桜 桜花吟醸 蔵出し',
  'Dewazakura Oka Ginjo',
  'sake',
  'Ginjo',
  '山形・出羽桜の代表吟醸。華やかな吟醸香で「吟醸酒ブーム」を牽引した一本。',
  NULL,
  15,
  'Japan',
  '出羽桜酒造',
  ARRAY['でわざくらおうか', '桜花吟醸']::TEXT[]
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

-- echigo-sakura
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'echigo-sakura',
  '越後桜 普通酒',
  'Echigo Sakura',
  'sake',
  'Futsushu',
  '新潟の日常酒。すっきり辛口で食卓に寄り添う。',
  NULL,
  15,
  'Japan',
  '越後桜酒造',
  ARRAY['えちござくら']::TEXT[]
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

-- fukunishiki-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'fukunishiki-junmai',
  '富久錦 純米',
  'Fukunishiki Junmai',
  'sake',
  'Junmai',
  '兵庫・富久錦の純米酒。米の甘みを素直に感じる食中酒。',
  NULL,
  15,
  'Japan',
  '富久錦',
  ARRAY['ふくにしきじゅんまい']::TEXT[]
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

-- gassan-junmai-ginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'gassan-junmai-ginjo',
  '月山 純米吟醸',
  'Gassan Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '島根・吉田酒造の月山。クリアで上品な香味の純米吟醸。',
  NULL,
  15,
  'Japan',
  '吉田酒造',
  ARRAY['がっさんじゅんまいぎんじょう']::TEXT[]
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

-- gekkeikan-horin
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'gekkeikan-horin',
  '月桂冠 鳳麟 純米大吟醸',
  'Gekkeikan Horin Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '京都・月桂冠の上位純米大吟醸。上品な香りと滑らかな甘み。',
  NULL,
  15,
  'Japan',
  '月桂冠',
  ARRAY['げっけいかんほうりん', '鳳麟']::TEXT[]
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

-- gekkeikan-tokusen
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'gekkeikan-tokusen',
  '月桂冠 特撰',
  'Gekkeikan Tokusen',
  'sake',
  'Honjozo',
  '全国で親しまれる特撰本醸造。穏やかでバランスの良い味わい。',
  NULL,
  15,
  'Japan',
  '月桂冠',
  ARRAY['げっけいかんとくせん']::TEXT[]
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

-- hakkaisan-ginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'hakkaisan-ginjo',
  '八海山 吟醸',
  'Hakkaisan Ginjo',
  'sake',
  'Ginjo',
  '淡麗でキレのある味わい。居酒屋から家庭まで広く親しまれる新潟の代表吟醸。',
  NULL,
  15.5,
  'Japan',
  '八海醸造',
  ARRAY['はっかいさんぎんじょう']::TEXT[]
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

-- hakkaisan-seishu
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'hakkaisan-seishu',
  '八海山 清酒',
  'Hakkaisan Seishu',
  'sake',
  'Honjozo',
  '八海山の普通に親しまれる清酒。淡麗辛口の王道。',
  NULL,
  15.5,
  'Japan',
  '八海醸造',
  ARRAY['はっかいさんせいしゅ']::TEXT[]
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

-- hakkaisan-tokubetsu-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'hakkaisan-tokubetsu-junmai',
  '八海山 特別純米酒',
  'Hakkaisan Tokubetsu Junmai',
  'sake',
  'Tokubetsu Junmai',
  '雪国新潟の軟水仕込み。淡麗辛口で食事と合わせやすい八海山の定番純米。',
  NULL,
  15.5,
  'Japan',
  '八海醸造',
  ARRAY['はっかいさんとくべつじゅんまい']::TEXT[]
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

-- hakurakusei-junmai-ginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'hakurakusei-junmai-ginjo',
  '伯楽星 純米吟醸',
  'Hakurakusei Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '宮城・新澤醸造店の伯楽星。透明感のある香味で人気の純米吟醸。',
  NULL,
  15,
  'Japan',
  '新澤醸造店',
  ARRAY['はくらくせい', '伯楽星']::TEXT[]
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

-- hakushika-sho-ume
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'hakushika-sho-ume',
  '白鶴 翔 純米大吟醸',
  'Hakutsuru Sho Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '白鶴の上位純米大吟醸。繊細な香りと上品な甘みが広がる。',
  NULL,
  15.5,
  'Japan',
  '白鶴酒造',
  ARRAY['はくつるしょう']::TEXT[]
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

-- hakushika-tokubetsu-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'hakushika-tokubetsu-junmai',
  '白鶴 特撰 純米酒',
  'Hakutsuru Tokusen Junmai',
  'sake',
  'Junmai',
  '神戸・白鶴の定番純米。穏やかな香りとすっきりした飲み口で幅広い料理に合う。',
  NULL,
  15,
  'Japan',
  '白鶴酒造',
  ARRAY['はくつるじゅんまい']::TEXT[]
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

-- hiroki-junmai-ginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'hiroki-junmai-ginjo',
  '飛露喜 純米吟醸',
  'Hiroki Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '華やかな香りと軽快な甘み。飛露喜らしい透明感のある純米吟醸。',
  NULL,
  16,
  'Japan',
  '廣木酒造本店',
  ARRAY['ひろきじゅんまいぎんじょう']::TEXT[]
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

-- hiroki-tokubetsu-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'hiroki-tokubetsu-junmai',
  '飛露喜 特別純米',
  'Hiroki Tokubetsu Junmai',
  'sake',
  'Tokubetsu Junmai',
  '福島・廣木酒造の人気酒。みずみずしくキレのある味わいで入手困難でも知られる。',
  NULL,
  16,
  'Japan',
  '廣木酒造本店',
  ARRAY['ひろきとくべつじゅんまい', '飛露喜']::TEXT[]
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

-- ichinokura-mukansa
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'ichinokura-mukansa',
  '一ノ蔵 無鑑査 本醸造 辛口',
  'Ichinokura Mukansa Honjozo Karakuchi',
  'sake',
  'Honjozo',
  '宮城・一ノ蔵の定番辛口本醸造。キレがあり冷酒から燗まで対応。',
  NULL,
  15,
  'Japan',
  '一ノ蔵',
  ARRAY['いちのくらむかんさ', '無鑑査']::TEXT[]
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

-- ichinokura-suisen
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'ichinokura-suisen',
  '一ノ蔵 翠すいせん',
  'Ichinokura Suisen',
  'sake',
  'Junmai Ginjo',
  '爽やかな香りの純米吟醸。軽快で飲みやすい。',
  NULL,
  15,
  'Japan',
  '一ノ蔵',
  ARRAY['いちのくらすいせん']::TEXT[]
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

-- isoijiman-junmai-daiginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'isoijiman-junmai-daiginjo',
  '磯自慢 純米大吟醸',
  'Isojiman Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '静岡・磯自慢の純米大吟醸。上品な香りとキレのある後味が特徴。',
  NULL,
  16,
  'Japan',
  '磯自慢酒造',
  ARRAY['いそじまんじゅんまいだいぎんじょう']::TEXT[]
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

-- isoijiman-tokubetsu-honjozo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'isoijiman-tokubetsu-honjozo',
  '磯自慢 特別本醸造',
  'Isojiman Tokubetsu Honjozo',
  'sake',
  'Tokubetsu Honjozo',
  'すっきり辛口で食事を引き立てる磯自慢の日常酒。',
  NULL,
  15.5,
  'Japan',
  '磯自慢酒造',
  ARRAY['いそじまとくべつほんじょうぞう']::TEXT[]
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

-- jikon-junmai-ginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'jikon-junmai-ginjo',
  '而今 純米吟醸',
  'Jikon Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '三重・而今の人気純米吟醸。果実香とジューシーな甘酸が魅力。',
  NULL,
  16,
  'Japan',
  '木屋正酒造',
  ARRAY['じこんじゅんまいぎんじょう', '而今']::TEXT[]
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

-- jozen-mizunogotoshi-junmai-daiginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'jozen-mizunogotoshi-junmai-daiginjo',
  '上善如水 純米大吟醸',
  'Jozen Mizunogotoshi Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '上善如水の純米大吟醸。華やかな香りと滑らかな甘み。',
  NULL,
  15,
  'Japan',
  '白瀧酒造',
  ARRAY['じょうぜんじゅんまいだいぎんじょう']::TEXT[]
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

-- juyondai-hakuryu
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'juyondai-hakuryu',
  '十四代 白龍',
  'Juyondai Hakuryu',
  'sake',
  'Ginjo',
  '十四代の吟醸酒。フルーティーな香りと柔らかい甘みが人気。',
  NULL,
  15,
  'Japan',
  '高木酒造',
  ARRAY['じゅうよんだいはくりゅう', '白龍']::TEXT[]
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

-- juyondai-nakadori-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'juyondai-nakadori-junmai',
  '十四代 中取り純米',
  'Juyondai Nakadori Junmai',
  'sake',
  'Junmai',
  '中取りのみを瓶詰めした純米酒。米の旨みと柔らかな酸のバランスが良い。',
  NULL,
  15,
  'Japan',
  '高木酒造',
  ARRAY['じゅうよんだいなかどりじゅんまい']::TEXT[]
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

-- juyondai-ryugetsu
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'juyondai-ryugetsu',
  '十四代 龍月',
  'Juyondai Ryugetsu',
  'sake',
  'Junmai Daiginjo',
  '十四代の上位純米大吟醸。豊かな香りと甘旨の余韻が長く続く。',
  NULL,
  16,
  'Japan',
  '高木酒造',
  ARRAY['じゅうよんだいりゅうげつ', '龍月']::TEXT[]
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

-- kamikokoro-koon
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'kamikokoro-koon',
  '嘉美心 純米',
  'Kamikokoro Junmai',
  'sake',
  'Junmai',
  '岡山・嘉美心の純米酒。柔らかい口当たりと穏やかな香り。',
  NULL,
  15,
  'Japan',
  '嘉美心酒造',
  ARRAY['かみこころじゅんまい']::TEXT[]
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

-- katsuyama-lei
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'katsuyama-lei',
  '勝山 純米吟醸 献',
  'Katsuyama Junmai Ginjo Lei',
  'sake',
  'Junmai Ginjo',
  '宮城・勝山の純米吟醸。エレガントな香りと繊細な味わい。',
  NULL,
  16,
  'Japan',
  '勝山酒造',
  ARRAY['かつやまけん', '勝山献']::TEXT[]
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

-- keigetsu-yuzu
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'keigetsu-yuzu',
  '桂月 純米大吟醸 吟之夢',
  'Keigetsu Junmai Daiginjo Gin-no-Yume',
  'sake',
  'Junmai Daiginjo',
  '高知・土佐酒造の純米大吟醸。華やかでクリアな味わい。',
  NULL,
  15,
  'Japan',
  '土佐酒造',
  ARRAY['けいげつぎんのゆめ']::TEXT[]
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

-- kenbishi-kuromatsu-tokujo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'kenbishi-kuromatsu-tokujo',
  '剣菱 黒松特上',
  'Kenbishi Kuromatsu Tokujo',
  'sake',
  'Honjozo',
  '黒松剣菱の上位版。まろやかさとコクが増した燗上がりする酒質。',
  NULL,
  15.8,
  'Japan',
  '剣菱酒造',
  ARRAY['けんびしくろまつとくじょう']::TEXT[]
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

-- kenbishi-kuromatsu
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'kenbishi-kuromatsu',
  '剣菱 黒松',
  'Kenbishi Kuromatsu',
  'sake',
  'Futsushu',
  '兵庫・剣菱のロングセラー。濃醇で燗酒向きの伝統的な味わい。',
  NULL,
  15.5,
  'Japan',
  '剣菱酒造',
  ARRAY['けんびしくろまつ', '黒松剣菱']::TEXT[]
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

-- kikumasamune-tokubetsu-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'kikumasamune-tokubetsu-junmai',
  '菊正宗 特別純米 嘉宝',
  'Kikumasamune Tokubetsu Junmai',
  'sake',
  'Tokubetsu Junmai',
  '兵庫・菊正宗の特別純米。米の旨みとまろやかなコクが楽しめる。',
  NULL,
  15,
  'Japan',
  '菊正宗酒造',
  ARRAY['きくまさむねとくべつじゅんまい']::TEXT[]
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

-- kokuryu-ishidaya
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'kokuryu-ishidaya',
  '黒龍 石田屋',
  'Kokuryu Ishidaya',
  'sake',
  'Junmai Daiginjo',
  '黒龍の最高峰クラス。濃密でありながら綺麗な味わいで、熟成感も楽しめる。',
  NULL,
  15,
  'Japan',
  '黒龍酒造',
  ARRAY['こくりゅういしだや', '石田屋']::TEXT[]
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

-- kokuryu-junmai-ginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'kokuryu-junmai-ginjo',
  '黒龍 純米吟醸',
  'Kokuryu Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '福井・黒龍の純米吟醸。上品な吟醸香とふくらみのある旨みが特徴。',
  NULL,
  15,
  'Japan',
  '黒龍酒造',
  ARRAY['こくりゅうじゅんまいぎんじょう']::TEXT[]
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

-- koshi-no-kanbai-bessen
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'koshi-no-kanbai-bessen',
  '越乃寒梅 別撰',
  'Koshi no Kanbai Bessen',
  'sake',
  'Ginjo',
  '特撰よりさらに香り高く、まろやかな別撰。贈答でも人気。',
  NULL,
  16,
  'Japan',
  '石本酒造',
  ARRAY['こしのかんばいべっせん']::TEXT[]
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

-- koshi-no-kanbai-ordinary
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'koshi-no-kanbai-ordinary',
  '越乃寒梅 普通酒',
  'Koshi no Kanbai Futsushu',
  'sake',
  'Futsushu',
  '日常使いの淡麗辛口。冷や・燗どちらでもキレが良い。',
  NULL,
  15,
  'Japan',
  '石本酒造',
  ARRAY['こしのかんばいふつうしゅ']::TEXT[]
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

-- koshi-no-kanbai-tokusen
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'koshi-no-kanbai-tokusen',
  '越乃寒梅 特撰',
  'Koshi no Kanbai Tokusen',
  'sake',
  'Ginjo',
  '新潟を代表する淡麗辛口。特撰は香りとコクを少し高めた定番。',
  NULL,
  15,
  'Japan',
  '石本酒造',
  ARRAY['こしのかんばいとくせん', '越乃寒梅']::TEXT[]
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

-- kubota-hyakuju
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'kubota-hyakuju',
  '久保田 百寿',
  'Kubota Hyakuju',
  'sake',
  'Honjozo',
  'すっきりとした辛口本醸造。冷やからぬる燗まで幅広く楽しめる。',
  NULL,
  15,
  'Japan',
  '朝日酒造',
  ARRAY['くぼたひゃくじゅ', '百寿']::TEXT[]
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

-- kubota-senju
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'kubota-senju',
  '久保田 千寿',
  'Kubota Senju',
  'sake',
  'Ginjo',
  '吟醸香を控えめに抑え、淡麗辛口に仕上げた久保田シリーズの日常酒。',
  NULL,
  15,
  'Japan',
  '朝日酒造',
  ARRAY['くぼたせんじゅ', '千寿']::TEXT[]
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

-- kubota-suiju
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'kubota-suiju',
  '久保田 翠寿',
  'Kubota Suiju',
  'sake',
  'Daiginjo',
  '久保田の大吟醸生酒。みずみずしい果実香とキレの良さが際立つ。',
  NULL,
  15,
  'Japan',
  '朝日酒造',
  ARRAY['くぼたすいじゅ', '翠寿']::TEXT[]
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

-- masumi-karakuchi-kiippon
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'masumi-karakuchi-kiippon',
  '真澄 辛口生一本',
  'Masumi Karakuchi Kiippon',
  'sake',
  'Junmai',
  '長野・真澄の定番純米。すっきり辛口で食事を邪魔しない。',
  NULL,
  15,
  'Japan',
  '宮坂醸造',
  ARRAY['ますみからくちきいっぽん']::TEXT[]
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

-- masumi-sanka
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'masumi-sanka',
  '真澄 山花',
  'Masumi Sanka',
  'sake',
  'Junmai Daiginjo',
  '真澄の純米大吟醸。優雅な香りと繊細な味わい。',
  NULL,
  15,
  'Japan',
  '宮坂醸造',
  ARRAY['ますみさんか', '山花']::TEXT[]
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

-- minami-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'minami-junmai',
  '南 純米酒',
  'Minami Junmai',
  'sake',
  'Junmai',
  '高知・南酒造場の純米酒。力強い旨みとキレの良さが同居する。',
  NULL,
  16,
  'Japan',
  '南酒造場',
  ARRAY['みなみじゅんまい', '南']::TEXT[]
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

-- nabeshima-junmai-daiginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'nabeshima-junmai-daiginjo',
  '鍋島 純米大吟醸',
  'Nabeshima Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '鍋島の上位純米大吟醸。芳醇な香りと洗練された甘み。',
  NULL,
  16,
  'Japan',
  '富久千代酒造',
  ARRAY['なべしまじゅんまいだいぎんじょう']::TEXT[]
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

-- nanbu-bijin-junmai-daiginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'nanbu-bijin-junmai-daiginjo',
  '南部美人 純米大吟醸',
  'Nanbu Bijin Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '南部美人の純米大吟醸。華やかで繊細、余韻が綺麗。',
  NULL,
  16,
  'Japan',
  '南部美人',
  ARRAY['なんぶびじんじゅんまいだいぎんじょう']::TEXT[]
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

-- nishi-no-sekai-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'nishi-no-sekai-junmai',
  '西の関 手造り純米',
  'Nishinoseki Handmade Junmai',
  'sake',
  'Junmai',
  '大分・西の関の手造り純米。米の旨みがしっかりと感じられる。',
  NULL,
  15,
  'Japan',
  '萱島酒造',
  ARRAY['にしのせきじゅんまい']::TEXT[]
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

-- oimatsu-junmai-daiginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'oimatsu-junmai-daiginjo',
  '大七 純米大吟醸',
  'Daishichi Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '福島・大七の生もと造り純米大吟醸。力強い旨みと奥行きのある酸が特徴。',
  NULL,
  15,
  'Japan',
  '大七酒造',
  ARRAY['だいしちじゅんまいだいぎんじょう']::TEXT[]
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

-- ozeki-karatamba
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'ozeki-karatamba',
  '大関 辛丹波',
  'Ozeki Karatamba',
  'sake',
  'Honjozo',
  '兵庫・大関の辛口本醸造。食事に寄り添うキレのある辛口。',
  NULL,
  15,
  'Japan',
  '大関',
  ARRAY['おおぜきからたんば', '辛丹波']::TEXT[]
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

-- ozeki-osakaya-chosuke
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'ozeki-osakaya-chosuke',
  '大関 純米大吟醸 大阪屋長兵衛',
  'Ozeki Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '大関の純米大吟醸。華やかな香りとまろやかなコク。',
  NULL,
  15.5,
  'Japan',
  '大関',
  ARRAY['おおぜきじゅんまいだいぎんじょう']::TEXT[]
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

-- sake-akita-homare
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-akita-homare',
  '秋田誉 純米吟醸',
  'Akita Homare Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '秋田誉の純米吟醸。穏やかな香りとまろやかな旨み。',
  NULL,
  15,
  'Japan',
  '秋田誉酒造',
  ARRAY['あきたほまれじゅんまいぎんじょう']::TEXT[]
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

-- sake-asabiraki-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-asabiraki-junmai',
  'あさ開 純米酒',
  'Asabiraki Junmai',
  'sake',
  'Junmai',
  '岩手・あさ開の純米酒。飲みやすく日常使いしやすい。',
  NULL,
  15,
  'Japan',
  'あさ開',
  ARRAY['あさびらきじゅんまい']::TEXT[]
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

-- sake-black-gokyo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-black-gokyo',
  '五橋 純米吟醸',
  'Gokyo Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '山口・酒井酒造の五橋。バランス良く食中酒として優秀。',
  NULL,
  15,
  'Japan',
  '酒井酒造',
  ARRAY['ごきょうじゅんまいぎんじょう', '五橋']::TEXT[]
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

-- sake-dassai-migaki-sono-sa
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-dassai-migaki-sono-sa',
  '獺祭 磨き その先へ',
  'Dassai Beyond',
  'sake',
  'Junmai Daiginjo',
  '精米歩合非公開の獺祭最上位クラス。極限まで磨いた透明感と複雑味。',
  NULL,
  16,
  'Japan',
  '旭酒造',
  ARRAY['だっさいそのさきへ', 'だっさいbeyond']::TEXT[]
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

-- sake-dassai-sparkling
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-dassai-sparkling',
  '獺祭 発泡にごりスパークリング50',
  'Dassai Sparkling 50',
  'sake',
  'Junmai Daiginjo',
  '二次発酵による発泡性の純米大吟醸。フルーティーで祝祭向き。',
  NULL,
  14,
  'Japan',
  '旭酒造',
  ARRAY['だっさいすぱーくりんぐ', 'だっさい発泡']::TEXT[]
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

-- sake-hamachidori-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-hamachidori-junmai',
  '浜千鳥 純米',
  'Hamachidori Junmai',
  'sake',
  'Junmai',
  '岩手・浜千鳥の純米酒。柔らかな口当たりと穏やかな香り。',
  NULL,
  15,
  'Japan',
  '浜千鳥',
  ARRAY['はまちどりじゅんまい']::TEXT[]
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

-- sake-harugasumi-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-harugasumi-junmai',
  '春霞 純米',
  'Harugasumi Junmai',
  'sake',
  'Junmai',
  '秋田・栗林酒造店の純米酒。ふくよかな米の旨みが広がる。',
  NULL,
  15,
  'Japan',
  '栗林酒造店',
  ARRAY['はるがすみじゅんまい', '春霞']::TEXT[]
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

-- sake-hiraizumi-yamahai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-hiraizumi-yamahai',
  '飛良泉 山廃純米',
  'Hiraizumi Yamahai Junmai',
  'sake',
  'Junmai',
  '秋田・飛良泉の山廃純米。山廃らしいコクと酸が魅力。',
  NULL,
  15,
  'Japan',
  '飛良泉本舗',
  ARRAY['ひらいずみやまはい']::TEXT[]
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

-- sake-iwanoi-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-iwanoi-junmai',
  '岩の井 純米',
  'Iwanoi Junmai',
  'sake',
  'Junmai',
  '千葉・岩瀬酒造の純米酒。穏やかな旨みと飲みやすさ。',
  NULL,
  15,
  'Japan',
  '岩瀬酒造',
  ARRAY['いわのいじゅんまい']::TEXT[]
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

-- sake-kagatobi-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-kagatobi-junmai',
  '加賀鳶 純米吟醸',
  'Kagatobi Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '石川・福光屋の加賀鳶。華やかで親しみやすい純米吟醸。',
  NULL,
  15,
  'Japan',
  '福光屋',
  ARRAY['かがとびじゅんまいぎんじょう', '加賀鳶']::TEXT[]
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

-- sake-kameizumi-cel24
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-kameizumi-cel24',
  '亀泉 純米吟醸 CEL-24',
  'Kameizumi Junmai Ginjo CEL-24',
  'sake',
  'Junmai Ginjo',
  '高知・亀泉の甘口純米吟醸。パイナップルのような華やかな香りで知られる。',
  NULL,
  14,
  'Japan',
  '亀泉酒造',
  ARRAY['かめいずみせる24', 'CEL-24']::TEXT[]
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

-- sake-kariho-karakuchi
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-kariho-karakuchi',
  '刈穂 超辛口 純米',
  'Kariho Extra Dry Junmai',
  'sake',
  'Junmai',
  '秋田・刈穂の超辛口純米。キレ鋭く、刺身や塩味の料理と相性が良い。',
  NULL,
  15,
  'Japan',
  '秋田清酒',
  ARRAY['かりほちょうからくち']::TEXT[]
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

-- sake-kikuhime-ginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-kikuhime-ginjo',
  '菊姫 吟醸',
  'Kikuhime Ginjo',
  'sake',
  'Ginjo',
  '菊姫の吟醸酒。山廃蔵らしい骨格に吟醸香が乗る。',
  NULL,
  15.5,
  'Japan',
  '菊姫',
  ARRAY['きくひめぎんじょう']::TEXT[]
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

-- sake-kikuhime-yamahai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-kikuhime-yamahai',
  '菊姫 山廃純米',
  'Kikuhime Yamahai Junmai',
  'sake',
  'Junmai',
  '石川・菊姫の山廃純米。力強い酸と濃醇な旨みが特徴。',
  NULL,
  15.5,
  'Japan',
  '菊姫',
  ARRAY['きくひめやまはい']::TEXT[]
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

-- sake-nanbu-bijin-tokubetsu-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-nanbu-bijin-tokubetsu-junmai',
  '南部美人 特別純米',
  'Nanbu Bijin Tokubetsu Junmai',
  'sake',
  'Tokubetsu Junmai',
  '岩手・南部美人の特別純米。クリーンで国際的にも評価の高い酒質。',
  NULL,
  15,
  'Japan',
  '南部美人',
  ARRAY['なんぶびじんとくべつじゅんまい']::TEXT[]
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

-- sake-no-hase-kakushi
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-no-hase-kakushi',
  '鍋島 純米吟醸',
  'Nabeshima Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '佐賀・富久千代酒造の鍋島。国際コンクール受賞歴も多い華やかな純米吟醸。',
  NULL,
  16,
  'Japan',
  '富久千代酒造',
  ARRAY['なべしまじゅんまいぎんじょう', '鍋島']::TEXT[]
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

-- sake-sakehitosuji
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-sakehitosuji',
  '酒一筋 純米吟醸',
  'Sake Hitosuji Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '岡山・利守酒造の純米吟醸。フルーティーで優しい甘み。',
  NULL,
  15,
  'Japan',
  '利守酒造',
  ARRAY['さけひとすじ']::TEXT[]
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

-- sake-sawahime-tokubetsu-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-sawahime-tokubetsu-junmai',
  '澤姫 特別純米',
  'Sawahime Tokubetsu Junmai',
  'sake',
  'Tokubetsu Junmai',
  '栃木・若駒酒造の澤姫。米の旨みを丁寧に引き出した特別純米。',
  NULL,
  15,
  'Japan',
  '若駒酒造',
  ARRAY['さわひめとくべつじゅんまい']::TEXT[]
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

-- sake-shirataki-jozen
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-shirataki-jozen',
  '上善如水 純米吟醸',
  'Jozen Mizunogotoshi Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '新潟・白瀧酒造の人気銘柄。柔らかくフルーティーで初心者にも親しみやすい。',
  NULL,
  14,
  'Japan',
  '白瀧酒造',
  ARRAY['じょうぜんみずのごとし', '上善如水']::TEXT[]
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

-- sake-tamanohikari-yamahai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-tamanohikari-yamahai',
  '玉乃光 純米吟醸',
  'Tamanohikari Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '京都・玉乃光の純米吟醸。純米酒の先駆者として知られる蔵の定番。',
  NULL,
  15,
  'Japan',
  '玉乃光酒造',
  ARRAY['たまのひかりじゅんまいぎんじょう']::TEXT[]
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

-- sake-tengumai-yamahai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sake-tengumai-yamahai',
  '天狗舞 山廃純米',
  'Tengumai Yamahai Junmai',
  'sake',
  'Junmai',
  '石川・車多酒造の山廃純米。濃醇で燗向きのコクがある。',
  NULL,
  16,
  'Japan',
  '車多酒造',
  ARRAY['てんぐまいやまはい', '天狗舞']::TEXT[]
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

-- sakehitosuji-junmai-daiginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'sakehitosuji-junmai-daiginjo',
  '作 純米大吟醸 恵乃智',
  'Zaku Junmai Daiginjo Enogi',
  'sake',
  'Junmai Daiginjo',
  '三重・清水清三郎商店の人気銘柄。華やかな香りと滑らかな甘み。',
  NULL,
  16,
  'Japan',
  '清水清三郎商店',
  ARRAY['ざくえのぎ', '作恵乃智']::TEXT[]
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

-- shimeharitsuru-ginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'shimeharitsuru-ginjo',
  '〆張鶴 吟撰',
  'Shimeharitsuru Ginsen',
  'sake',
  'Ginjo',
  'すっきりとした辛口吟醸。新潟らしい淡麗でキレのある味わい。',
  NULL,
  15,
  'Japan',
  '宮尾酒造',
  ARRAY['しめはりつるぎんせん']::TEXT[]
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

-- shimeharitsuru-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'shimeharitsuru-junmai',
  '〆張鶴 純',
  'Shimeharitsuru Jun',
  'sake',
  'Junmai',
  '新潟・宮尾酒造の淡麗純米。キレがあり冷酒でも燗でも楽しめる。',
  NULL,
  15,
  'Japan',
  '宮尾酒造',
  ARRAY['しめはりつるじゅん', '〆張鶴純']::TEXT[]
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

-- suigei-junmai-ginjo-gin
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'suigei-junmai-ginjo-gin',
  '酔鯨 純米吟醸 吟麗',
  'Suigei Junmai Ginjo Ginrei',
  'sake',
  'Junmai Ginjo',
  '爽やかな香りと軽快な辛口。冷やして飲むのに向く。',
  NULL,
  16,
  'Japan',
  '酔鯨酒造',
  ARRAY['すいげいぎんれい', '吟麗']::TEXT[]
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

-- suigei-tokubetsu-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'suigei-tokubetsu-junmai',
  '酔鯨 特別純米',
  'Suigei Tokubetsu Junmai',
  'sake',
  'Tokubetsu Junmai',
  '高知・酔鯨の特別純米。キレ辛口で土佐の食文化に合う。',
  NULL,
  15,
  'Japan',
  '酔鯨酒造',
  ARRAY['すいげいとくべつじゅんまい', '酔鯨']::TEXT[]
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

-- tamanohikari-junmai-daiginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'tamanohikari-junmai-daiginjo',
  '玉乃光 純米大吟醸',
  'Tamanohikari Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '山田錦を高精白した純米大吟醸。華やかでまろやか。',
  NULL,
  15.5,
  'Japan',
  '玉乃光酒造',
  ARRAY['たまのひかりじゅんまいだいぎんじょう']::TEXT[]
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

-- tedorigawa-junmai-ginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'tedorigawa-junmai-ginjo',
  '手取川 純米吟醸',
  'Tedorigawa Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '石川県を代表する純米吟醸の一つ。上品な香りとキレ。',
  NULL,
  15,
  'Japan',
  '吉田酒造店',
  ARRAY['てどりがわじゅんまいぎんじょう']::TEXT[]
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

-- tedorigawa-yamahai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'tedorigawa-yamahai',
  '手取川 山廃純米',
  'Tedorigawa Yamahai Junmai',
  'sake',
  'Junmai',
  '石川・吉田酒造店の山廃純米。コクと酸のバランスが良い。',
  NULL,
  15,
  'Japan',
  '吉田酒造店',
  ARRAY['てどりがわやまはい']::TEXT[]
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

-- tengumai-junmai-daiginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'tengumai-junmai-daiginjo',
  '天狗舞 純米大吟醸',
  'Tengumai Junmai Daiginjo',
  'sake',
  'Junmai Daiginjo',
  '天狗舞の純米大吟醸。華やかさと骨格のある味わい。',
  NULL,
  16,
  'Japan',
  '車多酒造',
  ARRAY['てんぐまいじゅんまいだいぎんじょう']::TEXT[]
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

-- tosatsuru-ginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'tosatsuru-ginjo',
  '土佐鶴 吟醸',
  'Tosatsuru Ginjo',
  'sake',
  'Ginjo',
  '高知・土佐鶴の吟醸酒。軽快でキレがあり、食中酒として優秀。',
  NULL,
  15,
  'Japan',
  '土佐鶴酒造',
  ARRAY['とさつるぎんじょう']::TEXT[]
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

-- toyobijin-daiginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'toyobijin-daiginjo',
  '東洋美人 純米大吟醸 一番纏',
  'Toyobijin Junmai Daiginjo Ichibanmatome',
  'sake',
  'Junmai Daiginjo',
  '東洋美人の上位純米大吟醸。濃密な果実香と滑らかな口当たり。',
  NULL,
  16,
  'Japan',
  '澄川酒造場',
  ARRAY['とうようびじんいちばんまとめ']::TEXT[]
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

-- toyobijin-junmai-ginjo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'toyobijin-junmai-ginjo',
  '東洋美人 純米吟醸',
  'Toyobijin Junmai Ginjo',
  'sake',
  'Junmai Ginjo',
  '山口・澄川酒造場の東洋美人。上品な甘みと華やかな香り。',
  NULL,
  16,
  'Japan',
  '澄川酒造場',
  ARRAY['とうようびじんじゅんまいぎんじょう', '東洋美人']::TEXT[]
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

-- urakasumi-junmai
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'urakasumi-junmai',
  '浦霞 純米酒',
  'Urakasumi Junmai',
  'sake',
  'Junmai',
  '食事と合わせやすい宮城の定番純米。柔らかく飲み飽きしない。',
  NULL,
  15,
  'Japan',
  '佐浦',
  ARRAY['うらかすみじゅんまい']::TEXT[]
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

-- urakasumi-zen
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'urakasumi-zen',
  '浦霞 禅',
  'Urakasumi Zen',
  'sake',
  'Junmai Ginjo',
  '宮城・浦霞の代表純米吟醸。穏やかな吟醸香と優しい米の甘みが特徴。',
  NULL,
  15.5,
  'Japan',
  '佐浦',
  ARRAY['うらかすみぜん', '浦霞禅']::TEXT[]
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

-- zaku-ho-no-tomo
INSERT INTO drinks (slug, name, name_en, category, subcategory, description, image_url, abv, origin_country, manufacturer, aliases)
VALUES (
  'zaku-ho-no-tomo',
  '作 穂乃智',
  'Zaku Ho no Tomo',
  'sake',
  'Junmai Ginjo',
  '飲みやすい純米吟醸。優しい果実香と軽快な口当たり。',
  NULL,
  16,
  'Japan',
  '清水清三郎商店',
  ARRAY['ざくほのとも', '作穂乃智']::TEXT[]
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

