---
name: nextjs-component-dev
description: >-
  Build Next.js App Router React components with Suspense skeletons, semantic OKLCH tokens, next-intl dictionaries, Jest + RTL unit tests, Playwright visual/hydration checks, and Tailwind logical styling. MANDATORY SKILL: MUST ALWAYS be activated, read, and strictly followed every time the agent creates, scaffolds, or implements any new React/Next.js component, UI section, card, widget, or layout element. Triggers on "/nextjs-component-dev", "create component", "new component", "build component", "develop component", or any component creation task.
metadata:
  author: BIGboss248
  version: "1.6"
---

# Next.js Component & Skeleton Development (`nextjs-component-dev`)

Specialized workflow for creating production-ready React Server Components (RSC) and Client Components with Suspense skeletons, dual-layer TDD testing (Jest + RTL unit tests and Playwright integration/hydration/visual checks), next-intl dictionary-backed translations, semantic theme tokens, and live runtime diagnostics via `next-devtools` MCP.

> [!CRITICAL]
> **MANDATORY COMPONENT CREATION INVARIANT:** Whenever you create any new React or Next.js component (whether requested directly by the user, created as part of a page build, or executed from `docs/plan/`), you **MUST** strictly follow every architectural standard and workflow step in this skill. Never create ad-hoc `.tsx` component files without executing this workflow (Next.js local docs lookup, `implementation_plan.md`, `messages/[locale].json` dictionary sync, TDD `[ComponentName].test.tsx`, `[ComponentName]Skeleton.tsx`, `index.ts`, and `verify-dev` verification).

> [!TIP]
> **Modular Assets & Templates:**
>
> - Next.js Docs Search & Context: [`references/nextjs-docs-lookup.md`](./references/nextjs-docs-lookup.md)
> - Testing Architecture & Verification: [`references/testing-architecture-guide.md`](./references/testing-architecture-guide.md)
> - Storybook Standards & Separation: [`references/storybook-reference.md`](./references/storybook-reference.md)
> - Instant Navigation & Prefetching: [`references/instant-navigation-and-prefetching.md`](./references/instant-navigation-and-prefetching.md)
> - Next DevTools Debugging Guide: [`references/next-devtools-debugging.md`](./references/next-devtools-debugging.md)
> - Caching & Revalidation: [`references/caching-and-revalidation.md`](./references/caching-and-revalidation.md)
> - RSC, State Boundaries & Lazy Loading: [`references/rsc-and-state-boundaries.md`](./references/rsc-and-state-boundaries.md)
> - Code Templates: [`resources/templates/`](./resources/templates/) ([Component](./resources/templates/component.template.tsx), [Skeleton](./resources/templates/skeleton.template.tsx), [Jest Unit Test](./resources/templates/unit-test.template.tsx), [Playwright Spec](./resources/templates/e2e-spec.template.ts))
> - Reference Implementations: [`examples/`](./examples/)
> - Verification Scripts: [`scripts/verify-dev.ps1`](./scripts/verify-dev.ps1) (Windows) / [`scripts/verify-dev.sh`](./scripts/verify-dev.sh) (Linux)

---

## Architectural Rules & Standards

### 1. Planning Context & Paths

- Read `docs/project.json` to resolve `package_manager`, `new_component_dir`, `style_file_dir`, `component_library`, `dictionaries_dir` (default: `"messages"`), and `supported_languages`.
- All internal routes MUST use `ROUTES` from `@/lib/routes`.
- All author/site metadata MUST use `SITE_CONFIG` from `@/lib/site-config`.
- Target path hierarchy: `<new_component_dir>/<page_or_global>/<ComponentName>/`
  - Category: `global/` for shared layout chrome; `<page-name>/` (e.g. `home/`, `about/`, `lab/`) for page-scoped sections.

### 2. Next.js Internal Docs Lookup (`node_modules/next/dist/docs`)

