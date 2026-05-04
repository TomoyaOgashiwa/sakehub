# AGENTS.md — SakeHub Monorepo

このファイルはリポジトリ全体で共有する **AI コーディングエージェント向けの作業指針** です。
Claude Code / Cursor / OpenAI Codex / Gemini など [agents.md](https://agents.md/) 仕様に対応するすべてのツールが参照します。

> **スコープ規則**: より深い階層の `AGENTS.md`（例: `apps/web/AGENTS.md`）が優先されます。
> 各 app 配下の固有ルールは、その app の `AGENTS.md` に記載しています。

---

## 1. プロジェクト概要

**SakeHub** は日本酒・ウイスキー・ビール・カクテルなどお酒愛好家のためのコミュニティプラットフォームです。

| Layer           | 技術                                                                               | 補足                      |
| --------------- | ---------------------------------------------------------------------------------- | ------------------------- |
| Monorepo        | pnpm workspaces + Turborepo                                                        | `pnpm@11`, `turbo` latest |
| Web             | **Next.js 16.2 (App Router) + React 19.2 + Tailwind CSS v4 + shadcn/ui v4 + SWR**  | RSC ファースト            |
| Mobile          | **Expo SDK 54 + React Native 0.81 + NativeWind v4 (Tailwind v3) + Expo Router v6** | New Architecture 有効     |
| Backend         | **Go 1.26 + chi v5 + zap + lib/pq**                                                | クリーンアーキテクチャ    |
| Database / Auth | Supabase (PostgreSQL 15 + GoTrue)                                                  | RLS + 非対称 JWT          |
| Tooling         | Prettier (latest), prettier-plugin-tailwindcss, ESLint 9 (flat config)             | Node.js 24+ 必須          |

> ⚠️ **注意**: 現状のスタックはほぼすべて _最新メジャー_ です。古い記事や LLM 内部知識（Next.js 14、Tailwind v3 JS config、React 18、Expo 53、Go 1.21 など）の前提でコードを書かないでください。

---

## 2. 必須コマンド（Quick Reference）

すべて **リポジトリルート** から実行することを想定しています。

```bash
# 依存関係
pnpm install

# 開発サーバー（Web + Mobile を Turbo が並列起動）
pnpm dev

# 個別起動
pnpm --filter web dev              # Web → http://localhost:3000
pnpm --filter @sakehub/mobile dev  # Mobile → Expo DevTools

# Go API（別ターミナル、ホスト実行）
cd apps/api && air                 # ホットリロード（推奨）
cd apps/api && go run ./cmd/server # ホットリロードなし

# Supabase ローカルスタック
supabase start    # PostgreSQL + Studio + Auth 起動
supabase status   # キーや URL の再表示
supabase stop     # 停止

# 品質チェック
pnpm lint        # turbo lint（全 workspace）
pnpm type-check  # turbo type-check
pnpm format      # Prettier 全ファイル

# Go 単独
cd apps/api && go vet ./... && go test ./...
```

> **エージェントへ**: タスク完了前に必ず `pnpm lint` と `pnpm type-check` を、Go 変更時は `go vet ./...` を実行してください。

---

## 3. リポジトリ構成

```
sakehub/
├── apps/
│   ├── web/        # Next.js 16 (App Router) — apps/web/AGENTS.md 参照
│   ├── mobile/     # Expo (React Native) — apps/mobile/AGENTS.md 参照
│   └── api/        # Go backend — apps/api/AGENTS.md 参照
├── packages/
│   ├── types/      # Shared TypeScript types
│   ├── utils/      # Shared utilities
│   └── eslint-config/
├── supabase/       # Supabase CLI project（migrations, seed, snippets）
├── turbo.json
├── pnpm-workspace.yaml
└── .env / .env.example
```

**インポートエイリアス**:

- `apps/web`: `@/*` → `apps/web/src/*`
- `apps/mobile`: 既定設定（相対パス）
- 共通パッケージ: 現状 workspace ルートで未公開（必要時に `@sakehub/types` 等で参照）

---

## 4. 環境変数

ルート `.env` を **single source of truth** として全 app が参照します（モバイルは `EXPO_PUBLIC_*` 系のみ）。

| 変数                                                                                 | 用途                                               | 例                                                        |
| ------------------------------------------------------------------------------------ | -------------------------------------------------- | --------------------------------------------------------- |
| `NEXT_PUBLIC_SUPABASE_URL`                                                           | Supabase エンドポイント                            | `http://localhost:54321`                                  |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY`                                                      | Supabase publishable key                           | `supabase status` から取得                                |
| `SUPABASE_SERVICE_ROLE_KEY`                                                          | サーバー側でのみ使用（**クライアントに露出禁止**） | –                                                         |
| `SUPABASE_JWT_SECRET`                                                                | Go API の JWT 検証                                 | `supabase status` から取得                                |
| `DATABASE_URL`                                                                       | Go API の DB 接続                                  | `postgresql://postgres:postgres@127.0.0.1:54322/postgres` |
| `API_PORT`                                                                           | Go API ポート                                      | `8080`                                                    |
| `EXPO_PUBLIC_SUPABASE_URL` / `EXPO_PUBLIC_SUPABASE_ANON_KEY` / `EXPO_PUBLIC_API_URL` | Mobile 用（バンドルに埋め込まれる）                | –                                                         |

**ルール**:

- `.env` は **絶対にコミットしない**。`.env.example` を更新して同期する。
- `NEXT_PUBLIC_` / `EXPO_PUBLIC_` 接頭辞のキーは公開バンドルに含まれます。**シークレットを置かない**。
- 値が空・プレースホルダのまま PR を出さない。

---

## 5. 共通コーディング規約

### TypeScript（Web / Mobile / packages）

- `strict: true` 前提。`any` は原則禁止（ESLint で warn）。明確な理由がある場合のみ局所利用。
- 関数コンポーネントと React Hooks のみ。クラスコンポーネントは作らない。
- `type` と `interface` は **オブジェクト形のものは `interface`、それ以外（Union, Mapped）は `type`** を基本とする。共通 props は `interface XxxProps`。
- `import type { ... }` を使い、型と値のインポートを分離する。
- ファイル/ディレクトリ命名は **kebab-case**（例: `user-profile.tsx`）。コンポーネント名は **PascalCase**。
- React の `props.children` は `React.ReactNode`、コンテナ系は `Readonly<{ children: React.ReactNode }>`。
- 早期 return を優先し、深いネストを避ける。
- 不要な `useEffect` は使わない（特に Server Components で計算可能なものは Server 側へ）。

### Prettier / ESLint

ルート `.prettierrc`:

```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "all",
  "printWidth": 100,
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

- ESLint 9 **flat config** を使用。`apps/web` は `eslint-config-next` v16 を継承。
- コミット前に `pnpm format && pnpm lint` を通す。

### Go

- `gofmt` / `goimports` を必須適用（保存時）。
- パッケージ命名: 小文字単一語。略語は `id`, `url`, `http` のように小文字統一。
- エラーは **`errors.Is` / `errors.As` で型判別**、独自エラー型は `pkg/errors.go` 等に集約予定。
- ロギングは `go.uber.org/zap` か Go 1.26 標準 `log/slog` を使用。混在させず、リポジトリ全体で **zap に統一**（Go 1.26 の `slog.MultiHandler` 等に切り替える場合は別 PR で全置換）。
- `context.Context` は **常に第一引数**。HTTP ハンドラ内で `r.Context()` を伝搬。
- リポジトリ層は `database/sql` + `lib/pq`（プレースホルダは `$1, $2`）。SQL は文字列結合せず常にプレースホルダで安全に渡す。

### Tailwind / CSS

- **Web は Tailwind CSS v4（CSS-first）**: `tailwind.config.{js,ts}` は **存在しません**。設定はすべて `apps/web/src/app/globals.css` の `@theme` ブロックに集約。
- **Mobile は NativeWind v4 + Tailwind CSS v3**: ここだけは `apps/mobile/tailwind.config.ts` を維持（NativeWind v4 は Tailwind v4 非対応）。
- 任意値や独自プロパティは `@theme` 内で `--color-foo` / `--font-bar` / `--radius-xl` 形式の CSS 変数として宣言する。
- `prettier-plugin-tailwindcss` がクラス順を自動整形するため、手動でクラス順を変更しない。

### コミット / ブランチ

- ブランチ命名: `feat/<scope>-<summary>`、`fix/...`、`chore/...`、`docs/...`。
- コミットは Conventional Commits 準拠（例: `feat(web): add login form server action`）。
- 1 PR = 1 関心事。複数アプリにまたがる変更でも論点を絞り、無関係な整形を含めない。

---

## 6. 共通アーキテクチャ原則

1. **認証の単一情報源は Supabase Auth**。
   - Web: `@supabase/ssr` で SSR / Route Handler / Server Action にまたがるセッションを Cookie で共有（`apps/web/src/lib/supabase/{client,server}.ts`）。
   - Mobile: `@supabase/supabase-js` をシングルトン化（`apps/mobile/lib/supabase.ts`）。
   - Go API: `Authorization: Bearer <access_token>` を受け取り、`SUPABASE_JWT_SECRET` で検証 → `context.Context` に user_id / role を載せる。
2. **データアクセスのデフォルトは Supabase 直アクセス（RLS で保護）**。
   - 単純な CRUD は RLS を信頼してフロントから直接 Supabase クライアントで叩く。
   - 集約・トランザクション・外部 API 連携・LLM 呼び出しなど **サーバーロジックが必要なものだけ Go API** に切り出す。
3. **Go API は薄く保つ**。レイヤは `handler → service → repository → DB`。`handler` は `net/http` 入出力のみ、`service` がドメインロジック、`repository` が SQL を担当。
4. **状態管理**:
   - サーバー状態: SWR（Web/Mobile 共通）。`useEffect` での fetch は基本書かない。
   - クライアント状態: React Hooks（`useState`/`useReducer`）が第一選択。グローバル状態が真に必要なときだけ Context を導入。
5. **型の共有**: フロントとバックで共通の DTO は `packages/types` に置く。Supabase 由来の型は `supabase gen types typescript` で生成し、`apps/web/src/types/database.ts` などに配置（未生成なら都度作成）。

---

## 7. Do / Don't

✅ **Do**

- 変更前に該当 app の `AGENTS.md` を読む。
- 既存ファイルを編集することを優先し、無闇に新規ファイルを作らない。
- Server Components / Server Actions など **サーバー側で完結できる処理はサーバー側で書く**。
- LLM が古い API を提案してきたら、必ず公式ドキュメントの 2025–2026 版を参照しなおす（特に Next.js 16 / React 19 / Tailwind v4 / Expo 54）。

❌ **Don't**

- `tailwind.config.{js,ts}` を **Web 側で復活させない**（v4 は CSS-first）。**理由**: 設定が二重化し、`@theme` と競合してユーティリティ生成が壊れる。
- React 19 で `forwardRef` を新規追加しない。`ref` は通常の prop として受けられる（既存の互換コードは残してよい）。**理由**: 旧パターンを増やすほど移行コストが上がり、型定義の見通しも悪化する。
- Service Role Key をクライアントバンドルに含めない。**理由**: 鍵が漏洩すると RLS をバイパスして全データを操作される重大インシデントになる。
- Server Component から `useState` / `useEffect` などのクライアント Hooks を呼ばない（必要時のみ `'use client'` を最小スコープで付ける）。**理由**: RSC 制約違反でビルドエラーになり、不要なクライアント化で性能も落ちる。
- `@supabase/auth-helpers-*` パッケージを新規導入しない（**deprecated**、`@supabase/ssr` を使用）。**理由**: 将来の更新で追従不能になり、認証まわりの保守性が悪化する。
- Mobile に Node.js 専用 API（`fs`, `path`, `node:crypto` 等）を持ち込まない。**理由**: RN ランタイムで動作せず、実機でクラッシュやバンドル失敗を起こす。

---

## 8. ローカル URL チートシート

| サービス        | URL                                                 |
| --------------- | --------------------------------------------------- |
| Web             | http://localhost:3000                               |
| Go API          | http://localhost:8080                               |
| Supabase API    | http://localhost:54321                              |
| Supabase Studio | http://localhost:54323                              |
| PostgreSQL      | localhost:54322                                     |
| Expo DevTools   | ターミナルに表示される QR / `http://localhost:8081` |

---

## 9. 参考リンク（最新情報の一次ソース）

- Next.js 16 リリースノート: <https://nextjs.org/blog/next-16>
- React 19: <https://react.dev/blog/2024/12/05/react-19>
- Tailwind CSS v4: <https://tailwindcss.com/blog/tailwindcss-v4>
- Expo SDK 54: <https://expo.dev/changelog/sdk-54>
- React Native New Architecture: <https://docs.expo.dev/guides/new-architecture/>
- NativeWind v4: <https://www.nativewind.dev/>
- Go 1.26 Release Notes: <https://go.dev/doc/go1.26>
- chi v5: <https://github.com/go-chi/chi>
- Supabase SSR (Next.js): <https://supabase.com/docs/guides/auth/server-side/nextjs>

---

## 10. 各 app へのポインタ

- 🌐 Web: [`apps/web/AGENTS.md`](apps/web/AGENTS.md)
- 📱 Mobile: [`apps/mobile/AGENTS.md`](apps/mobile/AGENTS.md)
- ⚙️ API: [`apps/api/AGENTS.md`](apps/api/AGENTS.md)
