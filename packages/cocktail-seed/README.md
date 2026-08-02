# @sakehub/cocktail-seed

公式（基本）カクテルレシピの投入パイプライン。JSON データファイルを単一情報源とし、決定的な SQL を生成する。

**ランタイム依存ゼロ**（Node.js 24 の TypeScript 型剥がし実行）。本番アプリからは呼ばれないオフライン開発ツール。

## フロー

```
data/pending.txt → draft.ts（任意・LLM）→ data/drafts/*.json
       ↓ 人手レビューして移動
data/cocktails/*.json → validate.ts → build-seed.ts → supabase/seeds/official_cocktails.sql
```

`build-seed.ts` は外部通信なし・決定的。同じ JSON から常に同じ SQL を出す。

## コマンド（リポジトリルート）

```bash
pnpm seed:cocktails:validate   # DB CHECK と同等の検証
pnpm seed:cocktails:build      # official_cocktails.sql を再生成
pnpm seed:cocktails:draft      # OPENAI_API_KEY 必須。下書きのみ
```

`supabase db reset` 時は `config.toml` の `[db.seed]` が生成 SQL → `seed.sql` の順で流す。

## レビュー運用

1. `data/pending.txt` に候補を書く（`ジントニック|gin-tonic` 形式可）
2. `pnpm seed:cocktails:draft` で `data/drafts/` に出力
3. **必ず人手で**分量・手順・説明文を確認し、問題なければ `data/cocktails/` へ移動
4. `validate` → `build` → ローカルで `supabase db reset` して目視

LLM は「データを作る工程」であり、パイプラインの必須ステップではない。AGENTS.md の「LLM 呼び出しは Go API」は本番ランタイムの規約であり、本パッケージは適用外。

## 既存 8 件の UUID

デモレシピが参照する `c0c00000-0000-4000-8000-00000000000N` はデータファイルの `id` に明示して維持する。新規カクテルは `id: null` で slug から UUIDv5 を導出する。

## 運営ユーザー

生成 SQL は `official@sakehub.app` を email サブクエリで参照する（環境変数なし）。既に Auth に同メールがあればユーザー作成は no-op。
