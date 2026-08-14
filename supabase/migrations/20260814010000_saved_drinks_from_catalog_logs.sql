-- =============================================================================
-- Migration: saved_drinks_from_catalog_logs
-- Description: カタログ付き drink_logs をリスト行へワンショット + トリガーで載せる。
--              リストの正は saved_drinks のまま。want / note は上書きしない。
--              自由入力ログ（drink_id なし）と provisional は対象外。
-- =============================================================================

INSERT INTO saved_drinks (user_id, drink_id, status)
SELECT DISTINCT l.user_id, l.drink_id, 'drank'
FROM drink_logs l
INNER JOIN drinks d ON d.id = l.drink_id
WHERE l.drink_id IS NOT NULL
  AND d.visibility = 'published'
ON CONFLICT (user_id, drink_id) DO NOTHING;

CREATE OR REPLACE FUNCTION sync_saved_drink_from_catalog_log()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.drink_id IS NULL THEN
    RETURN NEW;
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM drinks d
    WHERE d.id = NEW.drink_id
      AND d.visibility = 'published'
  ) THEN
    RETURN NEW;
  END IF;
  INSERT INTO saved_drinks (user_id, drink_id, status)
  VALUES (NEW.user_id, NEW.drink_id, 'drank')
  ON CONFLICT (user_id, drink_id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER drink_logs_sync_saved_drink
  AFTER INSERT OR UPDATE OF drink_id ON drink_logs
  FOR EACH ROW
  EXECUTE FUNCTION sync_saved_drink_from_catalog_log();
