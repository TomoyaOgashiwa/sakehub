-- =============================================================================
-- Migration: create_drinks
-- Description: drinks テーブルの作成（一覧・検索・フィルタ・詳細表示に必要）
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. drinks テーブル
-- ---------------------------------------------------------------------------
-- id (UUID): auto-increment INT ではなく UUID を採用。
--   分散環境で衝突しない・URL 推測攻撃を防ぐ。
-- slug (UNIQUE TEXT): SEO フレンドリーな URL `/drinks/yamazaki-12` を実現。
--   UUID を URL に露出させず、人間が読める識別子として機能する。
-- category (TEXT + CHECK): ENUM 型ではなく TEXT + CHECK 制約を採用。
--   カテゴリ追加時に ALTER TYPE + マイグレーション不要で拡張が容易。
-- subcategory: 別テーブルに切り出さず nullable TEXT。
--   現段階ではカーディナリティが低く正規化コストに見合わない。
-- name_en: 日英混在検索に対応。name は日本語表記優先で格納。
-- abv NUMERIC(4,1): 小数点1桁（例: 43.0%）。
--   FLOAT ではなく NUMERIC で丸め誤差を防ぐ。
-- average_rating / total_reviews: 非正規化した集計値。
--   一覧画面で毎回 JOIN + AVG する N+1 問題を回避。
--   将来 drink_reviews テーブル作成時にトリガーで自動更新する。
-- ---------------------------------------------------------------------------
CREATE TABLE drinks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            TEXT UNIQUE NOT NULL,
  name            TEXT NOT NULL,
  name_en         TEXT,
  category        TEXT NOT NULL,
  subcategory     TEXT,
  description     TEXT NOT NULL DEFAULT '',
  image_url       TEXT,
  abv             NUMERIC(4,1),
  origin_country  TEXT,
  manufacturer    TEXT,
  average_rating  NUMERIC(3,2) NOT NULL DEFAULT 0,
  total_reviews   INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- category の値を packages/types/src/drink.ts の DRINK_CATEGORIES ('all' を除く) と一致させる
ALTER TABLE drinks ADD CONSTRAINT chk_drinks_category
  CHECK (category IN (
    'beer', 'wine', 'whisky', 'sake', 'shochu',
    'vodka', 'gin', 'rum', 'tequila', 'brandy',
    'liqueur', 'cocktail', 'other'
  ));

-- rating は 0（レビューなし）または 1〜5 の範囲
ALTER TABLE drinks ADD CONSTRAINT chk_drinks_average_rating
  CHECK (average_rating >= 0 AND average_rating <= 5);

ALTER TABLE drinks ADD CONSTRAINT chk_drinks_total_reviews
  CHECK (total_reviews >= 0);

-- ---------------------------------------------------------------------------
-- 2. インデックス
-- ---------------------------------------------------------------------------
-- slug の UNIQUE 制約が自動で B-tree インデックスを作成するため追加不要。

-- カテゴリフィルタ: WHERE category = 'whisky' の高速化
CREATE INDEX idx_drinks_category ON drinks (category);

-- 全文検索用の generated column + GIN インデックス
-- 'simple' 辞書を使用: 日本語/英語混在で形態素解析に依存しない。
-- 日本語の本格的な全文検索が必要になったら pgroonga 拡張に切り替える。
-- Weight: A (名前) > B (製造者) > C (説明文) で名前一致を最優先。
ALTER TABLE drinks ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('simple', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(name_en, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(manufacturer, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(description, '')), 'C')
  ) STORED;

CREATE INDEX idx_drinks_search ON drinks USING GIN (search_vector);

-- ---------------------------------------------------------------------------
-- 3. RLS (Row Level Security)
-- ---------------------------------------------------------------------------
-- drinks は運営が管理するマスタデータ。
-- 読み取りは全ユーザー（anon 含む）に開放し SEO と未ログインブラウジングに対応。
-- 書き込みは service_role のみ（RLS をバイパスするため明示的な許可ポリシー不要）。
ALTER TABLE drinks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "drinks_select_public" ON drinks
  FOR SELECT USING (true);

-- ---------------------------------------------------------------------------
-- 4. updated_at 自動更新トリガー
-- ---------------------------------------------------------------------------
-- 汎用関数として作成。将来の drink_reviews 等でも再利用する。
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER drinks_updated_at
  BEFORE UPDATE ON drinks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ===========================================================================
-- 5. 将来テーブルの設計メモ（今回は作成しない）
-- ===========================================================================

-- -------------------------------------------------------------------------
-- drink_reviews: ユーザーによるお酒評価（星5つ最大）
-- -------------------------------------------------------------------------
-- CREATE TABLE drink_reviews (
--   id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   drink_id   UUID NOT NULL REFERENCES drinks(id) ON DELETE CASCADE,
--   user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
--   rating     SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
--   comment    TEXT NOT NULL DEFAULT '',
--   created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
--   updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
--   UNIQUE(drink_id, user_id)  -- 1ユーザー1ドリンクにつき1レビュー
-- );
-- → drinks.average_rating / total_reviews をトリガーで自動更新する想定:
--   INSERT/UPDATE/DELETE 時に
--   UPDATE drinks SET
--     average_rating = (SELECT AVG(rating) FROM drink_reviews WHERE drink_id = NEW.drink_id),
--     total_reviews  = (SELECT COUNT(*)     FROM drink_reviews WHERE drink_id = NEW.drink_id)
--   WHERE id = NEW.drink_id;

-- -------------------------------------------------------------------------
-- drink_flavor_profiles: フレーバー評価（レーダーチャート / 星グラフ用）
-- -------------------------------------------------------------------------
-- CREATE TABLE drink_flavor_profiles (
--   id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   drink_id     UUID NOT NULL REFERENCES drinks(id) ON DELETE CASCADE,
--   flavor_name  TEXT NOT NULL,  -- 例: 'sweetness', 'bitterness', 'body', 'aroma', 'acidity'
--   score        SMALLINT NOT NULL CHECK (score >= 1 AND score <= 5),
--   UNIQUE(drink_id, flavor_name)  -- 1ドリンク1フレーバー軸で1レコード
-- );
-- → EAV パターンではなく正規化テーブル。
--   フレーバー軸の数が飲み物カテゴリで異なるため
--   固定カラム (sweetness INT, bitterness INT, ...) ではなく行で持つ。
--   軸名を自由に追加でき、カテゴリごとに異なるフレーバー軸を柔軟に表現可能。

-- -------------------------------------------------------------------------
-- drink_logs: ユーザーの飲酒記録
-- -------------------------------------------------------------------------
-- CREATE TABLE drink_logs (
--   id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
--   drink_id   UUID NOT NULL REFERENCES drinks(id) ON DELETE CASCADE,
--   drank_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
--   created_at TIMESTAMPTZ NOT NULL DEFAULT now()
-- );
-- → ダッシュボードの頻度分析・種類別 Circle Graph・直近リストに使用。
--   drank_at を分離して「過去の記録」を遡って登録可能にする。