- **Search Local Docs via Codebase Memory MCP:** For any component creation, actively query and inspect the local Next.js distribution docs at `node_modules/next/dist/docs/` using `codebase-memory` MCP tools (`search_code`, `search_graph`, `get_code_snippet`) for relevant API signatures, directives (`'use cache'`, `'use client'`, `'use server'`), built-in components (`next/image`, `next/link`, `next/font`, `<Form>`), navigation hooks (`useRouter`, `usePathname`), and caching policies (`cacheLife`, `cacheTag`).
- **Eliminate Deprecations & Hallucinations:** Never rely on assumptions or outdated Next.js patterns; the local `node_modules/next/dist/docs` matching the installed package version is the primary source of truth. Consult [`references/nextjs-docs-lookup.md`](./references/nextjs-docs-lookup.md).

### 3. Dev Server & Next DevTools Protocol

- **Dev Server Check & Tune-In:** Before/during component development, check if the Next.js dev server is running via `next-devtools` MCP server (`nextjs_index`).
- **If Server Running:** Tune into the running server and port immediately; do not restart.
- **If Server Not Running:** Start the dev server in the background (`pnpm dev`, `IsDaemon: true`) and verify connection via `nextjs_index`.
- **Runtime Debugging:** After implementing components, query `next-devtools` (`nextjs_call`) to inspect errors, check build status, and diagnose runtime issues immediately. Consult [`references/next-devtools-debugging.md`](./references/next-devtools-debugging.md).

### 4. RSC Boundaries & Leaf Client Push-Down

1. **Server Components by Default:** Keep components server-rendered (`async function`).
2. **Push `"use client"` Down:** Isolate interactive handlers (buttons, toggles, form inputs) into small leaf Client Components.
3. **RSC Composition:** Pass Server Components as `children` or props into Client wrappers. Never import Server Components inside `"use client"` files.
4. **Lazy Client Loading (`next/dynamic`):** For heavy, conditionally rendered, or below-the-fold Client Components (rich text editors, dialogs/modals, charts, heavy pickers), dynamically load them via `next/dynamic` with `loading: () => <[ComponentName]Skeleton />`. Consult [`references/rsc-and-state-boundaries.md`](./references/rsc-and-state-boundaries.md).
5. **Client-Only Leaf (`ssr: false`):** When client components rely strictly on browser APIs (`window`, canvas, `localStorage`), disable SSR via `{ ssr: false }` to eliminate hydration mismatches while rendering the skeleton during SSR.
6. **Action-Driven Library Loading:** Dynamically import heavy libraries (`await import(...)`) inside event handlers rather than top-level module imports.

### 5. Styling, Logical Properties & Theme Tokens

- **Semantic Tokens:** Exclusively use semantic CSS variables defined in `app/globals.css` (`bg-background`, `text-foreground`, `border-border`, `text-muted-foreground`). Hardcoded hex colors (`#FAFAFA`) or raw color scales (`bg-blue-500`) are FORBIDDEN.
- **Class Merging:** Always merge classes using `cn(...)` (`clsx` + `tailwind-merge`).
- **Logical Properties (BiDi):** Exclusively use Tailwind logical properties (`ms-`, `pe-`, `ps-`, `me-`, `start`, `end`). Physical directional classes (`ml-`, `mr-`, `pl-`, `pr-`, `left-`, `right-`) are FORBIDDEN.
- **Progress Links:** Use `<Link>` from `@vercel/react-transition-progress` for primary navigation, hero CTAs, and interactive cards; use standard `next/link` for static utility links.
- **Images:** Always use `next/image` with explicit dimensions or `fill`, responsive `sizes`, and `priority` for above-the-fold LCP assets.

### 6. Instant Navigation, Granular Suspense & Caching Architecture

