# Prompt: `/list` を自分用の深さマップにする実装 PLAN

Plan mode の最初のユーザーメッセージとして、このファイルを **この見出し以下から末尾まで** 貼る。
このファイル自体は実装プランではない。生成物は [AGENTS.md](../../AGENTS.md) の「プランの保存」に従い、**必ず** `.cursor/plans/` に markdown で残す。Cursor UI 上のドラフトだけにしない。

実装はまだしない。調査してから、このリポジトリ既存プランと同じ粒度の実装 PLAN を書く。

---

あなたは SakeHub の実装プランを書く。対象は **Web のみ**。技術スタックは現状踏襲（Next.js 16 App Router、Server Actions、Go API、Supabase）。新規外部サービスは増やさない。既存ファイルの編集を優先し、無闇に新規ファイルを増やさない。

先に読め:

- [AGENTS.md](../../AGENTS.md)
- [apps/web/AGENTS.md](../../apps/web/AGENTS.md)
- [apps/api/AGENTS.md](../../apps/api/AGENTS.md)
- 既存プランの型（同じ見出し・却下案・受け入れ条件で書く）:
  - [.cursor/plans/identify_save_list_98da0e7a.plan.md](identify_save_list_98da0e7a.plan.md)
  - [.cursor/plans/intent_list_status_note_6b916cd3.plan.md](intent_list_status_note_6b916cd3.plan.md)
  - [.cursor/plans/zero_hit_exit_b76d0d64.plan.md](zero_hit_exit_b76d0d64.plan.md)
- 主経路の現状:
  - [apps/web/src/app/list/page.tsx](../../apps/web/src/app/list/page.tsx)
  - [apps/web/src/app/list/saved-drink-row.tsx](../../apps/web/src/app/list/saved-drink-row.tsx)
  - [apps/web/src/app/profile/page.tsx](../../apps/web/src/app/profile/page.tsx)
  - [apps/web/src/app/my-logs/page.tsx](../../apps/web/src/app/my-logs/page.tsx)（`/list` へ redirect）
  - [apps/api/internal/saveddrink/](../../apps/api/internal/saveddrink/)
  - [apps/api/internal/drinklog/](../../apps/api/internal/drinklog/)
  - [packages/types/src/saved-drink.ts](../../packages/types/src/saved-drink.ts)
  - [packages/types/src/drink-log.ts](../../packages/types/src/drink-log.ts)
  - [supabase/migrations/20260813200000_create_saved_drinks.sql](../../supabase/migrations/20260813200000_create_saved_drinks.sql)
  - [supabase/migrations/20260813210000_saved_drinks_status_note.sql](../../supabase/migrations/20260813210000_saved_drinks_status_note.sql)
  - [supabase/migrations/20260811220000_create_drink_logs.sql](../../supabase/migrations/20260811220000_create_drink_logs.sql)
  - [supabase/migrations/20260811230000_drink_logs_place_and_custom_drink.sql](../../supabase/migrations/20260811230000_drink_logs_place_and_custom_drink.sql)
  - drinks の `manufacturer` / `category` / `visibility`（`published` | `provisional`）

カタログ規模の目安（シード、PLAN 時点）: 全体約 1,330。sake 200 / whisky 180 / beer 150 / wine 150 / 他は 100 以下。カテゴリ一律「200種類」は到達不能な区分がある。

---

## 検証するプロダクト仮説（固定）

再訪しない主因は「遊び心が無い」ことではなく、`/list` が時系列の行で、得意の深さが見えないことである。

カタログに紐づく過去ログも含め、**カテゴリと作り手で埋まりが見える**と、瓶が目の前に無くても `/list` を開き、同じ系統をまた特定しにいく。

今回作るのは称号ラダーではない。自分用の深さマップである。称号・バッジ棚・公開プロフィールは、この仮説が行動で当たってから別 PLAN にする。

成功の見方（PLAN の受け入れに落とす。計測基盤は新しく作らない）:

- 残した直後以外でも `/list` を開く理由がある（得意の偏り / 作り手のまとまりが見える）
- リストから同じ `manufacturer` の銘柄詳細または `/?q=` / カテゴリ検索へ戻れる
- カタログ付きの過去ログが、集計（必要ならリスト行）に含まれる
- `want` は数に入れない。飲みたいの死蔵解消は今回の主仮説ではない（薄い導線なら可）

見ないもの: 称号解除数、連日ストリーク、摂取量、公開シェア。

---

## プロダクト決定（固定。再議論しない）

既存のリスト決定を壊さない:

- トップの約束は「銘柄を特定する」。未ログインで完結。ログイン後にダッシュボード化しない。**深さマップは `/list` に置く。`/` をダッシュボードにしない。**
- ログイン後の約束は「特定した銘柄を自分のリストに残す」。日記でも、レビュー投稿が主目的でもない。
- 意図は 2 値だけ: `drank` / `want`。無印「リストに残す」を復活させない。
- リストの正は `saved_drinks`。`ratings` は公開の注釈。`drink_logs` はリストの正にしない（テーブルと API は DROP しない）。
- 1人1銘柄（カタログ ID がある行）。評価するとリストに入る、等の既存不変条件は壊さない。
- 対象は Web のみ。グローバル前提。日本向け（器・節酒・グラム）を楔にしない。
- カクテルをリストに残すのは次フェーズ。今回の集計にもカクテルを混ぜない。
- 仮の印（`visibility='provisional'`）は公開カタログの図鑑マスに数えない。リスト行としては既存どおり残してよい。
- カメラ / OCR / おすすめフィード / 公開ランキングはやらない。

