# AGENTS.md — `apps/mobile` (SakeHub Mobile)

[ルート AGENTS.md](../../AGENTS.md) を**先に**読み、本ファイルを **追加の mobile 固有ルール** として参照してください。

---

## 1. スタック概要

| 項目             | バージョン / 採用技術                                                    |
| ---------------- | ------------------------------------------------------------------------ |
| プラットフォーム | iOS / Android / Web (RNW)                                                |
| フレームワーク   | **Expo SDK 56** + **React Native 0.85**                                  |
| ルーティング     | **Expo Router ~56**（ファイルベース）                                    |
| アーキテクチャ   | **New Architecture 強制**（SDK 55+ で Legacy 不可）                      |
| 言語             | TypeScript 6 (strict)                                                    |
| スタイリング     | **NativeWind v5 (preview)** + **Tailwind CSS v4**                        |
| 認証 / DB        | `@supabase/supabase-js` v2                                               |
| データフェッチ   | SWR v2                                                                   |
| ランタイム要件   | Node.js 24+, iOS 16.4+, Android 7.0+ (API 24)                            |

> ⚠️ **重要バージョン制約**:
>
> - **NativeWind v5 は Tailwind CSS v4（CSS-first）前提**。`tailwind.config.ts` は使わず、`global.css` + `postcss.config.mjs` で設定する。ルートの `pnpm.overrides.lightningcss` は **`1.30.1` に固定**する（deserialize エラー回避）。
> - **Reanimated v4** + **`react-native-worklets`** が必須（NativeWind v5 の前提）。`npx expo install react-native-reanimated react-native-worklets` で揃える。
> - **New Architecture は強制**。`newArchEnabled` / `edgeToEdgeEnabled` は app.json に書かない（スキーマ上も禁止）。
> - **Edge-to-edge が Android のデフォルト**。ルート `_layout.tsx` で `SafeAreaProvider` を必ず使い、safe area を考慮する。
> - SDK 56 の Expo Go はストア未配信のため、本番開発は **development build**（`npx expo run:ios` / `run:android`）を前提にする。
> - 依存の追加・更新は **必ず `npx expo install`**。Dependabot / `pnpm add` 単独で `react-native` 等を上げると SDK 互換表から外れる。

---

## 2. コマンド

```bash
# 依存関係（リポジトリルートで）
pnpm install

# 開発サーバー（リポジトリルート推奨）
pnpm dev:mobile
# または
pnpm --filter @sakehub/mobile dev
cd apps/mobile && npx expo start

# プラットフォーム起動（dev build 推奨）
cd apps/mobile && npx expo start --ios       # iOS シミュレーター
cd apps/mobile && npx expo start --android   # Android エミュレーター
cd apps/mobile && npx expo start --web       # Web（Metro バンドル）

# SDK 互換バージョンへ揃える
cd apps/mobile && npx expo install --fix

# 健全性チェック（依存と app.json の整合性）
cd apps/mobile && npx expo-doctor

# Lint
pnpm --filter @sakehub/mobile lint
```

> **エージェントへ**: 依存追加は **必ず `npx expo install <pkg>`** を使う。`pnpm add` だと SDK 互換バージョンが選ばれず、ネイティブビルドが壊れる。

---

## 3. ディレクトリ構成

```
apps/mobile/
├── app/                       # Expo Router のルーティング起点
│   ├── (auth)/
│   │   ├── login.tsx
│   │   └── register.tsx
│   ├── (tabs)/
│   │   ├── _layout.tsx        # タブナビゲーション
│   │   ├── index.tsx          # ホーム
│   │   ├── chat.tsx
│   │   └── profile.tsx
│   └── _layout.tsx            # ルートレイアウト（SafeAreaProvider 等）
├── assets/                    # 画像 / フォント / アイコン
├── components/                # 共通 UI コンポーネント
├── hooks/                     # カスタム Hooks
├── lib/
│   ├── supabase.ts            # Supabase クライアント（シングルトン）
│   └── api-client.ts          # Go API クライアント
├── types/                     # 型定義
├── app.json                   # Expo 設定（splash は expo-splash-screen プラグイン）
├── babel.config.js            # babel-preset-expo のみ（NativeWind babel は不要）
├── metro.config.js            # withNativewind ラップ必須
├── postcss.config.mjs         # @tailwindcss/postcss
├── nativewind-env.d.ts        # className prop の型拡張
├── global.css                 # Tailwind v4 @import + nativewind/theme
├── tsconfig.json
└── package.json
```

---

## 4. ルーティング規約（Expo Router ~56）