- **The Three Levers for Instant Components**:
  1. **Push Down**: Extract request-specific async operations (`await params`, `await searchParams`, `cookies()`, `headers()`, uncached DB/API calls) into leaf sub-components wrapped in `<Suspense>`. Static parents and siblings lift directly into the static/App Shell.
  2. **Cache**: Pair `'use cache'` with `cacheLife` and `cacheTag` at function/component level. Use Session Bridging patterns:
     - **Pattern A (Extract & Pass)**: Extract session attributes (e.g. `team_id`, `role`, `tier`) from `cookies()` outside and pass as arguments to `'use cache'` functions so cached data is shared across all users with matching attributes (cost scales with team/attribute count, not user session count).
     - **Pattern B (`"use cache: private"`)**: For strictly user-specific session lookups, use browser-only session caching with `stale >= 5m` that travels with the App Shell.
  3. **Prefetching Strategy & Dense Grids**:
     - **Default App Shell Prefetching (`<Link>` / `prefetch={null}`)**: Prefetches one shared static/App Shell per route. Bounded cost ($O(\text{routes})$), zero server invocations per link. Use for dense feeds, card grids (50+ cards), and bulk navigation.
     - **Per-Link Prefetching (`<Link prefetch={true}>`)**: Resolves dynamic URL data (`params`, `searchParams`) before navigation with 1 server invocation per visible link. Use sparingly for high-intent primary CTAs, hero actions, or master-detail list items where skeleton flashing must be eliminated.
     - **Dense Card Grids**: NEVER use blanket `prefetch={true}` across dozens of cards in feeds. Retain default `<Link>` or use hover/focus intent prefetching (`router.prefetch()`).
- **Granular Loading States (Anti-Full-Page Flash)**: Never wrap an entire component or page in a single top-level `<Suspense>` boundary that flashes full skeletons. Keep titles, layout frames, and cached content visible immediately; place `<Suspense>` strictly around dynamic streaming slots.
- **Native Next.js 16 Caching Directives**: Consult [`references/instant-navigation-and-prefetching.md`](./references/instant-navigation-and-prefetching.md) and [`references/caching-and-revalidation.md`](./references/caching-and-revalidation.md).

### 7. TanStack Query & Server Prefetching

- **Unified Cache Contract:** Define `key`, `tag`, and `queryOptions` with explicit `staleTime` (e.g. `30_000` ms).
- **Server Prefetch:** Trigger unawaited prefetch (`void queryClient.prefetchQuery(...)`) calling internal DB functions directly (zero relative fetch on server). Dehydrate with `<HydrationBoundary>`.
- **Streamed Components:** Use `useSuspenseQuery` inside `<Suspense fallback={<[ComponentName]Skeleton />}>`.
- **Optimistic Mutations:** Use `useMutation` with `onMutate` cache snapshots and `onError` rollbacks; call Server Actions with `updateTag(cache.tag)`.

### 8. Dual-Layer Testing Division of Labor (Jest vs. Playwright)

- **Jest + RTL (`[ComponentName].test.tsx`):**
  - Fast feedback loop in `jsdom`.
  - Prop permutations, conditional UI elements, and empty/null states.
  - User interactions via `@testing-library/user-event` (never `fireEvent`).
  - Next.js routing mocks (`useRouter`, `usePathname`, `useSearchParams` from `next/navigation`).
  - `next-intl` dictionary interpolation and pluralization checks inside `NextIntlClientProvider`.
  - Accessible role queries (`screen.getByRole`) and automated a11y checks (`jest-axe`).
- **Playwright (`[ComponentName].spec.ts` or page-level specs):**
  - Real browser execution (Chromium/WebKit/Firefox).
  - **Instant Shell Assertions (`@next/playwright`):** Use `instant(page, ...)` helper to assert that static shells and prefetched App Shells render immediately before dynamic server streaming resolves.
  - **Zero-Hydration Mismatches:** Listen to browser console events (`page.on('console')`) to detect and fail tests on React SSR hydration warnings.
  - **Visual & BiDi Regression:** Use `expect(page).toHaveScreenshot()` across themes (light vs. dark OKLCH variables) and text directions (`dir="ltr"` vs. `dir="rtl"`).
  - **Network Resilience:** Use `page.route()` to test slow network responses (verifying Suspense skeletons match geometry to prevent CLS) and 500 error boundaries.
