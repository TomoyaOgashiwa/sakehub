---
name: Web Layout Count And Recent
overview: 銘柄トップとカクテル一覧の件数をグリッド直前へ移し、「最近残した」をページネーション下へ移す。API は触らない。
isProject: false
---

# セクション 1 — レイアウト変更

対象は **Web のみ**。トップの約束は銘柄を特定する。未ログインで完結。ログイン後はリストに残す。Mobile / i18n / 国フィルター / 度数レンジ / 説明文の日英混在は触らない。

関連プラン:

- [度数のソート](web_drinks_abv_sort.md)（件数と同じ段にセレクトを足す。同一 PR 推奨）
- [表示名編集・退会](web_profile_edit_and_delete.md)

## 目的

検索結果が何件あるかを、グリッドを見る前に分かるようにする。銘柄トップとカクテル一覧で件数位置を揃える。特定ジョブ（検索 → カテゴリ → カード）を件数より下に押し下げない。

## 現状

銘柄 [`apps/web/src/components/drinks/drink-list-client.tsx`](../../apps/web/src/components/drinks/drink-list-client.tsx):

1. 検索
2. カテゴリチップ
3. 「最近残した」（ログインかつ保存あり）
4. グリッド / ゼロ件 / スケルトン
5. 件数（`total > 0` のときだけ）
6. 前へ / 次へ（`filtered` のときだけ）

件数コピー:

- フィルタ時: `{total}件中 {offset+1}–{offset+len}件を表示`
- 棚（`q` も category も無し）: `{total}件中 {len}件を表示`

[`apps/web/src/app/page.tsx`](../../apps/web/src/app/page.tsx) の `filtered = q || (category && category !== 'all')`。未フィルタは offset を 0 に固定し、ページネーションしない。

カクテル [`apps/web/src/app/cocktails/page.tsx`](../../apps/web/src/app/cocktails/page.tsx) の `CocktailListLoader`: 件数はグリッドの下。常にレンジ文言。ページネーションは常時。検索とベーススピリットは loader の外。カクテルに「最近残した」は無い。

## 決定（固定）

- 件数は **グリッドの直前**。下部の件数文は **消す**（上下に複製しない）。下部はページネーションだけ。
- 銘柄の順序:

  1. 検索
  2. カテゴリ
  3. 件数（度数ソート導入後は、この段にソートセレクトを並べる）
  4. グリッド
  5. 前へ / 次へ
  6. 「最近残した」（あるときだけ）

- 「最近残した」は **件数の上に置かない**。`/list` にも寄せない。グリッド＋ページネーションの下へ移す。
- カクテルも件数をグリッド直前へ。検索とベーススピリットの左右配置は変えない。カクテルに度数ソートは足さない。
- 件数文言のロジック（棚 vs レンジ、`total === 0` では出さない、ローディング中も `result = data ?? fallbackData` で出す）は壊さない。
- 件数は現状の中央揃えをやめ、グリッドと同じ左起点にする（フッターに見えないようにする）。
- API 変更はしない。フロントの配置だけ。

## 実装方針

既存 JSX の並べ替えだけ。共通コンポーネント新設はしない（銘柄は棚/レンジの二系統、カクテルはレンジのみで、抽出するほどではない）。

[`drink-list-client.tsx`](../../apps/web/src/components/drinks/drink-list-client.tsx):

- 件数 `<p>` を `DrinkGrid` / `SearchZeroExit` / スケルトンの直前へ。
- 「最近残した」`<section>` をページネーションの後へ。
- `SearchMissLogger` は非表示のまま。`filtersActive={categoryFilterActive}` は維持（このセクションでは `sort` を足さない）。

[`cocktails/page.tsx`](../../apps/web/src/app/cocktails/page.tsx) の loader: 件数を `CocktailGrid` の直前へ。ページネーションは下のまま。

[`page.tsx`](../../apps/web/src/app/page.tsx) の `recentSaves` 組み立ては動かさない。

## 対象ファイル

- [`apps/web/src/components/drinks/drink-list-client.tsx`](../../apps/web/src/components/drinks/drink-list-client.tsx)（主）
- [`apps/web/src/app/cocktails/page.tsx`](../../apps/web/src/app/cocktails/page.tsx)（件数位置）
- 触らない: Go API、`/list`、カテゴリチップ、検索コンポーネント

## 受け入れ条件

- `/` で件数はカテゴリとグリッドの間。下部に同じ文が無い。
- 棚: `N件中 20件を表示`（未フィルタ・`total > 0`）。フィルタ: `N件中 1–20件を表示`。ゼロ件では件数行が無い。
- ログイン＋保存ありで「最近残した」はページネーションの下。件数より上に出ない。
- `/cocktails` でも件数がグリッド直前。フィルタ/検索の位置は現状維持。
- 未ログインの特定フロー（検索 → カード）が「最近残した」で遮られない。
- `pnpm lint` と `pnpm type-check` が通る。

## やらないこと

- 国セレクト、度数レンジ、カテゴリ横のコントロール追加
- 件数の上下複製
- カクテルの並び順変更、カクテルへの「最近残した」
- `/list` の改修、Mobile
- 棚のページネーション（それは [度数ソート](web_drinks_abv_sort.md) の `sort` 連動）

## PR

[表示名編集・退会](web_profile_edit_and_delete.md) の PR 分割どおり、このセクションは度数ソートと **同一 PR（PR-A）** にする。
