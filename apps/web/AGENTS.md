# AGENTS.md — `apps/web` (SakeHub Web)

[ルート AGENTS.md](../../AGENTS.md) を**先に**読み、本ファイルを **追加の web 固有ルール** として参照してください。

---

## 1. スタック概要

| 項目           | バージョン / 採用技術                                                   |
| -------------- | ----------------------------------------------------------------------- |
| フレームワーク | **Next.js 16.2** (App Router, Turbopack default, React Compiler stable) |
| React          | **19.2**                                                                |
| 言語           | TypeScript 5 (strict)                                                   |
| スタイリング   | **Tailwind CSS v4**（CSS-first / `@theme`） + `tw-animate-css`          |
| UI Kit         | **shadcn/ui v4** (style: `base-nova`, base: **Base UI**, icons: lucide) |
| データフェッチ | SWR v2（クライアント）/ `fetch` + `cache` API（サーバー）               |
| 認証 / DB      | `@supabase/ssr` + `@supabase/supabase-js` v2                            |
| ランタイム     | Node.js 24+                                                             |

> ⚠️ Next.js 16 系の前提:
>
> - **Turbopack がデフォルト bundler**（webpack 設定を新規追加しない）。
> - **React Compiler が安定**。手動の `useMemo` / `useCallback` は原則不要。最適化が必要になったら **計測してから** 入れる。
> - **Cache Components**（`"use cache"` ディレクティブ）が opt-in で利用可能。導入する場合は `next.config.ts` に `cacheComponents: true` を追加する。

---

## 2. コマンド

```bash
# 開発
pnpm --filter web dev          # http://localhost:3000

# ビルド / 本番起動
pnpm --filter web build
pnpm --filter web start

# Lint / Type Check（リポジトリルート推奨）
pnpm --filter web lint
pnpm --filter web type-check

# shadcn/ui コンポーネント追加（apps/web で実行）
cd apps/web && pnpm dlx shadcn@latest add <component>
```

---

## 3. ディレクトリ構成

```
apps/web/
├── src/
│   ├── app/
│   │   ├── (auth)/          # 認証フロー（route group）
│   │   ├── (main)/          # 認証後の画面群
│   │   │   ├── chat/
│   │   │   ├── dashboard/
│   │   │   ├── drinks/
│   │   │   └── my-cocktails/
│   │   ├── globals.css      # Tailwind v4 のエントリ + @theme
│   │   ├── layout.tsx       # RootLayout（lang="ja", fonts）
│   │   ├── page.tsx
│   │   ├── robots.ts
│   │   └── sitemap.ts
│   ├── components/
│   │   ├── layouts/         # header, footer など枠
│   │   └── ui/              # shadcn 生成コンポーネント
│   ├── config/              # サイト全体の定数（メニュー定義等）
│   ├── hooks/               # カスタム React Hooks
│   ├── lib/
│   │   ├── api-client.ts    # Go API 呼び出し
│   │   ├── supabase/{client,server}.ts
│   │   └── utils.ts         # cn() など
│   └── types/
├── components.json          # shadcn 設定
├── eslint.config.mjs        # ESLint 9 flat config
├── next.config.ts
├── postcss.config.mjs       # @tailwindcss/postcss
└── tsconfig.json            # paths: { "@/*": ["./src/*"] }
```

**ルーティング規約**:

- **App Router 前提**。`pages/` ディレクトリは作らない。
- **Route Groups** `(auth)`, `(main)` で URL に影響を与えずに layout を分割する。
- 動的セグメントは `app/drinks/[slug]/page.tsx` のように `[param]`。Next.js 16 では `params` / `searchParams` は **Promise** なので必ず `await` する。

```tsx
type PageProps = { params: Promise<{ slug: string }> };

export default async function Page({ params }: PageProps) {
  const { slug } = await params;
  // ...
}
```

---

## 4. レンダリング戦略（Next.js 16）

1. **既定はサーバーコンポーネント (RSC)**。`'use client'` は **必要最小限のリーフコンポーネント** にだけ付ける。
2. データ取得は **Server Component で `await fetch(...)` または Supabase Server Client** が第一選択。
3. クライアント側の状態・イベントが必要な場合のみ `'use client'`。
4. **動的 vs 静的**:
   - Next.js 16 は既定で **すべてリクエスト時実行（dynamic）**。静的化したい部分は **Suspense + `"use cache"` ディレクティブ**で明示する（要 `cacheComponents: true`）。
