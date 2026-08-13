-- =============================================================================
-- Migration: drink_logs place + custom drink name
-- Description: カタログ外の酒名・場所を記録可能にする。drink_id は任意。
-- =============================================================================

ALTER TABLE drink_logs
  ALTER COLUMN drink_id DROP NOT NULL;

ALTER TABLE drink_logs
  ADD COLUMN custom_drink_name TEXT,
  ADD COLUMN place_name TEXT,
  ADD COLUMN place_url TEXT;

-- カタログ酒 or 自由入力のどちらか必須
ALTER TABLE drink_logs ADD CONSTRAINT chk_drink_logs_drink_identity
  CHECK (
    (drink_id IS NOT NULL AND custom_drink_name IS NULL)
    OR (drink_id IS NULL AND custom_drink_name IS NOT NULL AND char_length(btrim(custom_drink_name)) >= 1)
  );

ALTER TABLE drink_logs ADD CONSTRAINT chk_drink_logs_custom_drink_name_length
  CHECK (custom_drink_name IS NULL OR char_length(custom_drink_name) <= 200);

ALTER TABLE drink_logs ADD CONSTRAINT chk_drink_logs_place_name_length
  CHECK (place_name IS NULL OR char_length(place_name) <= 200);

ALTER TABLE drink_logs ADD CONSTRAINT chk_drink_logs_place_url_length
  CHECK (place_url IS NULL OR char_length(place_url) <= 2000);
