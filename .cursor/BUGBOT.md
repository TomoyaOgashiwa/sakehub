# Bugbot review policy (SakeHub)

## 1. Purpose

Report only **merge-blocking or clearly harmful issues** in the PR diff.

- GitHub review comments: **Japanese**. Severity tags: English `High` / `Medium` / `Low` only.
- Prefer false negatives over false positives. When unsure, do **not** report.
- Do not discuss taste, micro-refactors, or re-litigate existing style.
- Style guides and coding conventions live elsewhere; this file is a **report filter**, not a style guide.
- Context (not duplicated here): [`AGENTS.md`](../AGENTS.md), [`apps/web/AGENTS.md`](../apps/web/AGENTS.md), [`apps/mobile/AGENTS.md`](../apps/mobile/AGENTS.md), [`apps/api/AGENTS.md`](../apps/api/AGENTS.md).

**Run cadence:** Review only on **PR creation (once per PR)**. Do not leave new findings on later pushes unless explicitly re-triggered (`bugbot run` / `cursor review`). Team/repo setting **Run once per PR** should stay enabled to match this.

## 2. Review severity (High / Medium / Low)

Use **only** these three English labels: `High`, `Medium`, `Low`. Never `Critical`, `Info`, etc.

### High — merge blocker

- AuthZ/AuthN bypass; missing session / JWT verification
- Secret exposure (Service Role Key, private keys, production credentials)
- Clear injection / XSS (SQL, command, etc.)
- Data loss or irreversible destructive ops (wrong deletes, destructive migrations)
- Changes that effectively bypass RLS
- Production-certain crash/breakage (nil panic, undefined deref, missing required env → cannot start)

### Medium — fix before merge when clear

- Logic bugs / races / double-submit that corrupt state on valid input
- Swallowed errors that hide failures
- API contract breaks (breaking response changes, missing required fields)
- Blurred auth boundaries (updating another user’s data, etc.)
- Clear perf regression with real harm (N+1, unbounded queries, huge payloads)

### Low — optional; only if clearly valuable

- Small but definite defects that are quick to fix
- Missing tests on high-regression **core** paths only
- Docs/comments that fatally contradict the implementation

**Low cap:** at most **2 Low** findings per PR. Drop the rest.

## 3. Report only if...

Report **only** when the finding matches High / Medium / Low above **and**:

1. Harm is concrete (security, correctness, data integrity, observability, or clear user-facing breakage).
2. Evidence is in the **diff** (file + location). Speculation → do not report.
3. Same root cause → **one** finding, not many variants.
4. Not already explained as an intentional tradeoff in the PR description or existing comments.

## 4. Do not report...

- Naming, formatting, import order, anything Prettier/ESLint would catch
- “Cleaner rewrite” / preferred-style refactors
- Style drift from existing patterns when the PR follows nearby code
- Tailwind class reordering; subjective component splits
- Type-strictness nits with no runtime harm (light `any`, etc.)
- Docs-only gaps
- Future extensibility / abstraction suggestions
- Known tradeoffs already called out in the PR
- Noise limited to tests, generated code, or seed micro-diffs
- “More modern” React 19 / Next.js 16 preference-level rewrites

## 5. Comment format

**Language:** Write all GitHub PR review comments in **Japanese**. This policy file may stay in English; severity labels stay English (`High` / `Medium` / `Low`). Field labels below may stay English; the title and body text must be Japanese.

Every finding **must** use:

```text
[High|Medium|Low] <短いタイトル（日本語）>
Why it matters: <実害を1文（日本語）>
Evidence: <差分上のファイルパスと該当箇所>
Suggested fix: <最小修正を1〜3行（日本語で説明可。コードはそのまま）>
```

Rules:

- Priority label is exactly `High`, `Medium`, or `Low`.
- Deduplicate by root cause.
- No evidence in the diff → no comment.
- If there are no High or Medium findings: reply with only `対応が必要な指摘はありません` (or `No actionable findings`).
- Do not pad with Low items to fill a quota.

## 6. Project-specific assumptions

Treat these as **correct by default**. Do not flag diffs that merely follow them:

- Monorepo: Web (Next.js App Router) / Mobile (Expo) / Go API / Supabase.
- Simple CRUD → Supabase + RLS; heavy / transactional / external work → Go API.
- Web Tailwind v4 is CSS-first (`tailwind.config` must not return); do not open style debates about that stack.
- Exposing Service Role Key (or other secrets) to the client is **High**.
- `drinks` / `cocktails` are SKU/expression-level; following existing granularity (e.g. not splitting limited labels into new rows) is correct.

## 7. Quantity limits

| Rule | Limit |
| --- | --- |
| High + Medium | Prefer **≤ 5** total; if more, keep only the highest-severity / highest-impact |
| Low | **≤ 2** per PR |
| Duplicates | Merge into one finding per root cause |
| Empty High/Medium | `No actionable findings` only |
| Re-review on push | **No** — once at PR open unless manually re-triggered |