5. **`"use cache"` 例**:

   ```ts
   // app/lib/queries.ts
   import { unstable_cacheLife as cacheLife, unstable_cacheTag as cacheTag } from 'next/cache';

   export async function getDrinks() {
     'use cache';
     cacheLife('hours');
     cacheTag('drinks');
     const supabase = await createClient();
     const { data } = await supabase.from('drinks').select('*');
     return data ?? [];
   }
   ```

   - 無効化は `revalidateTag('drinks')` または Next.js 16 で導入された `updateTag('drinks', newValue)`。

6. **Streaming / Suspense** を活用し、上から順に表示できるよう `<Suspense>` 境界で重い fetch を切り出す。
7. **Metadata API** (`metadata` / `generateMetadata`) を使用。`<head>` を直接書かない。

---

## 5. React 19 ベストプラクティス

- **Server Actions** をフォーム/ミューテーションの第一選択に。
  - サーバー側関数の先頭に `'use server'` を付け、クライアントから直接呼べる。
  - **戻り値は必ず判別可能な結果オブジェクト** を返す（throw しない）:
    ```ts
    return { ok: true, data } as const;
    return { ok: false, error: 'Invalid email' } as const;
    ```
- **`useActionState`** で submit 状態をハンドリング:

  ```tsx
  'use client';
  import { useActionState } from 'react';
  import { signIn } from './actions';

  export function LoginForm() {
    const [state, formAction, isPending] = useActionState(signIn, { ok: false, error: '' });
    return (
      <form action={formAction}>
        <input name="email" type="email" />
        <input name="password" type="password" />
        <button disabled={isPending}>Sign in</button>
        {!state.ok && state.error && <p>{state.error}</p>}
      </form>
    );
  }
  ```

- **import 元は `react`**（`react-dom` ではない）。
- **uncontrolled input を優先**。アクション再描画でユーザー入力が消えないようにする。
- **`forwardRef` は使わない**。React 19 では `ref` を通常の prop として受け取れる（コンポーネント引数で `function Foo({ ref, ...props })`）。
- **`use()`** はプロミスやコンテキストを条件分岐内でも読み取れる新しい API。Server から渡された Promise を Client Component で開く用途に活用。
- **`useOptimistic`** で楽観的 UI を実装する。
- **`<form action={...}>`** ネイティブ統合を優先（`onSubmit` で fetch するのは旧パターン）。

---

## 6. Tailwind CSS v4

**最重要**: `tailwind.config.{js,ts}` は **存在しない / 作らない**。すべて CSS で完結。

`apps/web/src/app/globals.css`:

```css
@import 'tailwindcss';
@import 'tw-animate-css';
@import 'shadcn/tailwind.css';

@custom-variant dark (&:is(.dark *));

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  /* ... トークンは CSS 変数として宣言する */
}
```

**ルール**:

- 新しいデザイントークンは `@theme` ブロック内で `--color-*`, `--font-*`, `--spacing-*`, `--radius-*` 形式で宣言する。
- ライト/ダーク値は `:root` と `.dark` の CSS 変数で切り替える（既存パターンを踏襲）。
- 任意の値は **アービトラリ値** `bg-[oklch(0.7_0.18_250)]` ではなく **`@theme` でのトークン化** を優先（再利用性のため）。
- PostCSS 設定は `@tailwindcss/postcss` のみ（`autoprefixer` は不要、Lightning CSS が処理）。
- ブラウザ要件: Safari 16.4+, Chrome 111+, Firefox 128+。古い IE / 低バージョン Safari は対象外。

---

## 7. shadcn/ui v4

`components.json`（既設）:

```json
{
  "style": "base-nova",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true
  },
  "iconLibrary": "lucide",
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  }
}
```

- `style: "base-nova"` の場合、プリミティブは **Base UI**（`@base-ui/react`）を使用。`@radix-ui/*` を新規追加しない。
- 新規コンポーネントは **必ず CLI で生成**:
  ```bash
  pnpm dlx shadcn@latest add button card dialog
  ```
- 生成された `src/components/ui/*.tsx` は手で大胆に書き換えてよい（コピーオン書き込み）。
- アイコンは `lucide-react` 一択。Heroicons / FontAwesome を混ぜない。
- バリアントは `class-variance-authority`、結合は `tailwind-merge` + `clsx` をラップした `cn()`（`@/lib/utils`）を使う。

---

## 8. データフェッチ

### サーバー側（推奨）

