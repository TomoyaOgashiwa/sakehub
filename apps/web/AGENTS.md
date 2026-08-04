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
# 開発（リポジトリルート推奨）
pnpm dev:web                   # http://localhost:3000
pnpm --filter web dev

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
│   │   ├── (auth)/          # 認証フロー（login / signup）
│   │   ├── api/             # Route Handlers
│   │   ├── cocktails/       # カクテル一覧・詳細・レシピ
│   │   ├── drinks/          # ドリンク詳細
│   │   ├── my-cocktails/    # 自作カクテル投稿
│   │   ├── profile/         # プロフィール
│   │   ├── globals.css      # Tailwind v4 のエントリ + @theme
│   │   ├── layout.tsx       # RootLayout（lang="ja", fonts）
│   │   ├── page.tsx
│   │   ├── robots.ts
│   │   └── sitemap.ts
│   ├── components/
│   │   ├── catalog/         # 共通カタログカード等
│   │   ├── cocktails/
│   │   ├── drinks/
│   │   ├── layouts/         # header, footer など枠
│   │   ├── ratings/
│   │   └── ui/              # shadcn 生成コンポーネント
│   ├── application/         # API / SWR / fetch に関わる処理
│   ├── config/              # サイト全体の定数（メニュー定義等）
│   ├── hooks/               # API 非依存の use* カスタム Hooks
│   ├── lib/
│   │   └── supabase/{client,server}.ts
│   ├── proxy.ts             # セッション refresh + 保護ルート（Next.js 16 proxy）
│   ├── utils/               # API 非依存かつ use* 以外のユーティリティ
│   └── types/
├── components.json          # shadcn 設定
├── eslint.config.mjs        # ESLint 9 flat config
├── next.config.ts
├── postcss.config.mjs       # @tailwindcss/postcss
└── tsconfig.json            # paths: { "@/*": ["./src/*"] }
```

**配置ルール（優先順位つき）**:

1. `useSWR` 使用、または `fetch` を使うファイルはすべて `src/application/` 配下に置く（`use*` 命名でもこちらを優先）。
2. それ以外で `use` から始まるファイル名は `src/hooks/` 配下に置く。
3. それ以外（`use*` 以外）は `src/utils/` 配下に置く。

**ルーティング規約**:

- **App Router 前提**。`pages/` ディレクトリは作らない。
- **Route Groups** は必要時に `(auth)` などで URL に影響を与えずに layout を分割する。
- 動的セグメントは `app/drinks/[slug]/page.tsx` のように `[param]`。Next.js 16 では `params` / `searchParams` は **Promise** なので必ず `await` する。
- セッション refresh / 保護ルートは `src/proxy.ts`（`middleware.ts` は使わない）。

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
   import { cacheLife, cacheTag } from 'next/cache';

   export async function getDrinks() {
     'use cache';
     cacheLife('hours');
     cacheTag('drinks');
     const supabase = await createClient();
     const { data } = await supabase.from('drinks').select('*');
     return data ?? [];
   }
   ```

   - 背景再検証は `revalidateTag('drinks', 'max')`（第2引数の `cacheLife` プロファイル必須）。
   - Server Action で即時反映（read-your-writes）が必要なら `updateTag('drinks')`。

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
    "utils": "@/utils/utils",
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
- バリアントは `class-variance-authority`、結合は `tailwind-merge` + `clsx` をラップした `cn()`（`@/utils/utils`）を使う。

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

- 共通クライアント `src/application/api-client.ts` を経由する。
- ベース URL は `process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8080'`。
- 認証必須エンドポイントは `Authorization: Bearer ${supabaseAccessToken}` を付与。

---

## 9. Supabase 認証パターン

- **クライアント**: `createClient()` from `@/lib/supabase/client` をブラウザ専用コードでのみ使う。
- **サーバー / Route Handler / Server Action / Server Component**: `createClient()` from `@/lib/supabase/server` を **その都度呼ぶ**（Next.js 16 で `cookies()` は async なので await 必須）。
- セッション保護は **`src/proxy.ts`**（cookie refresh + 保護ルート redirect）または各 layout の冒頭で `supabase.auth.getUser()` を呼んでリダイレクト判定。`getSession()` は cookie を信頼するため、サーバー側では `getUser()` を使う。
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

