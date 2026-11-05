# Next.js Component Creation Pitfalls & Anti-Patterns

| Anti-Pattern                                        | Correct Solution                                                                                 |
| :-------------------------------------------------- | :----------------------------------------------------------------------------------------------- |
| Direct import of RSC inside `"use client"` file     | Pass RSC as `children` or React props into Client wrapper                                        |
| Hardcoded colors (e.g., `text-gray-600`, `#FAFAFA`) | Use semantic tokens (`text-muted-foreground`, `bg-background`, `border-border`)                  |
| Physical directional margins (`ml-4`, `pr-2`)       | Use logical properties (`ms-4`, `pe-2`, `start`, `end`)                                          |
| Standard `<img>` tag                                | Use Next.js `<Image src="..." width={...} height={...} alt="..." />`                             |
| Writing component code before unit tests            | Invoke `nextjs-test` in `baseline` mode first (TDD gate)                               |
| Self-certifying quality without adversarial audit   | Spawn Adversarial Auditor subagent to write `<component_name>.edge.test.tsx`                      |
| Guessing unspecific requirements                    | Interview user (suggest `/grill-me`) to clarify props and behavior first                         |
| Transient plan in chat memory only                  | Save plan to `.agents/history/plan-[component-name].json` and update statuses                    |
| Standard `next/link` for internal navigation        | Use `Link` from `@/i18n/navigation`; `next/link` only for hash anchors and the locale-less root `not-found.tsx` |
| No pending feedback on slow navigations             | Render a `useLinkStatus()` child inside the link; never add a progress-bar package |
| Naked internal links (`<Link href="/about">`)       | Use `Link` from `@/i18n/navigation` — it prefixes the active locale automatically                |
| Manual date/currency formatting                     | Use native `Intl.DateTimeFormat` or `Intl.NumberFormat`                                          |
| Skipping `@param` tags or non-English TSDoc         | Write strict English TSDoc for every prop and parameter                                          |
| Shared singleton `QueryClient` on server            | Instantiate `new QueryClient()` per request on server                                            |
| Awaiting `prefetchQuery` in RSC                     | Use non-blocking prefetch `void queryClient.prefetchQuery(...)` inside `<Suspense>`              |
| Relative URLs in server prefetch                    | Call internal service/DB directly in server prefetch; relative URLs for client                   |
| Missing `staleTime` on hydrated queries             | Set explicit `staleTime: 30_000` in `queryOptions`                                               |
| Calling `Date.now()` during Cache Components build  | Wrap dehydration timestamp in `'use cache'` helper with matching `cacheTag`                      |
| Sequential `useSuspenseQuery` waterfalls            | Split independent queries into sibling components or `useSuspenseQueries`                        |
| Hardcoding internal navigation URLs                 | Import route constants from `@/lib/routes` (`ROUTES.about`)                                      |
| Hardcoding author bio / credentials in UI           | Import canonical details from `@/lib/site-config` (`SITE_CONFIG`)                                |
| Designing UI without consulting design tokens       | Review `docs/design/03-ui-design-tokens.md`                                                      |
| Creating stories for internal leaf micro-helpers    | Create Storybook stories ONLY for the main component                                             |
| Hardcoded callback stubs in stories                 | Import `fn` from `'storybook/test'` so clicks log to Actions panel                               |
| Skipping Storybook tests in verification            | Run smoke test (`pnpm run storybook:smoke`) and build (`pnpm run build-storybook`)               |
| Overwriting pre-existing component files            | Audit companion files and enter Backfill Mode without overwriting working code                   |
| Running Playwright or the full suite during dev     | Fast tier only: targeted Jest file; Playwright/full Jest/build run at pre-push                    |
| Reporting a deferred E2E suite as `PASS`            | Report `DEFERRED (pre-push)` and list it in `deferred_expensive_tests[]`                          |
| Writing in the user's working tree                  | Create and work in the `agent/<slug>` worktree; merge into `main` after the fast gates            |
| Resolving a merge conflict by guessing              | Abort the merge, keep the branch, report the paths, and ask the user to choose                    |
