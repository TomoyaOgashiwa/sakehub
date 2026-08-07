-- =============================================================================
-- Migration: enable_pg_trgm
-- Description: packages/drink-seed の export-demand.ts が使う類似度検索
--              （既存 drinks との重複候補チェック）のために pg_trgm を有効化する。
--              スキーマ変更なし（拡張の有効化のみ）。
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS pg_trgm;
