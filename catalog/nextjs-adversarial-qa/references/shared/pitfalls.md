# Next.js Testing Pitfalls & Anti-Patterns

Two catalogues: creation mistakes that testing exposes, and testing mistakes that hide defects.

---

## 1. Creation Anti-Patterns (caught by these suites)

| Anti-Pattern | Correct Solution |
| :--- | :--- |
| Direct import of RSC inside `"use client"` | Pass RSC as `children` or props into the Client wrapper |
| Hardcoded colors (`text-gray-600`, `#FAFAFA`) | Semantic tokens (`text-muted-foreground`, `bg-background`, `border-border`) |
| Physical directional margins (`ml-4`, `pr-2`) | Logical properties (`ms-4`, `pe-2`, `start`, `end`) |
| Standard `<img>` tag | `next/image` with `width`/`height` or `fill` and `alt` |
| Writing component code before tests | Invoke QA `baseline` mode first; tests gate the implementation |
| Self-certifying quality without adversarial audit | Spawn the independent auditor subagent for `*.edge.test.tsx` |
| Guessing unspecified behavior | Grill the user before writing the test plan |
| Transient plan in chat memory only | Persist `<component_name>.test-plan.md` and `.agents/history/plan-[component-name].json` |
| Standard `next/link` for internal navigation | `Link` from `@/i18n/navigation` (locale prefix applied automatically) |
| Naked internal links (`/about`) | `Link` from `@/i18n/navigation` with a route key, not a hand-built path |
| Manual date/currency formatting | `Intl.DateTimeFormat` / `Intl.NumberFormat` |
| Skipping `@param` tags or non-English TSDoc | Strict English TSDoc for every prop and parameter |
| Shared singleton `QueryClient` on server | `new QueryClient()` per request |
| `await prefetchQuery` in RSC | `void queryClient.prefetchQuery(...)` inside `<Suspense>` |
| Relative URLs in server prefetch | Call internal service/DB directly on the server |
| Missing `staleTime` on hydrated queries | Explicit `staleTime: 30_000` |
| Calling `Date.now()` during Cache Components build | Wrap the timestamp in a `'use cache'` helper with matching `cacheTag` |
| Sequential `useSuspenseQuery` waterfalls | Sibling components or `useSuspenseQueries` |
| Hardcoding internal navigation URLs | Import `ROUTES` from `@/lib/routes` |
| Hardcoding author bio / credentials in UI | Import `SITE_CONFIG` from `@/lib/site-config` |
| Designing UI without consulting design tokens | Review `docs/design/03-ui-design-tokens.md` |
| Creating stories for internal leaf micro-helpers | Stories ONLY for the main composite component |
| Hardcoded callback stubs in stories | Import `fn` from `storybook/test` so clicks log to Actions |
| Skipping Storybook verification | Run smoke test and `build-storybook` in the storybook gate |
| Overwriting pre-existing component files | Enter Backfill Mode and generate only missing companions |
| In-file mock dictionaries (`DEFAULT_CONTENT`) | Extract all strings to `messages/[locale].json` |

---

## 2. Testing Anti-Patterns

| Anti-Pattern | Why It Fails | Correct Solution |
| :--- | :--- | :--- |
| Testing an `async` RSC in jsdom | React never resolves the promise in Jest | Assert through Playwright |
| Mocking `useTranslations` / `next-intl` | Hides missing keys and RTL defects | Real `NextIntlClientProvider` + dictionary |
| `fireEvent` | Skips focus and keyboard semantics | `@testing-library/user-event` |
| `waitForTimeout(500)` | Flaky and slow | `findBy*`, `waitFor`, fake timers |
| Snapshot-only assertions | Breaks on any class change, proves nothing | Assert roles, text, ARIA state |
| Co-located `*.spec.tsx` | Playwright picks up Jest files | `tests/e2e/**` |
| `test.only` committed | CI silently skips the suite | Ban `only`; grep in verification |
| `it.skip` on a failing edge case | Hides a real defect | Fix the component |
| Weakening assertions to go green | Violates the immutability rule | Fix the implementation |
| Asserting Tailwind classes as behavior | Couples tests to styling churn | Assert visible/disabled/expanded state |
| Hardcoded English expected text | Breaks for `fa` and other locales | Read from dictionary |
| Full-suite runs during iteration | Slow, noisy, token-heavy | Targeted file execution |
| Duplicating Jest coverage in Playwright | Doubles maintenance | One layer per behavior |
| Screenshot of dynamic regions | Permanent flake | `mask: [...]` or scope the locator |
| Absolute `http://localhost:3000` | Breaks in CI | `baseURL` from config |
| Ignoring console errors | Hydration bugs ship | Hydration guard fails the test |
| No teardown of subscriptions | Open handles, false passes | `cleanup()` / abort controllers |
| One giant happy-path test | Failure gives no signal | One behavior per test |

---

## 3. Diagnostic Table

| Symptom | Likely Cause | Check |
| :--- | :--- | :--- |
| `No intl context found` | Missing `NextIntlClientProvider` | Test harness wrapper |
| `not wrapped in act(...)` | Un-awaited state update | `await user.click`, `findBy*` |
| `Hydration failed` | `Date.now()`, `Math.random()`, browser globals in SSR | Playwright hydration guard |
| Test passes alone, fails in suite | Shared mutable fixture / singleton client | Per-test fixtures |
| Snapshot diff on every run | Fonts/images not deterministic | Disable animations, mask dynamic parts |
| `Cannot find module 'next/navigation'` | Missing mock | `jest.mock("next/navigation", ...)` |
| Edge test cannot render RSC | Async component | Move assertion to Playwright |
