-- =============================================================================
-- Migration: create_users
-- Description: public.users テーブルの作成（auth.users と連携するプロフィール情報）
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. users テーブル
-- ---------------------------------------------------------------------------
-- id: auth.users(id) を FK として使用。Supabase Auth のユーザーと 1:1 対応。
-- login_type: サインアップ手段を記録。トリガーで auth.users の provider から自動設定。
-- display_name: 表示名。初期値は空文字列、ユーザーが後から設定可能。
-- ---------------------------------------------------------------------------
CREATE TABLE users (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT UNIQUE NOT NULL,
  display_name  TEXT NOT NULL DEFAULT '',
  avatar_url    TEXT,
  login_type    TEXT NOT NULL DEFAULT 'email',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE users ADD CONSTRAINT chk_users_login_type
  CHECK (login_type IN ('email', 'google', 'apple', 'github'));

-- ---------------------------------------------------------------------------
-- 2. インデックス
-- ---------------------------------------------------------------------------
-- email の UNIQUE 制約が自動で B-tree インデックスを作成するため追加不要。

-- ---------------------------------------------------------------------------
-- 3. RLS (Row Level Security)
-- ---------------------------------------------------------------------------
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_authenticated" ON users
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "users_update_own" ON users
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- 4. updated_at 自動更新トリガー
-- ---------------------------------------------------------------------------
-- update_updated_at() 関数は create_drinks migration で作成済み
CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- 5. auth.users INSERT 時に自動で public.users レコードを作成するトリガー
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.users (id, email, login_type)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_app_meta_data->>'provider', 'email')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
