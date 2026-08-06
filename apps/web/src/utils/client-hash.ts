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
 */
export function getOrCreateClientHash(): string | undefined {
  if (typeof window === 'undefined') return undefined;

  try {
    const existing = window.localStorage.getItem(STORAGE_KEY);
    if (existing) return existing;

    const id =
      typeof crypto !== 'undefined' && 'randomUUID' in crypto
        ? crypto.randomUUID()
        : `${Date.now()}-${Math.random().toString(36).slice(2)}`;

    window.localStorage.setItem(STORAGE_KEY, id);
    return id;
  } catch {
    // ストレージが無効 / 利用不可のときは帰属なしのログにフォールバックする。
    return undefined;
  }
}
