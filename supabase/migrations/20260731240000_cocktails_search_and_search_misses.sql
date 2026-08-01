-- =============================================================================
-- Migration: cocktails_search_and_search_misses
-- Description: cocktails 全文検索用 search_vector と、ゼロヒット検索ログ
--              search_misses（＋ Studio 用集計ビュー）を追加する。
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. cocktails.search_vector（drinks と同パターン）
-- ---------------------------------------------------------------------------
-- 'simple' 辞書: 日英混在で形態素解析に依存しない。
-- Weight: A (名前) > B (ベーススピリット) > C (説明文)
-- aliases は seed JSON のみで DB 未所持のため、将来カラム追加時に A へ合流予定。
ALTER TABLE cocktails ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('simple', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(name_en, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(base_spirit, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(description, '')), 'C')
  ) STORED;

CREATE INDEX idx_cocktails_search ON cocktails USING GIN (search_vector);

-- base_spirit フィルタ用
CREATE INDEX idx_cocktails_base_spirit ON cocktails (base_spirit);

-- ---------------------------------------------------------------------------
-- 2. search_misses（ゼロヒット検索ログ）
-- ---------------------------------------------------------------------------
CREATE TABLE search_misses (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scope            TEXT NOT NULL CHECK (scope IN ('cocktail', 'drink', 'ingredient')),
  query_raw        TEXT NOT NULL,
  query_normalized TEXT NOT NULL,
  result_count     INTEGER NOT NULL,
  user_id          UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  client_hash      TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE search_misses ADD CONSTRAINT chk_search_misses_query_raw_length
  CHECK (char_length(query_raw) >= 1 AND char_length(query_raw) <= 200);

ALTER TABLE search_misses ADD CONSTRAINT chk_search_misses_query_normalized_length
  CHECK (char_length(query_normalized) >= 2 AND char_length(query_normalized) <= 40);

ALTER TABLE search_misses ADD CONSTRAINT chk_search_misses_result_count
  CHECK (result_count >= 0);

CREATE INDEX idx_search_misses_scope_normalized
  ON search_misses (scope, query_normalized);

CREATE INDEX idx_search_misses_created_at
  ON search_misses (created_at DESC);

ALTER TABLE search_misses ENABLE ROW LEVEL SECURITY;

-- ログ書き込みのみ許可（anon / authenticated）。user_id は本人か NULL。
CREATE POLICY "search_misses_insert_public" ON search_misses
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    user_id IS NULL OR auth.uid() = user_id
  );

-- SELECT ポリシーなし: 公開クライアントから他人の検索履歴を読めない。
-- 集計は service_role / Studio / Go API 経由。

-- ---------------------------------------------------------------------------
-- 3. Studio 用ランキングビュー
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW search_miss_ranking AS
SELECT
  scope,
  query_normalized,
  COUNT(*)::INTEGER AS miss_count,
  COUNT(DISTINCT COALESCE(user_id::text, client_hash))::INTEGER AS unique_searchers,
  MAX(created_at) AS last_seen_at
FROM search_misses
WHERE result_count = 0
GROUP BY scope, query_normalized;