- **Detailed Testing Standards:** Consult [`references/testing-architecture-guide.md`](./references/testing-architecture-guide.md).

---

## Phase 0: Implementation Plan & Approval Gate

> [!IMPORTANT]
> **Plan Before Execution:** Always generate and present an `implementation_plan.md` artifact detailing all planned file creations, modifications, TypeScript contracts, translation dictionary additions, and TDD test cases before executing any write operations, modifying dictionaries, or creating components in the repository. Wait for user confirmation/approval before proceeding with execution.

The implementation plan must cover:

1. **Target Architecture & Path**: Full target directory (`<new_component_dir>/<page_or_global>/<ComponentName>/`) and classification (RSC, Eager Client leaf, Lazy Client leaf with `next/dynamic`, or Client-only with `ssr: false`).
2. **Next.js Local Docs Consulted**: Specific doc paths checked under `node_modules/next/dist/docs/` (e.g. `04-api-reference/04-components/image.md`, `03-directives/use-cache.md`, `04-api-reference/02-functions/use-router.md`).
3. **TypeScript Contracts**: Prop interfaces and types with strict English TSDoc annotations.
4. **Dictionary Strategy**: Explicit translation namespaces and keys to add to `messages/[locale].json` across all `supported_languages` in `docs/project.json` (zero hardcoded strings or in-file mock dictionaries).
5. **Theme Tokens & Styling**: Identified semantic OKLCH CSS variables and logical layout classes.
6. **Testing & Diagnostics Strategy**:
   - **Jest Unit Tests (`[ComponentName].test.tsx`)**: Mock configurations (`next/navigation`), prop variations, callback assertions, `NextIntlClientProvider` integration, and a11y role queries.
   - **Playwright Integration Scenarios (`[ComponentName].spec.ts`)**: Visual snapshot targets (light/dark theme tokens, LTR vs. RTL logical layouts), network throttling/skeleton geometry checks, and hydration verification listeners.
   - **Next DevTools Diagnostics**: Runtime error and compilation checks via `next-devtools`.
7. **Verification Gate**: Exact verification commands to run (`verify-dev.ps1`, targeted unit tests, and Playwright e2e specs).

---

## Workflow Steps

- [ ] **Step 0: Implementation Plan Generation & Approval Gate**
  - Search and inspect `node_modules/next/dist/docs` via `codebase-memory` MCP (`search_code`, `search_graph`) for any Next.js APIs, directives, hooks, or components utilized by the planned component to ensure up-to-date context.
  - Synthesize component requirements, scan `docs/project.json`, and generate `implementation_plan.md` documenting consulted docs and contracts.
  - Set `request_feedback = true` and `user_facing = true` on the artifact.
  - Wait for user review and explicit approval before writing any code.

- [ ] **Step 1: Dev Server Verification & Next DevTools Connection**
  - Query `next-devtools` MCP via `nextjs_index` to detect running Next.js dev server instances.
  - **If Dev Server is running:** Tune into the active port and server instance; continue developing without restarting.
  - **If Dev Server is NOT running:** Start the dev server in the background (`pnpm dev`, `IsDaemon: true`) and verify discovery with `nextjs_index`.

- [ ] **Step 2: Dictionary Population & TypeScript Contract Definition**
  - Read `docs/project.json` to resolve `dictionaries_dir` (`messages` is default) and `supported_languages`.
  - Define the component's translation namespace and keys.
  - **Populate all dictionary files** (`messages/en.json`, `messages/fa.json`, etc.) with authentic translations for every supported language before writing JSX.
  - Define prop interfaces with strict **English TSDoc** annotations (`@param`, `@defaultValue`, `@returns`).
  - If there are more than one supported language, component must fetch the translation first and if failed use fallbacks.

- [ ] **Step 3: TDD Baseline Unit Tests (`[ComponentName].test.tsx` via Jest + RTL)**
  - Write `[ComponentName].test.tsx` BEFORE implementing the component.
  - Mock `next/navigation` hooks (`useRouter`, `usePathname`, `useSearchParams`).
  - Wrap rendered components in `NextIntlClientProvider` supplying the dictionary `messages` and active `locale`.
  - Test directional attributes (`dir="rtl"` vs. `dir="ltr"`), default props, interactive callbacks (`@testing-library/user-event`), Suspense skeleton fallbacks, and semantic ARIA roles.

