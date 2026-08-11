# @sakehub/catalog-image-seed

本番カタログ（`drinks` / official `cocktails`）向けの WebP 画像を OpenAI Images で生成し、Supabase Storage `catalog-images` へ投入するオフラインツール。

## フロー

```
data/priority.txt
  → generate（gpt-image-1.5 / medium / webp）→ data/staging/**（gitignore）
    → upload（service_role + prod SUPABASE_URL）→ Storage + seed JSON の imageUrl 更新
    → pnpm seed:drinks|cocktails:validate/build
    → pnpm supabase:seed:prod
```

ローカルでの目視 Quality Check / 再生成ループは当面スコープ外。API 失敗時の機械リトライのみ行う。

## コマンド（リポジトリルート）

```bash
OPENAI_API_KEY=... pnpm seed:images:generate

# prod project URL 必須（localhost はデフォルト拒否）
SUPABASE_URL=https://xxxx.supabase.co SUPABASE_SERVICE_ROLE_KEY=... \
  pnpm seed:images:upload
```

- `generate` は既存 staging をスキップする。上書きは `--force`
- `upload` は linked（prod）の `https://*.supabase.co` を想定。絶対公開 URL（`?v=<sha8>` 付き）を `imageUrl` に書き戻す
- ローカル Storage への試験投入だけは `pnpm seed:images:upload -- --allow-local`。**localhost の imageUrl を seed にコミットしないこと**
- `pnpm supabase:seed:prod` の前に validate/build を通すこと。upsert は seed の `image_url` が NULL のとき既存 URL を消さないが、prod 向け正本は常に `https://*.supabase.co/...` であること

## 費用目安

`gpt-image-1.5` medium / 1024×1024 でおおよそ **$0.034 / 枚**。Phase 1（≈80 枚・再生成なし）は **約 $2.7**。