```tsx
// Server Component
import { createClient } from '@/lib/supabase/server';

export default async function DrinksPage() {
  const supabase = await createClient();
  const { data: drinks } = await supabase.from('drinks').select('*').order('created_at');
  return <DrinkList drinks={drinks ?? []} />;
}
```

### クライアント側（必要なときだけ）

- リアルタイム更新やユーザー操作で再取得する場合のみ SWR を使う。
- キーは **配列形式**で構造化:
  ```ts
  const { data } = useSWR(['drinks', filter], ([, f]) => fetchDrinks(f));
  ```
- グローバル設定（リトライ、`revalidateOnFocus` など）は `app/swr-config.tsx` を作って `<SWRConfig>` で囲む。

### Go API 呼び出し

- 共通クライアント `src/lib/api-client.ts` を経由する。
- ベース URL は `process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8080'`。
- 認証必須エンドポイントは `Authorization: Bearer ${supabaseAccessToken}` を付与。

---

## 9. Supabase 認証パターン

- **クライアント**: `createClient()` from `@/lib/supabase/client` をブラウザ専用コードでのみ使う。
- **サーバー / Route Handler / Server Action / Server Component**: `createClient()` from `@/lib/supabase/server` を **その都度呼ぶ**（Next.js 16 で `cookies()` は async なので await 必須）。
- セッション保護は **middleware** または各 layout の冒頭で `supabase.auth.getUser()` を呼んでリダイレクト判定。`getSession()` は cookie を信頼するため、サーバー側では `getUser()` を使う。
- `@supabase/auth-helpers-nextjs` は **deprecated**。新規コードに導入しない。

---

## 10. SEO / メタデータ

- `layout.tsx` の `metadata` を base にし、各 page で部分上書き。
- 動的タイトルは `generateMetadata` を使用（async OK）。
- `app/sitemap.ts`, `app/robots.ts` で出力済み。新ルート追加時は sitemap も更新。
- 構造化データは `src/components/json-ld.tsx` を再利用。

---

## 11. アクセシビリティ / パフォーマンス

- **画像**: 必ず `next/image` を使う（Static Optimization が効く）。
- **フォント**: `next/font/google` 経由で読み込み、CSS 変数として layout で適用（既存の Geist パターンを踏襲）。
- **アクセシビリティ**: shadcn / Base UI コンポーネントを優先（ARIA を自前で書かない）。フォーム要素には必ず `<label>` を関連付ける。
- **Core Web Vitals**: ページ表示で計測 → 必要に応じて `loading="lazy"`、`Suspense` 分割、`"use cache"` を導入。
- **`router.prefetch` の濫用禁止**: Next.js 16 は incremental prefetch が既定で動くため、明示的な prefetch は通常不要。

---

## 12. テスト方針（追加時）

- ユニット: **Vitest**（jsdom 環境）+ React Testing Library。Jest は新規導入しない。
- E2E: 必要が生じたら Playwright を `apps/web/e2e/` で導入予定。
- テストファイルは対象と同階層に `*.test.ts(x)`。

---

## 13. よくあるアンチパターン（避ける）

❌ Server Component で `useState`/`useEffect` を import してレンダーする。**理由**: RSC ではクライアント Hooks が使えず、ビルド失敗または不要なクライアント化につながる。
❌ `'use client'` を最上位 layout に貼って全画面をクライアント化する。**理由**: SSR/RSC の利点（高速初期表示・小さい JS）を失い、バンドルサイズと hydration コストが急増する。
❌ `useMemo` / `useCallback` を予防的に乱用する（React Compiler が処理する）。**理由**: 可読性だけ下がり、依存配列バグを増やす割に実測メリットが出にくい。
❌ Tailwind v3 の `@apply` / JS config 前提のスニペットをそのままコピーする。**理由**: Tailwind v4 の CSS-first 設計と不整合を起こし、スタイルが反映されない原因になる。
❌ `@radix-ui/react-*` を直接 `pnpm add` する（shadcn v4 では Base UI 経由）。**理由**: UI プリミティブが混在し、アクセシビリティ挙動とスタイル規約が崩れる。
❌ Supabase の `service_role` キーをクライアント (`'use client'`) コードから参照する。**理由**: ブラウザへ秘密鍵が漏れ、全テーブルへの特権操作を許してしまう。
❌ Server Action 内で `throw new Error(...)` してクライアントに伝播させる（→ 結果オブジェクトを返す）。**理由**: UX が不安定になり、フォームの検証エラーを安全に表示・復元しづらくなる。