- [ ] **Step 4: Component & Skeleton Implementation**
  - Create primary component `[ComponentName].tsx` (RSC or Client Component) consuming translations via `next-intl` (`getTranslations` or `useTranslations`) with zero hardcoded placeholders or in-file mock dictionary objects. For heavy or conditionally rendered interactive leaves, wrap via `next/dynamic` with `loading: () => <[ComponentName]Skeleton />` (or `{ ssr: false }` for browser-only APIs).
  - Create matching Suspense skeleton `[ComponentName]Skeleton.tsx` mirroring layout geometry and classes to prevent CLS.
  - Create clean barrel export `index.ts`.

- [ ] **Step 5: Runtime Diagnostics & Verification Gate**
  - **Next DevTools Runtime Inspection & Navigation Inspector:** Use `next-devtools` MCP server (`nextjs_call`) to check for compilation errors, runtime exceptions, hydration issues, or broken routes. Use Navigation Inspector ("Pause on navigations") to verify the static shell and App Shell render instantly with granular fallbacks.
  - **Targeted Unit Test Execution:** Run verification script to check companion files, dictionary compliance, and execute unit tests:
    - **Windows (PowerShell):**
      ```pwsh
      pwsh .agents/skills/nextjs-component-dev/scripts/verify-dev.ps1 -ComponentPath <target_component_dir>
      ```
    - **Linux / macOS (Bash):**
      ```bash
      bash .agents/skills/nextjs-component-dev/scripts/verify-dev.sh <target_component_dir>
      ```
  - **Playwright Instant Navigation & Hydration Check:** Run targeted Playwright component/integration spec:
    ```bash
    pnpm test:e2e [ComponentName]
    ```
  - Validate that `instant()` tests pass for hard page load and client navigation, visual snapshots pass across themes, and console listeners register 0 hydration mismatch errors.
  - Fix any syntax errors, missing dictionary keys, visual discrepancies, or test regressions until all assertions pass.

- [ ] **Step 6: Implementation Plan Checklist Synchronization**
  - Check off the completed component item (`- [x]`) in `docs/plan/05-pages-and-components.md`.
  - If all sub-components and page infrastructure tasks for the parent page are completed, check off the parent page item (`- [x]`).

---

## Edge Cases & AI Pitfalls

- **Local Docs Verification via Codebase Memory MCP:** Always search `node_modules/next/dist/docs/` using `codebase-memory` MCP tools (`search_code`, `search_graph`) before authoring components. Never assume deprecated Next.js API signatures or outdated caching mechanisms; local docs reflect the exact runtime version installed.
- **Zero In-File i18n Fallbacks:** Never hardcode dictionary objects or fallbacks (`const DEFAULT_CONTENT = {...}`) in TSX files. All text must come from `messages/[locale].json`.
- **Hydration Warning Detection & Browser APIs:** Never access browser-only globals (`window`, `localStorage`) during SSR. Use `dynamic(() => import('./Widget'), { ssr: false, loading: () => <WidgetSkeleton /> })` instead of double-rendering `useEffect(mounted)` flags to eliminate hydration crashes cleanly.
- **Strict Logical Styling (BiDi):** Never use physical directions (`ml-`, `mr-`, `pl-`, `pr-`, `left-`, `right-`). Always use logical alternatives (`ms-`, `me-`, `ps-`, `pe-`, `start`, `end`).
- **Targeted Test Execution:** Always run tests targeting specific component files to conserve tokens and reduce execution time (do not run full project test suites during component iterations).
- **Storybook Story Separation:** Do not author `.stories.tsx` or run Storybook builds during standard component development unless the `nextjs-storybook-story` skill is specifically requested. Consult [`references/storybook-reference.md`](./references/storybook-reference.md).
