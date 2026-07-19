# SakeHub Mobile

Expo（React Native）製モバイルアプリ。iOS・Android・Web に対応します。

## 技術スタック

| 項目           | 技術                                     |
| -------------- | ---------------------------------------- |
| フレームワーク | Expo ~54 / React Native 0.81             |
| ルーティング   | Expo Router v6（ファイルベース）         |
| スタイリング   | NativeWind v5 preview（Tailwind CSS v4） |
| 認証 / DB      | Supabase JS v2                           |
| データフェッチ | SWR v2                                   |

### 前提

- Node.js 24 以上・pnpm 11 以上（リポジトリルート README を参照）。

## ディレクトリ構成

```
apps/mobile/
├── app/
│   ├── (auth)/         # 認証フロー（ログイン・登録）
│   │   ├── login.tsx
│   │   └── register.tsx
│   ├── (tabs)/         # ログイン後のタブ画面
│   │   ├── index.tsx       # ホーム / ダッシュボード
│   │   ├── chat.tsx
│   │   └── profile.tsx
│   └── _layout.tsx     # ルートレイアウト
├── components/         # 共通UIコンポーネント
├── hooks/              # カスタム React Hooks
├── lib/
│   ├── supabase.ts     # Supabase クライアント初期化
│   └── api-client.ts   # Go API クライアント
├── types/              # TypeScript 型定義
└── assets/             # 画像・フォントなどの静的アセット
```

## 環境変数

ルートの `.env` ファイルを参照します。Expo では `EXPO_PUBLIC_` プレフィックスが必要です。

| 変数名                          | 説明                                                  |
| ------------------------------- | ----------------------------------------------------- |
| `EXPO_PUBLIC_SUPABASE_URL`      | Supabase の URL（ローカル: `http://localhost:54321`） |
| `EXPO_PUBLIC_SUPABASE_ANON_KEY` | Supabase の Anon Key                                  |
| `EXPO_PUBLIC_API_URL`           | Go API の URL（ローカル: `http://localhost:8080`）    |

## 起動方法

```bash
# 依存関係インストール（プロジェクトルートで）
pnpm install

# Expo 開発サーバー起動（リポジトリルート）
pnpm dev:mobile
# または
pnpm --filter @sakehub/mobile dev
cd apps/mobile && npx expo start
```

起動後、ターミナルに QR コードが表示されます。

| 操作                   | コマンド            |
| ---------------------- | ------------------- |
| iOS シミュレーター     | `i` キーを押す      |
| Android エミュレーター | `a` キーを押す      |
| Web ブラウザ           | `w` キーを押す      |
| 実機（Expo Go）        | QR コードをスキャン |

## Supabase との連携

`lib/supabase.ts` で Supabase クライアントを初期化しています。認証トークンはセッション管理され、Expo Router のレイアウトで認証状態に応じてルートを切り替えます。
