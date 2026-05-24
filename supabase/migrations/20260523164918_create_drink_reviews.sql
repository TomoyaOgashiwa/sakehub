-- =============================================================================
-- Migration: create_ratings
-- Description: ratings テーブルの作成（星評価 1-5 + コメント）
--              drinks.average_rating / total_reviews 列を削除し、
--              Go API 側で ratings からサブクエリで動的計算する方式に移行
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. ratings テーブル
-- ---------------------------------------------------------------------------
-- rating: SMALLINT (1–5) で DB レベルでも範囲を保証。
-- comment: 任意入力。DEFAULT '' で NULL を避ける。
-- UNIQUE(drink_id, user_id): 1ユーザー1ドリンクにつき1評価を保証。
--   フロントからは UPSERT で「評価の変更」を同じレコードに反映する。
-- ---------------------------------------------------------------------------
CREATE TABLE ratings (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  drink_id   UUID NOT NULL REFERENCES drinks(id) ON DELETE CASCADE,
  rating     SMALLINT NOT NULL,
  comment    TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (drink_id, user_id)
);

ALTER TABLE ratings ADD CONSTRAINT chk_ratings_rating
  CHECK (rating >= 1 AND rating <= 5);

ALTER TABLE ratings ADD CONSTRAINT chk_ratings_comment_length
  CHECK (char_length(comment) <= 1000);

-- ---------------------------------------------------------------------------
-- 2. インデックス
-- ---------------------------------------------------------------------------
CREATE INDEX idx_ratings_drink_id ON ratings (drink_id);
CREATE INDEX idx_ratings_user_id ON ratings (user_id);

-- ---------------------------------------------------------------------------
-- 3. updated_at 自動更新トリガー
-- ---------------------------------------------------------------------------
-- update_updated_at() 関数は create_drinks migration で定義済み
CREATE TRIGGER ratings_updated_at
  BEFORE UPDATE ON ratings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- 4. drinks テーブルの非正規化カラムを削除
-- ---------------------------------------------------------------------------
-- average_rating / total_reviews は ratings テーブルからサブクエリで
-- 動的に計算するため、drinks 側の列は不要になる。
-- ---------------------------------------------------------------------------
ALTER TABLE drinks DROP CONSTRAINT IF EXISTS chk_drinks_average_rating;
ALTER TABLE drinks DROP CONSTRAINT IF EXISTS chk_drinks_total_reviews;
ALTER TABLE drinks DROP COLUMN IF EXISTS average_rating;
ALTER TABLE drinks DROP COLUMN IF EXISTS total_reviews;

-- ---------------------------------------------------------------------------
-- 5. RLS (Row Level Security)
-- ---------------------------------------------------------------------------
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;

-- 認証済み・未認証ユーザーともに全評価を閲覧可能（運営公開データ）
CREATE POLICY "ratings_select_public" ON ratings
  FOR SELECT USING (true);

-- 認証済みユーザーのみ自分の評価を追加
CREATE POLICY "ratings_insert_own" ON ratings
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 自分の評価のみ更新
CREATE POLICY "ratings_update_own" ON ratings
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 自分の評価のみ削除
CREATE POLICY "ratings_delete_own" ON ratings
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);