今回の追加決定:

1. **深さ**が主語。全体の「お酒博士」や種類数マイスターは出さない。
2. **バッジは自分だけ。** `/profile` を社交化しない。他人に見せる UI を作らない。
3. **飲んだの定義（集計の正）:** ユニークな `drink_id`。出典は
   - `saved_drinks.status = 'drank'` かつ対象 drink が `published`、**または**
   - `drink_logs.drink_id IS NOT NULL` かつその drink が `published`
   - 同じ銘柄を何回飲んでも 1
   - `want` は数えない
   - `custom_drink_name` のみのログ（`drink_id` なし）は数えない。図鑑のマスが無い
4. **日記 UI は主経路に戻さない。** `/my-logs` の redirect、ナビから日記を消した状態を維持する。ログは数える（必要ならカタログ付きログを `drank` としてリストに出す）。入力先を `/list` にしない。
5. **ログを `saved_drinks` 行にバックフィルするかは PLAN で 1 案に決める。** 却下案も書く。制約:
   - 進捗に含めることは必須
   - リスト行に出すなら、カタログ付きログだけ `status='drank'`。既存の `want` / `note` は上書きしない
   - 自由入力ログはリスト化しない
   - `drink_logs` をリストの正にしない
6. **深さの単位は 2 段:**
   - カテゴリ: 飲んだ数 / そのカテゴリの **published** マスタ数。一番厚いカテゴリを得意として 1 行で示す
   - 作り手: 得意カテゴリ（または全体）で、同一 `manufacturer` が 2 銘柄以上あるものだけ「この蔵 N種」。シリーズエンティティは作らない（マスタにシリーズが無い）
7. **次の 1 手は薄くてよい。** その作り手の、まだ drank でない published を少数出してカタログへ戻す。レコメンドエンジンは作らない。`GET /api/drinks` の既存 `q` / `category` で足りるか、既存一覧の使い回しを先に検討する。
8. **閾値・称号・進捗バーの終点（50/100/500/1000、カテゴリ 200）は出さない。** 分母はカタログ実数。到達不能な固定段数を置かない。
9. **コピーは「記録した銘柄」「図鑑」「埋まり」に寄せる。** 「飲めば強くなる」「今夜あと 1 杯で解放」、ストリーク、弱点・ランク付けは禁止。薄いカテゴリは「まだ N 銘柄」と事実だけ。
10. リスト上限 `maxListLimit=100` と、ログ件数・カテゴリ 12 個の現実を読んで、**集計を Web のメモリ集計にするか Go の集計 API にするか** を 1 案に決める。100 件超のリスト拡張が必要なら、深さと同時にやらず範囲を明示する。

---

## 明示的にやらないこと

- 全体 / カテゴリの称号ラダー、バッジ画像、解除演出
- 公開プロフィール、他人の深さマップ、リーダーボード
- `/my-logs` 一覧の復活、銘柄ページから `/my-logs/new` へ送る
- `drink_logs` をリストの正にする、杯数・日付・場所を `/list` の必須にする
- カクテルのリスト化、Mobile、i18n
- シリーズ / 蔵マスタの新規テーブル（`manufacturer` TEXT を使う）
- `/` をログイン後ダッシュボードにする
- アルコール摂取量・純アルコール g・カレンダー Habit
- 仮の印同士を図鑑の分母や分子に入れる
- 運営マージ UI、AI 下書き

---

## PLAN に必ず含めること

既存プランと同じ型:

1. YAML frontmatter（`name`, `overview`, `todos`, `isProject: false`）
2. 対象・スタック・「新規サービスを増やさない」
3. mermaid で主経路（`/` 特定 → 銘柄 → リスト。深さマップは `/list` 上）
4. **プロダクト決定（固定）** を短く再掲
5. **データモデル決定（1案）** と **却下した案**（少なくとも: 称号テーブル、ログを正にする、日記復活、Web だけ雑に二重カウント、全カテゴリのバッジ棚）
6. 「飲んだ」union の SQL / 所有権 / 仮の印除外を具体的に
7. ログをリスト行へバックフィルする／しないの決定と、するならトリガーかワンショット migration か
8. API: 既存 `GET /api/auth/saved-drinks` を拡張するか、集計専用 endpoint か。フィーチャー間 import は原則禁止（`saveddrink` が `drink_logs` を読むなら、service の interface か SQL をそのリポジトリに閉じる方針を書く）
9. Web: `/list` の情報設計（どこに集計、どこに行、空状態、既存の status / q フィルタとの関係）。`/profile` は触らないか、リンク 1 本だけか
10. コピー案（見出し・補足・得意 1 行・作り手・空）
11. やらないこと
12. 受け入れ条件（ユーザー操作で検証できる文）
13. 実装順: (1) union 集計 (2) カテゴリ偏りと得意 (3) 作り手まとまりとカタログへ戻る。3 は 2 の前提がコード上で足りてから
14. 既存不変条件を壊さない確認（ratings トリガー、provisional、`/my-logs` redirect、トップをダッシュボード化しない）

調査で現状と矛盾したら、決定を勝手に緩めず、PLAN 末尾に「要確認」として 1 節だけ書く。本文の歴史は書き換えない（このプロンプトの決定を覆すときだけ）。

書き終わったら `.cursor/plans/` に保存する。ファイル名は `list_depth_map_<短い英数字>.plan.md`。実装は待って、PLAN の確認を求める。
