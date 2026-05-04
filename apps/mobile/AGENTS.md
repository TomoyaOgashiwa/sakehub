# AGENTS.md — `apps/mobile` (SakeHub Mobile)

[ルート AGENTS.md](../../AGENTS.md) を**先に**読み、本ファイルを **追加の mobile 固有ルール** として参照してください。

---

## 1. スタック概要

| 項目             | バージョン / 採用技術                                                    |
| ---------------- | ------------------------------------------------------------------------ |
| プラットフォーム | iOS / Android / Web (RNW)                                                |
| フレームワーク   | **Expo SDK 54** + **React Native 0.81**                                  |
| ルーティング     | **Expo Router v6**（ファイルベース）                                     |
| アーキテクチャ   | **New Architecture (Fabric + TurboModules) ON** (`newArchEnabled: true`) |
| 言語             | TypeScript 5.9 (strict)                                                  |
| スタイリング     | **NativeWind v4** + **Tailwind CSS v3**                                  |
| 認証 / DB        | `@supabase/supabase-js` v2                                               |
| データフェッチ   | SWR v2                                                                   |
| ランタイム要件   | Node.js 24+, iOS 15.1+, Android 7.0+ (API 24)                            |

> ⚠️ **重要バージョン制約**:
>
> - **NativeWind v4 は Tailwind CSS v3 と組み合わせて使う**。Tailwind v4 はまだ NativeWind v5（preview）でしか動かないので、**`tailwindcss@3` を維持**する。Web 側の Tailwind v4 設定をコピーしてはいけない。
> - **Reanimated v4** は NativeWind v4 と非互換のため、**Reanimated v3** を使う（追加導入時は `react-native-reanimated@3.x` を明示）。
> - **SDK 54 は Legacy Architecture を選択できる最後のバージョン**。SDK 55 以降は New Architecture 強制。新規コードは New Arch 前提で書く。
> - **Edge-to-edge レイアウトが Android のデフォルト**。`SafeAreaView` か `react-native-safe-area-context` の `SafeAreaProvider` で必ず safe area を考慮する。

---

## 2. コマンド

```bash
# 依存関係（リポジトリルートで）
pnpm install

# 開発サーバー
pnpm --filter @sakehub/mobile dev
# または
cd apps/mobile && npx expo start

# プラットフォーム起動
cd apps/mobile && npx expo start --ios       # iOS シミュレーター
cd apps/mobile && npx expo start --android   # Android エミュレーター
cd apps/mobile && npx expo start --web       # Web（Metro バンドル）

# 健全性チェック（依存とネイティブ設定の整合性）
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
├── app.json                   # Expo 設定
├── babel.config.js            # NativeWind preset 必須
├── metro.config.js            # withNativeWind ラップ必須
├── nativewind-env.d.ts        # className prop の型拡張
├── tailwind.config.ts         # ★ Tailwind v3 設定（残す）
├── global.css                 # Tailwind directives
├── tsconfig.json
└── package.json
```

---

## 4. ルーティング規約（Expo Router v6）

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

---

## 5. NativeWind v4 + Tailwind v3 規約

### セットアップ前提

- `babel.config.js`:
  ```js
  module.exports = function (api) {
    api.cache(true);
    return {
      presets: [['babel-preset-expo', { jsxImportSource: 'nativewind' }], 'nativewind/babel'],
    };
  };
  ```
- `tailwind.config.ts`:
  ```ts
  import type { Config } from 'tailwindcss';
  export default {
    content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
    presets: [require('nativewind/preset')],
    theme: { extend: {} },
    plugins: [],
  } satisfies Config;
  ```
- `metro.config.js` は `withNativeWind` で必ずラップ。
- ルートレイアウトで `import './global.css'` を **先頭** にインポート。

### 書き方ルール

- `className` prop は **`View`, `Text`, `Pressable` 等のコア RN コンポーネントに使える**（NativeWind が拡張）。サードパーティの View には `className` が効かないことがあるので、その場合は `style={{ ... }}` か `cssInterop()` を使う。
- **HTML/CSS 専用クラスは使えない**（`grid`, `flex-row` のうち RN 非対応のもの）。NativeWind ドキュメントの "Compatibility" を参照。
- ダーク対応: 既定で `userInterfaceStyle: "automatic"`。`dark:` バリアントが OS 設定に追従する。
- アニメーションは原則 React Native の `Animated` か Reanimated v3。Web の `tw-animate-css` は使えない。

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
- `expo-file-system` は SDK 54 で API 改修済み。古い記事のスニペット（`FileSystem.writeAsStringAsync`）は形が変わっている可能性あり。最新ドキュメント参照。

---

## 9. パフォーマンス / UX

- **FlatList / SectionList** を長尺リストでは必ず使う（`map` で大量レンダーしない）。`getItemLayout` を可能なら指定。
- **画像** は `expo-image` を推奨（SDK 同梱のキャッシュ・トランジション付き）。
- **アイコン** は `@expo/vector-icons`（lucide-react は React DOM 専用なので RN では使えない）。
- スクリーン遷移時の "ちらつき" 対策: `expo-splash-screen` を `useEffect` 内で `hideAsync()` するパターン。
- **Hermes エンジン** がデフォルト。`console.log` 大量出力はリリースで除去（`babel-plugin-transform-remove-console`）。

---

## 10. プラットフォーム差異

- 条件分岐は `Platform.OS === 'ios' | 'android' | 'web'` を使う。
- ファイル名サフィックスで分岐も可能: `Component.ios.tsx`, `Component.android.tsx`, `Component.web.tsx`。
- Web (RNW) ビルドでは一部 RN API（`Alert`, `LinearGradient` など）が未実装の場合あり。実機 Expo Go と Web で**両方**動作確認する。

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
❌ Tailwind v4 の `@theme` 構文を `tailwind.config.ts` に書き込む。**理由**: NativeWind v4 は Tailwind v3 前提のため、クラス生成が壊れて UI が崩れる。
❌ `react-native` を `pnpm add` で強制バージョン指定する（Expo SDK が決める）。**理由**: Expo が前提とする ABI とズレて、iOS/Android ネイティブビルドが破綻する。
❌ ルート `_layout.tsx` でセッション判定をせず各画面で個別に書く（DRY 違反）。**理由**: 画面ごとに認証ロジックが分岐し、未保護ルートやリダイレクト漏れが発生しやすい。
❌ `Reanimated v4` を新規導入する（NativeWind と非互換）。**理由**: 既知の互換性問題でスタイル反映やアニメーションが不安定になり、デバッグコストが高い。
❌ Service Role Key 等のシークレットを `EXPO_PUBLIC_*` で公開する。**理由**: 端末バンドルから容易に抽出され、バックエンド権限を奪取されるリスクがある。
❌ Edge-to-edge を無視して `padding-top` をハードコード（端末ごとに崩れる）。**理由**: ノッチ・ステータスバー差分を吸収できず、画面欠けやタップ不能領域が発生する。
