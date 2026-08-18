-- =============================================================================
-- Migration: users_display_name_length
-- Description: display_name の上限を 50 文字に制限する。
--              空文字は既存行・signup トリガーのため許容する（下限 CHECK は足さない）。
-- =============================================================================

ALTER TABLE public.users
  ADD CONSTRAINT chk_users_display_name_length
  CHECK (char_length(display_name) <= 50);
