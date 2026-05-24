-- =============================================================================
-- Migration: create_drink_reviews
-- Description: drink_reviews テーブルの作成（星評価 1-5）と
--              drinks.average_rating / total_reviews の自動更新トリガー
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. drink_reviews テーブル
-- ---------------------------------------------------------------------------
-- rating: SMALLINT (1–5) で DB レベルでも範囲を保証。
-- comment: 任意入力。DEFAULT '' で NULL を避ける。
-- UNIQUE(drink_id, user_id): 1ユーザー1ドリンクにつき1レビューを保証。
--   フロントからは UPSERT で「評価の変更」を同じレコードに反映する。
-- ---------------------------------------------------------------------------
CREATE TABLE drink_reviews (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  drink_id   UUID NOT NULL REFERENCES drinks(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating     SMALLINT NOT NULL,
  comment    TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (drink_id, user_id)
);

ALTER TABLE drink_reviews ADD CONSTRAINT chk_drink_reviews_rating
  CHECK (rating >= 1 AND rating <= 5);

ALTER TABLE drink_reviews ADD CONSTRAINT chk_drink_reviews_comment_length
  CHECK (char_length(comment) <= 1000);

-- ---------------------------------------------------------------------------
-- 2. インデックス
-- ---------------------------------------------------------------------------
-- drink_id での絞り込みを最適化（一覧取得の主なアクセスパターン）
CREATE INDEX idx_drink_reviews_drink_id ON drink_reviews (drink_id);

-- user_id での絞り込みを最適化（「自分のレビュー」取得用）
CREATE INDEX idx_drink_reviews_user_id ON drink_reviews (user_id);

-- ---------------------------------------------------------------------------
-- 3. updated_at 自動更新トリガー
-- ---------------------------------------------------------------------------
-- update_updated_at() 関数は create_drinks migration で定義済み
CREATE TRIGGER drink_reviews_updated_at
  BEFORE UPDATE ON drink_reviews
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- 4. drinks.average_rating / total_reviews 自動更新トリガー
-- ---------------------------------------------------------------------------
-- INSERT / UPDATE / DELETE どのタイミングでも集計を再計算して
-- drinks テーブルの非正規化カラムを最新状態に保つ。
-- SECURITY DEFINER で RLS をバイパスし、サービス側から安全に更新できる。
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_drink_rating_stats()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  target_drink_id UUID;
BEGIN
  -- DELETE の場合は OLD.drink_id、INSERT/UPDATE は NEW.drink_id を使う
  IF TG_OP = 'DELETE' THEN
    target_drink_id := OLD.drink_id;
  ELSE
    target_drink_id := NEW.drink_id;
  END IF;

  UPDATE public.drinks
  SET
    average_rating = COALESCE(
      (SELECT AVG(rating)::NUMERIC(3,2) FROM public.drink_reviews WHERE drink_id = target_drink_id),
      0
    ),
    total_reviews = (
      SELECT COUNT(*) FROM public.drink_reviews WHERE drink_id = target_drink_id
    )
  WHERE id = target_drink_id;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER drink_reviews_update_stats
  AFTER INSERT OR UPDATE OR DELETE ON drink_reviews
  FOR EACH ROW EXECUTE FUNCTION update_drink_rating_stats();

-- ---------------------------------------------------------------------------
-- 5. RLS (Row Level Security)
-- ---------------------------------------------------------------------------
ALTER TABLE drink_reviews ENABLE ROW LEVEL SECURITY;

-- 認証済みユーザー全員が全レビューを閲覧可能（運営公開データ）
-- 未認証ユーザーも一覧表示に使うため anon も含める
CREATE POLICY "drink_reviews_select_public" ON drink_reviews
  FOR SELECT USING (true);

-- 認証済みユーザーのみ自分のレビューを追加
CREATE POLICY "drink_reviews_insert_own" ON drink_reviews
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 自分のレビューのみ更新
CREATE POLICY "drink_reviews_update_own" ON drink_reviews
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 自分のレビューのみ削除
CREATE POLICY "drink_reviews_delete_own" ON drink_reviews
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);
