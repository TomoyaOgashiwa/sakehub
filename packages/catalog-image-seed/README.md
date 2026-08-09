# @sakehub/catalog-image-seed

本番カタログ（`drinks` / official `cocktails`）向けの WebP 画像を OpenAI Images で生成し、Supabase Storage `catalog-images` へ投入するオフラインツール。

## フロー

```
data/priority.txt
  → generate（gpt-image-1.5 / medium / webp）→ data/staging/**（gitignore）
  → upload（service_role）→ Storage + seed JSON の imageUrl 更新
  → pnpm seed:drinks|cocktails:validate/build
  → pnpm supabase:seed:prod
```

ローカルでの目視 Quality Check / 再生成ループは当面スコープ外。API 失敗時の機械リトライのみ行う。

## コマンド（リポジトリルート）

```bash
OPENAI_API_KEY=... pnpm seed:images:generate
SUPABASE_URL=https://xxxx.supabase.co SUPABASE_SERVICE_ROLE_KEY=... pnpm seed:images:upload
```

- `generate` は既存 staging をスキップする。上書きは `--force`
- `upload` は linked（prod）の `SUPABASE_URL` を想定。絶対公開 URL を `imageUrl` に書き戻す

## 費用目安

`gpt-image-1.5` medium / 1024×1024 でおおよそ **$0.034 / 枚**。Phase 1（≈80 枚・再生成なし）は **約 $2.7**。