- **ファイル名 = ルート**。`app/profile.tsx` → `/profile`、`app/(tabs)/index.tsx` → `/`。
- カッコ付きディレクトリ `(auth)`, `(tabs)` は **Route Groups**（URL に出ない）。
- `_layout.tsx` がそのセグメントの共通レイアウト。
- 動的ルートは `app/drinks/[id].tsx`、Catch-all は `app/blog/[...slug].tsx`。
- 画面遷移:

  ```tsx
  import { router, Link } from 'expo-router';

  // 宣言的
  <Link href="/(tabs)/profile">Profile</Link>;

  // 命令的
  router.push('/drinks/1');
  router.replace('/(auth)/login');
  router.back();
  ```

- Deep link スキームは `app.json` の `"scheme": "sakehub"`（`sakehub://drinks/1` で開ける）。
- SDK 56 以降、`expo-router` は React Navigation から分離。`@react-navigation/*` を直接 import しない（必要な場合は `npx expo-codemod sdk-56-expo-router-react-navigation-replace app`）。

---

## 5. NativeWind v5 + Tailwind v4 規約

### セットアップ前提

- `babel.config.js`（NativeWind babel / jsxImportSource は **付けない**）:
  ```js
  module.exports = function (api) {
    api.cache(true);
    return {
      presets: ['babel-preset-expo'],
    };
  };
  ```
- `global.css`:
  ```css
  @import 'tailwindcss/theme.css' layer(theme);
  @import 'tailwindcss/preflight.css' layer(base);
  @import 'tailwindcss/utilities.css';

  @import 'nativewind/theme';
  ```
- `postcss.config.mjs`:
  ```js
  export default {
    plugins: {
      '@tailwindcss/postcss': {},
    },
  };
  ```
- `metro.config.js` は `withNativewind(config)` でラップ（第 2 引数不要）。
- ルートレイアウトで `import './global.css'` を **先頭** にインポート。
- サードパーティ View への `className` は `styled()`（旧 `cssInterop` / `remapProps` は非推奨）。

### 書き方ルール

- `className` prop は **`View`, `Text`, `Pressable` 等のコア RN コンポーネントに使える**（NativeWind が import rewrite）。
- **HTML/CSS 専用クラスは使えない**（RN 非対応のもの）。NativeWind ドキュメントの "Compatibility" を参照。
- ダーク対応: 既定で `userInterfaceStyle: "automatic"`。`dark:` バリアントが OS 設定に追従する。
- アニメーションは Reanimated v4（+ worklets）。Web の `tw-animate-css` は使えない。

```tsx
import { View, Text, Pressable } from 'react-native';

export function Card({ title }: { title: string }) {
  return (
    <View className="rounded-2xl bg-white p-4 dark:bg-neutral-900">
      <Text className="text-lg font-semibold text-neutral-900 dark:text-neutral-50">{title}</Text>
      <Pressable className="mt-3 rounded-xl bg-blue-600 px-4 py-2 active:opacity-80">
        <Text className="text-center text-white">Open</Text>
      </Pressable>
    </View>
  );
}
```

---

## 6. Supabase 認証パターン

- `lib/supabase.ts` で **クライアントをシングルトン化**。
- セッション永続化は `@react-native-async-storage/async-storage` を `auth.storage` に渡す（必要時）:

  ```ts
  import 'react-native-url-polyfill/auto';
  import AsyncStorage from '@react-native-async-storage/async-storage';
  import { createClient } from '@supabase/supabase-js';

  export const supabase = createClient(
    process.env.EXPO_PUBLIC_SUPABASE_URL!,
    process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!,
    {
      auth: {
        storage: AsyncStorage,
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: false,
      },
    },
  );
  ```

- 認証状態は `app/_layout.tsx` で `supabase.auth.onAuthStateChange` を購読し、`router.replace` で `(auth)` / `(tabs)` を切り替える。
- 環境変数は **必ず `EXPO_PUBLIC_` プレフィックス**（バンドルに埋め込まれる）。Service Role Key を **絶対に** 入れない。

---

## 7. データフェッチ

- 一覧/詳細: SWR + Supabase クライアント、または Go API（`lib/api-client.ts`）。
- ミューテーション: Supabase 直 or Go API → 成功後に `mutate(key)` でリフェッチ。
- ネットワークエラーは UI で必ずハンドリング（`error` ステートをユーザーに伝える）。

```tsx
import useSWR from 'swr';
import { supabase } from '@/lib/supabase';

const fetcher = async () => {
  const { data, error } = await supabase.from('drinks').select('*');
  if (error) throw error;
  return data;
};

export function useDrinks() {
  return useSWR('drinks', fetcher);
}
```

