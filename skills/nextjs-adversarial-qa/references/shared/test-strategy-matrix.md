# Test Strategy Matrix (Next.js App Router)

Decide the cheapest layer that can prove the behavior. Push assertions down to Jest when jsdom can express them; escalate to Playwright only when the browser is required.

---

## 1. Layer Assignment

| Behavior under test | Layer | File | Runner |
| :--- | :--- | :--- | :--- |
| Prop permutations, defaults, conditional UI | Jest + RTL | `<dir>/[ComponentName].test.tsx` | `pnpm test` |
| Callback invocation, local state, toggles | Jest + RTL | `<dir>/[ComponentName].test.tsx` | `pnpm test` |
| Empty / null / error fallback rendering | Jest + RTL | `<dir>/[ComponentName].edge.test.tsx` | `pnpm test` |
| Keyboard navigation, ARIA state, focus order | Jest + RTL (`jest-axe`) | `<dir>/[ComponentName].edge.test.tsx` | `pnpm test` |
| Unicode / RTL glyph rendering and `dir` | Jest + RTL | `<dir>/[ComponentName].edge.test.tsx` | `pnpm test` |
| Timer teardown, rapid re-render, unmount | Jest + RTL | `<dir>/[ComponentName].edge.test.tsx` | `pnpm test` |
| SSR hydration mismatches | Playwright | `tests/e2e/components/<page>/<ComponentName>.spec.ts` | `pnpm test:e2e` |
| Async RSC / streamed content | Playwright | `tests/e2e/components/<page>/<ComponentName>.spec.ts` | `pnpm test:e2e` |
| Instant shell / prefetched App Shell | Playwright (`instant()`) | `tests/e2e/components/<page>/<ComponentName>.spec.ts` | `pnpm test:e2e` |
| Visual regression (light, dark, RTL) | Playwright snapshots | `tests/e2e/components/<page>/<ComponentName>.spec.ts` | `pnpm test:e2e` |
| Slow network / 500 / Suspense geometry | Playwright (`page.route`) | `tests/e2e/components/<page>/<ComponentName>.spec.ts` | `pnpm test:e2e` |
| `generateMetadata`, canonical, hreflang | Playwright | `tests/e2e/pages/<route>.spec.ts` | `pnpm test:e2e` |
| JSON-LD graph validity | Playwright | `tests/e2e/pages/<route>.spec.ts` | `pnpm test:e2e` |
| `generateStaticParams` locale coverage | Playwright | `tests/e2e/pages/<route>.spec.ts` | `pnpm test:e2e` |
| `loading.tsx` / `error.tsx` boundaries | Playwright | `tests/e2e/pages/<route>.spec.ts` | `pnpm test:e2e` |

---

## 2. Hard Rules

1. **jsdom cannot run async RSC.** Never `await Page()` inside a Jest test. Render the resolved JSX only for synchronous components; otherwise test through Playwright.
2. **Playwright specs live under `tests/e2e/`.** Co-located `.spec.tsx` files are picked up by default `testMatch` and collide with Jest.
3. **One behavior per test.** A failing test must identify exactly one defect.
4. **No duplicate coverage.** If Jest proves it, do not repeat it in Playwright unless SSR/hydration changes the outcome.
5. **Targeted runs only.** `pnpm test -- <file>` and `pnpm test:e2e <file>`, never the full suite during iteration.

---

## 3. Gates by Mode

| Mode | Gate | Blocks |
| :--- | :--- | :--- |
| `baseline` | `[ComponentName].test.tsx` green | Component implementation may start |
| `page` | `tests/e2e/pages/<route>.spec.ts` green | Page marked complete in `docs/plan/05-pages-and-components.md` |
| `adversarial` | `[ComponentName].edge.test.tsx` green | Orchestrator Phase 3 handoff |
| `repair` | All targeted suites green | Any completion claim |
| `audit` | Report delivered, no code change | Nothing (advisory) |

---

## 4. Minimum Coverage Contract

| Artifact | Baseline | Adversarial | Playwright |
| :--- | :--- | :--- | :--- |
| Component | 4+ cases: default render, props, interaction, skeleton | 6+ cases across BND / PROP / NET / A11Y / LIFE / I18N | 3+ cases: hydration, instant, visual |
| Page | — | 4+ cases: missing params, invalid locale, empty data, error | 6+ cases: metadata, JSON-LD, routes, loading, error, instant |

Coverage is judged by mapped plan rows, not line percentage.
