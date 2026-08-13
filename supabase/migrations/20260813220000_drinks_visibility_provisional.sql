-- Provisional personal marks live on drinks with visibility='provisional'.
-- Public catalog surfaces stay published-only. Merge is a later column only.

ALTER TABLE drinks
  ADD COLUMN visibility TEXT NOT NULL DEFAULT 'published',
  ADD COLUMN submitted_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN merged_into_id UUID REFERENCES drinks(id) ON DELETE SET NULL,
  ADD COLUMN name_normalized TEXT;

ALTER TABLE drinks
  ADD CONSTRAINT chk_drinks_visibility
    CHECK (visibility IN ('published', 'provisional'));

ALTER TABLE drinks
  ADD CONSTRAINT chk_drinks_visibility_owner
    CHECK (
      (visibility = 'published' AND submitted_by IS NULL)
      OR (
        visibility = 'provisional'
        AND submitted_by IS NOT NULL
        AND category = 'other'
        AND name_normalized IS NOT NULL
      )
    );

CREATE UNIQUE INDEX uq_drinks_provisional_owner_name
  ON drinks (submitted_by, name_normalized)
  WHERE visibility = 'provisional';

DROP POLICY "drinks_select_public" ON drinks;

CREATE POLICY "drinks_select_published" ON drinks
  FOR SELECT
  USING (visibility = 'published');

CREATE POLICY "drinks_select_own_provisional" ON drinks
  FOR SELECT TO authenticated
  USING (visibility = 'provisional' AND submitted_by = auth.uid());

CREATE OR REPLACE FUNCTION reject_rating_on_provisional()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM drinks
    WHERE id = NEW.drink_id
      AND visibility = 'provisional'
  ) THEN
    RAISE EXCEPTION 'cannot rate provisional drink';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER ratings_reject_provisional
  BEFORE INSERT OR UPDATE OF drink_id ON ratings
  FOR EACH ROW
  EXECUTE FUNCTION reject_rating_on_provisional();
