-- =============================================================================
-- Migration: create_saved_drinks
-- Description: 1人1銘柄のリスト印。ratings は任意の注釈。drink_logs とは独立。
-- =============================================================================

CREATE TABLE saved_drinks (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  drink_id   UUID NOT NULL REFERENCES drinks(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, drink_id)
);

CREATE INDEX idx_saved_drinks_user_created_at ON saved_drinks (user_id, created_at DESC);
CREATE INDEX idx_saved_drinks_drink_id ON saved_drinks (drink_id);

ALTER TABLE saved_drinks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "saved_drinks_select_own" ON saved_drinks
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "saved_drinks_insert_own" ON saved_drinks
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "saved_drinks_delete_own" ON saved_drinks
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- 評価するとリストに入る。評価を消しても印は残る。
CREATE OR REPLACE FUNCTION sync_saved_drink_from_rating()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO saved_drinks (user_id, drink_id)
  VALUES (NEW.user_id, NEW.drink_id)
  ON CONFLICT (user_id, drink_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER ratings_sync_saved_drink
  AFTER INSERT OR UPDATE OF user_id, drink_id ON ratings
  FOR EACH ROW
  EXECUTE FUNCTION sync_saved_drink_from_rating();

-- リストから外すと星もコメントも消える。
CREATE OR REPLACE FUNCTION delete_rating_when_unsave()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM ratings
  WHERE user_id = OLD.user_id AND drink_id = OLD.drink_id;
  RETURN OLD;
END;
$$;

CREATE TRIGGER saved_drinks_delete_rating
  BEFORE DELETE ON saved_drinks
  FOR EACH ROW
  EXECUTE FUNCTION delete_rating_when_unsave();

-- 既存の評価済みはリスト済み。drink_logs からは移行しない。
INSERT INTO saved_drinks (user_id, drink_id, created_at)
SELECT user_id, drink_id, MIN(created_at)
FROM ratings
GROUP BY user_id, drink_id
ON CONFLICT (user_id, drink_id) DO NOTHING;
