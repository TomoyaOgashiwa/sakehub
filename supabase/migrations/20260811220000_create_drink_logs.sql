-- =============================================================================
-- Migration: create_drink_logs
-- Description: 個人の飲酒量記録（プライベート）。評価 (ratings) とは分離。
-- =============================================================================

CREATE TABLE drink_logs (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  drink_id         UUID NOT NULL REFERENCES drinks(id) ON DELETE CASCADE,
  drank_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  volume_ml        NUMERIC(8, 2) NOT NULL,
  input_unit       TEXT NOT NULL,
  input_value      NUMERIC(8, 2) NOT NULL,
  serving_key      TEXT,
  volume_precision TEXT NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE drink_logs ADD CONSTRAINT chk_drink_logs_volume_ml
  CHECK (volume_ml > 0 AND volume_ml <= 2000);

ALTER TABLE drink_logs ADD CONSTRAINT chk_drink_logs_input_value
  CHECK (input_value > 0);

ALTER TABLE drink_logs ADD CONSTRAINT chk_drink_logs_input_unit
  CHECK (input_unit IN ('ml', 'oz'));

ALTER TABLE drink_logs ADD CONSTRAINT chk_drink_logs_volume_precision
  CHECK (volume_precision IN ('exact', 'estimated'));

CREATE INDEX idx_drink_logs_user_drank_at ON drink_logs (user_id, drank_at DESC);
CREATE INDEX idx_drink_logs_drink_id ON drink_logs (drink_id);

CREATE TRIGGER drink_logs_updated_at
  BEFORE UPDATE ON drink_logs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE drink_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "drink_logs_select_own" ON drink_logs
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "drink_logs_insert_own" ON drink_logs
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "drink_logs_update_own" ON drink_logs
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "drink_logs_delete_own" ON drink_logs
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);
