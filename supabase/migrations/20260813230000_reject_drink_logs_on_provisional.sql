-- Block drink_logs from attaching to provisional drinks, matching ratings.
-- drink_id is nullable (custom_drink_name path); only fire when a catalog id is set.

CREATE OR REPLACE FUNCTION reject_ref_on_provisional()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.drink_id IS NOT NULL AND EXISTS (
    SELECT 1
    FROM drinks
    WHERE id = NEW.drink_id
      AND visibility = 'provisional'
  ) THEN
    RAISE EXCEPTION 'cannot reference provisional drink';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER drink_logs_reject_provisional
  BEFORE INSERT OR UPDATE OF drink_id ON drink_logs
  FOR EACH ROW
  WHEN (NEW.drink_id IS NOT NULL)
  EXECUTE FUNCTION reject_ref_on_provisional();
