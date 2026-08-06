const STORAGE_KEY = 'sakehub:client-hash';

/**
 * 未ログインユーザーのゼロヒット検索を `search_miss_ranking.unique_searchers`
 * でグルーピングするための、ブラウザ単位の安定した匿名識別子を返す。
 *
 * これがないと匿名訪問者のゼロヒットはすべて `NULL` バケット
 * （ランキングビューの `COALESCE(user_id, client_hash)`）に潰れ、
 * 未ログイン由来の需要が過少に見える。値は search-miss ログに付く不透明な
 * トークンとしてだけ `localStorage` の外に出る。個人情報は含まず、
 * 端末指紋からも導出しない。
 *
 * `localStorage` が使えない場合（SSR・プライバシーモードなど）は `undefined`。
 *
 * 値は必ず `crypto.randomUUID()` で生成する（API 側も UUID 形式のみ受理）。
 * `Date.now()` 等の低エントロピーなフォールバックは `client_hash` を安易に
 * 量産・回転させやすく、`unique_searchers` を水増しする経路になるため使わない。
 * `randomUUID` が使えない環境では帰属なしのログにフォールバックする。
 */
export function getOrCreateClientHash(): string | undefined {
  if (typeof window === 'undefined') return undefined;
  if (typeof crypto === 'undefined' || !('randomUUID' in crypto)) return undefined;

  try {
    const existing = window.localStorage.getItem(STORAGE_KEY);
    if (existing) return existing;

    const id = crypto.randomUUID();
    window.localStorage.setItem(STORAGE_KEY, id);
    return id;
  } catch {
    // ストレージが無効 / 利用不可のときは帰属なしのログにフォールバックする。
    return undefined;
  }
}
