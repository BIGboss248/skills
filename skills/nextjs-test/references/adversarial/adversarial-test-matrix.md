# Adversarial Test Matrix (Components & Pages)

Edge-case taxonomy for the auditor subagent. Every spec §7 row must map to at least one ID below. IDs are stable; reference them in `<component_name>.test-plan.md` and test names.

---

## 1. Component IDs

| ID | Category | Scenario | Layer |
| :--- | :--- | :--- | :--- |
| BND-1 | Boundary | Empty string prop (`""`) renders fallback, no crash | Jest |
| BND-2 | Boundary | `null` / `undefined` optional props use documented defaults | Jest |
| BND-3 | Boundary | 200+ character unbroken string wraps without overflow | Jest / Visual |
| BND-4 | Boundary | Zero-item collection renders empty state, not an empty frame | Jest |
| BND-5 | Boundary | Single-item and maximum-item collections keep grid geometry | Jest / Visual |
| BND-6 | Boundary | Negative, zero, and huge numeric values format correctly | Jest |
| PROP-1 | Permutations | All optional flags omitted | Jest |
| PROP-2 | Permutations | Conflicting flags (`isLoading` + `error`) resolve deterministically | Jest |
| PROP-3 | Permutations | `disabled` blocks interaction and sets `aria-disabled` | Jest |
| PROP-4 | Permutations | Prop change after mount re-renders without stale state | Jest |
| NET-1 | Network | Async rejection renders error card with retry | Jest / Playwright |
| NET-2 | Network | Malformed payload does not throw during render | Jest |
| NET-3 | Network | Slow response keeps skeleton geometry (no CLS) | Playwright |
| NET-4 | Network | 500 response reaches `error.tsx` with a working reset | Playwright |
| A11Y-1 | Accessibility | `Tab` order reaches every interactive element | Jest |
| A11Y-2 | Accessibility | `Enter` and `Space` activate buttons/links | Jest |
| A11Y-3 | Accessibility | `Escape` closes overlays and restores focus | Jest |
| A11Y-4 | Accessibility | `aria-expanded` / `aria-busy` / `aria-live` reflect state | Jest |
| A11Y-5 | Accessibility | Focus is trapped inside modal and restored on close | Jest |
| A11Y-6 | Accessibility | `jest-axe` reports zero violations | Jest |
| MOT-1 | Motion | `prefers-reduced-motion` disables non-essential animation | Jest / Playwright |
| LIFE-1 | Lifecycle | Unmount clears timers, subscriptions, and abort controllers | Jest |
| LIFE-2 | Lifecycle | Rapid re-render (10x) does not duplicate listeners or requests | Jest |
| LIFE-3 | Lifecycle | Double-click triggers exactly one mutation | Jest |
| I18N-1 | i18n | Persian/Arabic glyphs render RTL without clipping | Jest / Visual |
| I18N-2 | i18n | Text expansion (+40%) keeps container height | Visual |
| I18N-3 | i18n | Missing dictionary key fails loudly, not silently | Jest |
| I18N-4 | i18n | `Intl` currency/date output matches locale | Jest |
| HYD-1 | Hydration | Zero console hydration warnings | Playwright |
| VIS-1 | Visual | Light, dark, and RTL snapshots stable | Playwright |

---

## 2. Page IDs

| ID | Category | Scenario | Layer |
| :--- | :--- | :--- | :--- |
| PAGE-1..14 | Contract | See [`page-testing-standards.md`](../authoring/page-testing-standards.md) | Playwright |
| PBND-1 | Boundary | Missing dynamic param returns 404/redirect, never 500 | Playwright |
| PBND-2 | Boundary | Invalid locale redirects to default or 404s | Playwright |
| PBND-3 | Boundary | Empty data set renders page-level empty state | Playwright |
| PBND-4 | Boundary | Malformed search params fall back safely | Playwright |
| PBND-5 | Boundary | Unknown nested route renders localized 404 | Playwright |
| PSEO-1 | SEO | JSON-LD parses and `@id` references resolve | Playwright |
| PSEO-2 | SEO | No unescaped `<` in JSON-LD | Playwright |
| PSEO-3 | SEO | hreflang covers every supported locale | Playwright |

---

## 3. Authoring Rules for the Auditor

1. **One ID per test name**: `it("BND-3: wraps a 240-character unbroken title", ...)`.
2. **No duplicate coverage** of baseline tests — read `<component_name>.test.tsx` first.
3. **Assert behavior, not implementation** — no Tailwind class equality unless geometry is the contract.
4. **Deterministic fixtures** — no `Date.now()`, `Math.random()`, or network calls without stubbing.
5. **Immutable output** — after writing, the edge file is read-only for the implementer.
6. **Minimums** — 6 component cases across ≥4 categories; 4 page boundary cases.

---

## 4. Severity Classification

| Severity | Meaning | Action |
| :--- | :--- | :--- |
| `critical` | Crash, data loss, broken navigation, a11y blocker | Block handoff |
| `major` | Wrong state, missing error handling, layout break | Fix before handoff |
| `minor` | Cosmetic overflow, suboptimal default | Log in report, fix if cheap |
| `info` | Improvement suggestion | Report only |