<!-- NEXT-AGENTS-MD-START -->[Next.js Docs Index]|root: ./node_modules/next/dist/docs|STOP. What you remember about Next.js is WRONG for this project. Always search docs and read before any task.|If docs missing, run this command first: npx @next/codemod agents-md --output AGENTS.md|01-app:{04-glossary.md}|01-app/01-getting-started:{01-installation.md,02-project-structure.md,03-layouts-and-pages.md,04-linking-and-navigating.md,05-server-and-client-components.md,06-fetching-data.md,07-mutating-data.md,08-caching.md,09-revalidating.md,10-error-handling.md,11-css.md,12-images.md,13-fonts.md,14-metadata-and-og-images.md,15-route-handlers.md,16-proxy.md,17-deploying.md,18-upgrading.md}|01-app/02-guides:{ai-agents.md,analytics.md,authentication.md,backend-for-frontend.md,caching-without-cache-components.md,cdn-caching.md,ci-build-caching.md,content-security-policy.md,css-in-js.md,custom-server.md,data-security.md,debugging.md,deploying-to-platforms.md,draft-mode.md,environment-variables.md,forms.md,how-revalidation-works.md,incremental-static-regeneration.md,instant-navigation.md,instrumentation.md,internationalization.md,json-ld.md,lazy-loading.md,local-development.md,mcp.md,mdx.md,memory-usage.md,migrating-to-cache-components.md,multi-tenant.md,multi-zones.md,open-telemetry.md,package-bundling.md,ppr-platform-guide.md,prefetching.md,preserving-ui-state.md,preventing-flash-before-hydration.md,production-checklist.md,progressive-web-apps.md,public-static-pages.md,redirecting.md,rendering-philosophy.md,sass.md,scripts.md,self-hosting.md,server-actions.md,single-page-applications.md,static-exports.md,streaming.md,tailwind-v3-css.md,third-party-libraries.md,videos.md,view-transitions.md}|01-app/02-guides/migrating:{app-router-migration.md,from-create-react-app.md,from-vite.md}|01-app/02-guides/testing:{cypress.md,jest.md,playwright.md,vitest.md}|01-app/02-guides/upgrading:{codemods.md,version-14.md,version-15.md,version-16.md}|01-app/03-api-reference:{07-edge.md,08-turbopack.md}|01-app/03-api-reference/01-directives:{use-cache-private.md,use-cache-remote.md,use-cache.md,use-client.md,use-server.md}|01-app/03-api-reference/02-components:{font.md,form.md,image.md,link.md,script.md}|01-app/03-api-reference/03-file-conventions/01-metadata:{app-icons.md,manifest.md,opengraph-image.md,robots.md,sitemap.md}|01-app/03-api-reference/03-file-conventions/02-route-segment-config:{dynamicParams.md,instant.md,maxDuration.md,preferredRegion.md,runtime.md}|01-app/03-api-reference/03-file-conventions:{default.md,dynamic-routes.md,error.md,forbidden.md,instrumentation-client.md,instrumentation.md,intercepting-routes.md,layout.md,loading.md,mdx-components.md,not-found.md,page.md,parallel-routes.md,proxy.md,public-folder.md,route-groups.md,route.md,src-folder.md,template.md,unauthorized.md}|01-app/03-api-reference/04-functions:{after.md,cacheLife.md,cacheTag.md,catchError.md,connection.md,cookies.md,draft-mode.md,fetch.md,forbidden.md,generate-image-metadata.md,generate-metadata.md,generate-sitemaps.md,generate-static-params.md,generate-viewport.md,headers.md,image-response.md,next-request.md,next-response.md,not-found.md,permanentRedirect.md,redirect.md,refresh.md,revalidatePath.md,revalidateTag.md,unauthorized.md,unstable_cache.md,unstable_noStore.md,unstable_rethrow.md,updateTag.md,use-link-status.md,use-params.md,use-pathname.md,use-report-web-vitals.md,use-router.md,use-search-params.md,use-selected-layout-segment.md,use-selected-layout-segments.md,userAgent.md}|01-app/03-api-reference/05-config/01-next-config-js:{adapterPath.md,allowedDevOrigins.md,appDir.md,assetPrefix.md,authInterrupts.md,basePath.md,cacheComponents.md,cacheHandlers.md,cacheLife.md,compress.md,crossOrigin.md,cssChunking.md,deploymentId.md,devIndicators.md,distDir.md,env.md,expireTime.md,exportPathMap.md,generateBuildId.md,generateEtags.md,headers.md,htmlLimitedBots.md,httpAgentOptions.md,images.md,incrementalCacheHandlerPath.md,inlineCss.md,logging.md,mdxRs.md,onDemandEntries.md,optimizePackageImports.md,output.md,pageExtensions.md,poweredByHeader.md,productionBrowserSourceMaps.md,proxyClientMaxBodySize.md,reactCompiler.md,reactMaxHeadersLength.md,reactStrictMode.md,redirects.md,rewrites.md,sassOptions.md,serverActions.md,serverComponentsHmrCache.md,serverExternalPackages.md,staleTimes.md,staticGeneration.md,taint.md,trailingSlash.md,transpilePackages.md,turbopack.md,turbopackFileSystemCache.md,turbopackIgnoreIssue.md,turbopackLocalPostcssConfig.md,typedRoutes.md,typescript.md,urlImports.md,useLightningcss.md,useTypeScriptCli.md,viewTransition.md,webVitalsAttribution.md,webpack.md}|01-app/03-api-reference/05-config:{02-typescript.md,03-eslint.md}|01-app/03-api-reference/06-cli:{create-next-app.md,next.md}|01-app/03-api-reference/07-adapters:{01-configuration.md,02-creating-an-adapter.md,03-api-reference.md,04-testing-adapters.md,05-routing-with-next-routing.md,06-implementing-ppr-in-an-adapter.md,07-runtime-integration.md,08-invoking-entrypoints.md,09-output-types.md,10-routing-information.md,11-use-cases.md}|02-pages/01-getting-started:{01-installation.md,02-project-structure.md,04-images.md,05-fonts.md,06-css.md,11-deploying.md}|02-pages/02-guides:{analytics.md,authentication.md,babel.md,ci-build-caching.md,content-security-policy.md,css-in-js.md,custom-server.md,debugging.md,draft-mode.md,environment-variables.md,forms.md,incremental-static-regeneration.md,instrumentation.md,internationalization.md,lazy-loading.md,mdx.md,multi-zones.md,open-telemetry.md,package-bundling.md,post-css.md,preview-mode.md,production-checklist.md,redirecting.md,sass.md,scripts.md,self-hosting.md,static-exports.md,tailwind-v3-css.md,third-party-libraries.md}|02-pages/02-guides/migrating:{app-router-migration.md,from-create-react-app.md,from-vite.md}|02-pages/02-guides/testing:{cypress.md,jest.md,playwright.md,vitest.md}|02-pages/02-guides/upgrading:{codemods.md,version-10.md,version-11.md,version-12.md,version-13.md,version-14.md,version-9.md}|02-pages/03-building-your-application/01-routing:{01-pages-and-layouts.md,02-dynamic-routes.md,03-linking-and-navigating.md,05-custom-app.md,06-custom-document.md,07-api-routes.md,08-custom-error.md}|02-pages/03-building-your-application/02-rendering:{01-server-side-rendering.md,02-static-site-generation.md,04-automatic-static-optimization.md,05-client-side-rendering.md}|02-pages/03-building-your-application/03-data-fetching:{01-get-static-props.md,02-get-static-paths.md,03-get-server-side-props.md,05-client-side.md}|02-pages/03-building-your-application/06-configuring:{12-error-handling.md}|02-pages/04-api-reference:{06-edge.md,08-turbopack.md}|02-pages/04-api-reference/01-components:{font.md,form.md,head.md,image-legacy.md,image.md,link.md,script.md}|02-pages/04-api-reference/02-file-conventions:{instrumentation.md,proxy.md,public-folder.md,src-folder.md}|02-pages/04-api-reference/03-functions:{get-initial-props.md,get-server-side-props.md,get-static-paths.md,get-static-props.md,next-request.md,next-response.md,use-params.md,use-report-web-vitals.md,use-router.md,use-search-params.md,userAgent.md}|02-pages/04-api-reference/04-config/01-next-config-js:{adapterPath.md,allowedDevOrigins.md,assetPrefix.md,basePath.md,bundlePagesRouterDependencies.md,compress.md,crossOrigin.md,deploymentId.md,devIndicators.md,distDir.md,env.md,exportPathMap.md,generateBuildId.md,generateEtags.md,headers.md,httpAgentOptions.md,images.md,logging.md,onDemandEntries.md,optimizePackageImports.md,output.md,pageExtensions.md,poweredByHeader.md,productionBrowserSourceMaps.md,proxyClientMaxBodySize.md,reactStrictMode.md,redirects.md,rewrites.md,serverExternalPackages.md,trailingSlash.md,transpilePackages.md,turbopack.md,typescript.md,urlImports.md,useLightningcss.md,useTypeScriptCli.md,webVitalsAttribution.md,webpack.md}|02-pages/04-api-reference/04-config:{01-typescript.md,02-eslint.md}|02-pages/04-api-reference/05-cli:{create-next-app.md,next.md}|02-pages/04-api-reference/06-adapters:{01-configuration.md,02-creating-an-adapter.md,03-api-reference.md,04-testing-adapters.md,05-routing-with-next-routing.md,06-implementing-ppr-in-an-adapter.md,07-runtime-integration.md,08-invoking-entrypoints.md,09-output-types.md,10-routing-information.md,11-use-cases.md}|03-architecture:{accessibility.md,fast-refresh.md,nextjs-compiler.md,supported-browsers.md}|04-community:{01-contribution-guide.md,02-rspack.md}<!-- NEXT-AGENTS-MD-END -->