---

## 8. ネイティブ機能の追加

- **必ず `npx expo install <pkg>`** で追加（互換バージョン解決）。
- ネイティブモジュール追加後は **Dev Client を再ビルド**（`npx expo prebuild` → `npx expo run:ios` / `run:android`）。
- カメラ・通知・位置情報など権限が必要なものは `app.json` の `plugins` セクションに設定を追加する。
- Splash はトップレベル `splash` ではなく **`expo-splash-screen` プラグイン**で設定する。
- `expo-file-system` は新 API が既定。古い記事のスニペット（`FileSystem.writeAsStringAsync`）は形が変わっている可能性あり。最新ドキュメント参照。
- アイコンを使う場合は `@expo/vector-icons` を **明示インストール**（SDK 56 で `expo` の transitive 依存から外れた）。移行先は `@react-native-vector-icons/*`。

---

## 9. パフォーマンス / UX

- **FlatList / SectionList** を長尺リストでは必ず使う（`map` で大量レンダーしない）。`getItemLayout` を可能なら指定。
- **画像** は `expo-image` を推奨（SDK 同梱のキャッシュ・トランジション付き）。
- スクリーン遷移時の "ちらつき" 対策: `expo-splash-screen` を `useEffect` 内で `hideAsync()` するパターン。
- **Hermes エンジン** がデフォルト（SDK 56 では Hermes v1 既定）。`console.log` 大量出力はリリースで除去（`babel-plugin-transform-remove-console`）。

---

## 10. プラットフォーム差異

- 条件分岐は `Platform.OS === 'ios' | 'android' | 'web'` を使う。
- ファイル名サフィックスで分岐も可能: `Component.ios.tsx`, `Component.android.tsx`, `Component.web.tsx`。
- Web (RNW) ビルドでは一部 RN API（`Alert`, `LinearGradient` など）が未実装の場合あり。dev build と Web で**両方**動作確認する。

---

## 11. アクセシビリティ

- すべての押下可能要素に `accessibilityRole`, `accessibilityLabel`, `accessibilityHint` を付ける。
- `<Pressable>` を `<TouchableOpacity>` より優先（タッチ状態 API が新しい）。
- 動的フォントサイズ（OS 設定）に追従するよう、テキストには **絶対サイズではなく** Tailwind の `text-base` 等のクラスを使う。

---

## 12. デバッグ

- **Expo DevTools** + **React Native DevTools**（Hermes 内蔵、Chrome DevTools 連携）。
- **`npx expo-doctor`** で依存と app.json の整合性を確認。
- ネイティブビルドのエラーは Xcode / Android Studio のログを直接確認するのが速い。
- Logging は `console.log` でよいが、**ストア提出ビルドからは Babel で削除**する設定を追加することを推奨。

---

## 13. アンチパターン（避ける）

❌ Web 用ライブラリ（`lucide-react`, `tw-animate-css`, `next/*`）を import する。**理由**: React Native 環境に存在しない API へ依存し、実機でクラッシュまたはバンドル失敗する。
❌ `lib/supabase.ts` を毎回 `createClient()` する（シングルトンを破壊）。**理由**: セッション監視やトークン更新が多重化し、認証不整合やメモリリークの原因になる。
❌ `tailwind.config.ts` を復活させる / NativeWind v4 の babel preset を戻す。**理由**: NativeWind v5 は CSS-first + PostCSS 前提のため、旧設定と競合してクラス生成が壊れる。
❌ `react-native` / `expo-router` 等を `pnpm add` や Dependabot で単独バンプする。**理由**: Expo SDK の互換表（`bundledNativeModules.json`）からズレてネイティブビルドが破綻する。必ず `npx expo install --fix`。
❌ ルート `_layout.tsx` でセッション判定をせず各画面で個別に書く（DRY 違反）。**理由**: 画面ごとに認証ロジックが分岐し、未保護ルートやリダイレクト漏れが発生しやすい。
❌ `react-native-worklets` なしで Reanimated v4 だけ入れる。**理由**: peer 欠落でランタイムクラッシュする。
❌ Service Role Key 等のシークレットを `EXPO_PUBLIC_*` で公開する。**理由**: 端末バンドルから容易に抽出され、バックエンド権限を奪取されるリスクがある。
❌ Edge-to-edge を無視して `padding-top` をハードコード（端末ごとに崩れる）。**理由**: ノッチ・ステータスバー差分を吸収できず、画面欠けやタップ不能領域が発生する。
