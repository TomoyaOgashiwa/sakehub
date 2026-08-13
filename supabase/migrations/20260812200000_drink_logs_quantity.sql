-- =============================================================================
-- Migration: drink_logs quantity
-- Description: 同じ銘柄を複数杯記録できるようにする。volume_ml は1杯あたり。
-- =============================================================================

ALTER TABLE drink_logs
  ADD COLUMN quantity INTEGER NOT NULL DEFAULT 1;

ALTER TABLE drink_logs ADD CONSTRAINT chk_drink_logs_quantity
  CHECK (quantity >= 1 AND quantity <= 20);
