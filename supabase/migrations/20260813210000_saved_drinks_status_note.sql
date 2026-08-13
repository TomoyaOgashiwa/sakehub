-- =============================================================================
-- Migration: saved_drinks_status_note
-- Description: リスト印に意図 (drank/want) と非公開メモを載せる。
--              ratings は公開注釈のまま。drink_logs は触らない。
-- =============================================================================

ALTER TABLE saved_drinks
  ADD COLUMN status TEXT,
  ADD COLUMN note TEXT NOT NULL DEFAULT '';

-- 既存の無印行: 評価がある → drank、無い → want。未分類は作らない。
UPDATE saved_drinks s
SET status = CASE
  WHEN EXISTS (
    SELECT 1
    FROM ratings r
    WHERE r.user_id = s.user_id
      AND r.drink_id = s.drink_id
  ) THEN 'drank'
  ELSE 'want'
END
WHERE s.status IS NULL;

ALTER TABLE saved_drinks
  ALTER COLUMN status SET NOT NULL;

ALTER TABLE saved_drinks
  ADD CONSTRAINT chk_saved_drinks_status
    CHECK (status IN ('drank', 'want'));

ALTER TABLE saved_drinks
  ADD CONSTRAINT chk_saved_drinks_note_length
    CHECK (char_length(note) <= 280);

CREATE POLICY "saved_drinks_update_own" ON saved_drinks
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 評価するとリストに入る。status 欠落時は drank。既存の意図とメモは上書きしない。
CREATE OR REPLACE FUNCTION sync_saved_drink_from_rating()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO saved_drinks (user_id, drink_id, status)
  VALUES (NEW.user_id, NEW.drink_id, 'drank')
  ON CONFLICT (user_id, drink_id) DO NOTHING;
  RETURN NEW;
END;
$$;
