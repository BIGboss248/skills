---
name: nextjs-component-dev
description: >-
  Build Next.js App Router React components with semantic OKLCH tokens, next-intl dictionaries, and Tailwind logical styling; a Suspense skeleton is added only when the component can suspend, lazy-load, or wait on I/O, never for static components. Test authoring is owned exclusively by nextjs-test. MANDATORY SKILL: activate for every new component, UI section, card, widget, or layout element. Triggers on "/nextjs-component-dev", "create component", "new component", "build component", "develop component".
metadata:
  author: BIGboss248
  version: "2.3"
---

# Next.js Component & Skeleton Development (`nextjs-component-dev`)

Specialized workflow for creating production-ready React Server Components (RSC) and Client Components with next-intl dictionary-backed translations, semantic theme tokens, and live runtime diagnostics via `next-devtools` MCP. Suspense skeletons are **conditional**: they ship only for components that can suspend or lazy-load, and are deliberately skipped for static components. This skill creates implementation only; test authoring is owned exclusively by `nextjs-test`.

> [!CRITICAL]
> **MANDATORY COMPONENT CREATION INVARIANT:** Whenever you create any new React or Next.js component (whether requested directly by the user, created as part of a page build, or executed from `docs/plan/`), you **MUST** strictly follow every architectural standard and workflow step in this skill. Never create ad-hoc `.tsx` component files without executing this workflow (Next.js local docs lookup, `implementation_plan.md`, surface-folder placement (`<new_component_dir>/<surface>/<component_name>.tsx`), `messages/[locale].json` dictionary sync, the skeleton decision gate (§1.2), and `verify-dev` verification). Test files are **not** part of this workflow: `nextjs-test` owns them.

> [!IMPORTANT]
> **Standalone invocation is self-sufficient.** When this skill is triggered on its own (`/nextjs-component-dev`, "create component", "build this card") — with no orchestrator, page skill, or plan file driving it — the same two gates still apply and are never delegated or skipped:
>
> 1. **Surface-first categorization (§1.1)** — resolve the owning surface folder from the component's renderers *before* the first write.
> 2. **Skeleton decision gate (§1.2)** — classify the component as *can suspend/lazy-load* or *static* first, record the verdict, then either ship `<component_name>_skeleton.tsx` **and** wire it as the `<Suspense>` / `next/dynamic` fallback, or explicitly skip it with the reason recorded.
>
> If the surface cannot be resolved, or the skeleton verdict is genuinely ambiguous, stop and ask the user. Never fall back to an ad-hoc file, a `global/` folder, a per-component folder, a skeleton on a purely static component, or a streaming component shipped without a wired fallback.

> [!TIP]
> **Modular Assets & Templates:**
>
> - Next.js Docs Search & Context: [`references/nextjs-docs-lookup.md`](./references/nextjs-docs-lookup.md)
> - Forms & Server Actions Guide: [references/form-server-actions.md](./references/form-server-actions.md)
> - Test Authoring (separate skill, run after creation): [`../nextjs-test/SKILL.md`](../nextjs-test/SKILL.md)
> - Storybook Standards & Separation: [`references/storybook-reference.md`](./references/storybook-reference.md)
> - Instant Navigation & Prefetching: [`references/instant-navigation-and-prefetching.md`](./references/instant-navigation-and-prefetching.md)
> - Next DevTools Debugging Guide: [`references/next-devtools-debugging.md`](./references/next-devtools-debugging.md)
> - Caching & Revalidation: [`references/caching-and-revalidation.md`](./references/caching-and-revalidation.md)
> - RSC, State Boundaries & Lazy Loading: [`references/rsc-and-state-boundaries.md`](./references/rsc-and-state-boundaries.md)
> - Code Templates: [`resources/templates/`](./resources/templates/) ([Component](./resources/templates/component.template.tsx), [Form Component](./resources/templates/form-component.template.tsx), [Skeleton](./resources/templates/skeleton.template.tsx), [Link Status Button](./resources/templates/link-status-button.template.tsx))
> - Source Tree Isolation & Approval-Gated Merge: [`../nextjs-dev-setup/references/agent-worktree-isolation.md`](../nextjs-dev-setup/references/agent-worktree-isolation.md)
> - Test Execution Tiers (fast vs pre-push): [`../nextjs-test/references/shared/test-execution-tiers.md`](../nextjs-test/references/shared/test-execution-tiers.md)
> - Test Templates (owned by `nextjs-test`): [`../nextjs-test/resources/templates/`](../nextjs-test/resources/templates/)
> - Reference Implementations: [`examples/`](./examples/)
> - Verification Scripts: [`scripts/verify-dev.ps1`](./scripts/verify-dev.ps1) (Windows) / [`scripts/verify-dev.sh`](./scripts/verify-dev.sh) (Linux)

---

## Architectural Rules & Standards

### 1. Planning Context, Surface Categorization & Skeleton Decision

- Read `docs/project.json` to resolve `package_manager`, `new_component_dir`, `style_file_dir`, `component_library`, `dictionaries_dir` (default: `"messages"`), and `supported_languages`.
- All internal routes MUST use `ROUTES` from `@/lib/routes`.
- All author/site metadata MUST use `SITE_CONFIG` from `@/lib/site-config`.

#### 1.1 Surface Categorization (mandatory — also when invoked alone)

A component's folder is decided by **who renders it**, never by its own name. Resolve the surface before the first write and record the evidence in `implementation_plan.md`.

| Owning surface | Use when | Examples |
| :--- | :--- | :--- |
| `<page-segment>/` | Exactly one route segment renders it (`app/[locale]/<segment>/page.tsx` or its sections) | `home/hero.tsx`, `about/team_grid.tsx`, `lab/experiment_card.tsx` |
| `<layout-region>/` | A `layout.tsx` renders it on every route | `header/navbar.tsx`, `header/theme_button.tsx`, `footer/site_footer.tsx`, `sidebar/docs_sidebar.tsx` |
| `shared/` | Two or more surfaces or pages import it | `shared/section_heading.tsx`, `shared/empty_state.tsx` |
| `ui/` | Design-system primitive with no page or business knowledge | `ui/button.tsx`, `ui/badge.tsx` |

**Decision procedure — apply in order:**

1. **Find the renderers** — grep `app/`, every `layout.tsx`, and the existing surface folders for the component name or the import that will reference it.
2. **Zero renderers yet** → it belongs to the page segment you are building; never invent a folder from the component's own name.
3. **Exactly one page renderer** → that page segment.
4. **Two or more renderers, or explicitly designed for reuse** → `shared/`.
5. **Rendered by `app/[locale]/layout.tsx` or a nested `layout.tsx`** → the matching layout region (`header/`, `footer/`, `sidebar/`).
6. **No route knowledge, no data access, no business copy** → `ui/`.
7. **Still ambiguous** (for example a card used by one page today and planned for three) → stop and ask the user; never guess.

- **Target path**: `<new_component_dir>/<surface>/<component_name>.tsx` — flat files, no per-component subfolder, no per-component `index.ts` (an optional area-level `<surface>/index.ts` barrel is allowed).
- **Forbidden**: the retired `global/` folder, `components/<component_name>/`, and any folder derived from the component's own name.
- **Promotion rule**: the moment a second surface imports a page-scoped component, move it to `shared/` in the same change and update every import.
- **Naming**: `snake_case.tsx` files with `PascalCase` exports (`theme_button.tsx` → `ThemeButton`). Companions are flat siblings in the same surface folder: `<component_name>_skeleton.tsx` **(only when §1.2 requires it)** and, when `nextjs-test` runs, `<component_name>.test.tsx`, `<component_name>.edge.test.tsx`, `<component_name>.test-plan.md`; `<component_name>.stories.tsx` only when Storybook is in scope.
- **Test mirror**: QA Playwright specs live at `tests/e2e/components/<surface>/<component_name>.spec.ts` and are authored by `nextjs-test`.

```text
<new_component_dir>/
├── header/                       # layout region
│   ├── navbar.tsx
│   ├── navbar_skeleton.tsx       # only if navbar suspends / lazy-loads
│   └── theme_button.tsx          # static? no skeleton
├── home/                         # page segment
│   ├── hero.tsx
│   └── hero_skeleton.tsx         # only if hero awaits data or streams
├── shared/                       # reused by 2+ surfaces
└── ui/                           # design-system primitives (static → no skeletons)
```

#### 1.2 Skeleton Decision Gate (mandatory — also when invoked alone)

A skeleton is a **streaming fallback**, not a mandatory companion file. It exists to fill the component's box while the real content is still being produced. A static component that finishes synchronously in the same server pass must **not** ship one: a fallback that can never paint is dead code that silently drifts out of sync with the real layout.

**Decision question: can this component suspend, lazy-load, or wait on I/O before its HTML exists?**

| Verdict | Use when | Typical cases |
| :--- | :--- | :--- |
| **Skeleton required** | The component's box can be painted before its content is ready | Async RSC awaiting data (`fetch`, DB/API, `await params` / `await searchParams`, `cookies()`, `headers()`, `connection()`); a section placed inside `<Suspense>`; `useSuspenseQuery`; lazy `next/dynamic` leaves (charts, rich-text editors, dialogs, below-the-fold widgets); `ssr: false` client-only leaves; a route that composes `loading.tsx` |
| **No skeleton** | The component renders completely and synchronously during the server pass | Static/presentational RSC whose data arrives as props or literal copy and which contains no `await`; layout chrome such as `footer/` or a static `header/` row; `ui/` primitives (`button`, `badge`, `input`); client leaves whose initial state paints instantly with no lazy import and no browser-API gate |

1. **Record the verdict before the first write** — in `implementation_plan.md`: `skeleton: required — <trigger>` or `skeleton: not required — static (<evidence>)`. The verdict is a decision with a reason, never a default.
2. **Required → ship the artifact**: `<new_component_dir>/<surface>/<component_name>_skeleton.tsx`, a flat sibling exporting `[ComponentName]Skeleton` (start from [`skeleton.template.tsx`](./resources/templates/skeleton.template.tsx)).
3. **Required → wire it; an unwired skeleton is a failed deliverable:**
   - Async RSC or data-reading section: the parent renders `<Suspense fallback={<ComponentNameSkeleton />}><ComponentName /></Suspense>`.
   - Lazy client leaf: `dynamic(() => import("./x").then((m) => m.X), { loading: () => <XSkeleton /> })`, plus `{ ssr: false }` for browser-only APIs.
   - TanStack Query: `useSuspenseQuery` inside `<Suspense fallback={<ComponentNameSkeleton />}>`.
   - Route level: `loading.tsx` composes the section skeletons instead of a blank page (see `nextjs-page-dev`).
4. **Required → geometry parity (CLS = 0)** — reuse the component's outer wrapper element and classes verbatim: same padding, `max-w-*`, `gap-*`, border and radius, `grid`/`flex` layout, row and column counts, responsive breakpoints (`sm:`/`md:`/`lg:`), media aspect ratios or fixed heights, and the same number of placeholder items and text lines.
5. **Required → tokens only, pure and static** — `animate-pulse bg-muted` (or `bg-muted/70`) blocks inside the same semantic container (`border border-border bg-card rounded-xl`). No hardcoded colors, no physical-direction classes, no data fetching, no hooks, no `"use client"`, no props beyond an optional `className`. Mark decorative blocks `aria-hidden="true"`; any localized loading label comes from the dictionary, never inline.
6. **Required → streaming-order check** — on a slow response the layout must show the skeleton inside the component's exact box: never a full-page spinner and never a blank gap. Confirm with the Next DevTools Navigation Inspector ("Pause on navigations").
7. **Not required → create nothing.** Do not add a `_skeleton.tsx` file, and do not wrap a static component in a `<Suspense>` boundary purely to justify one. Record the reason in `implementation_plan.md` and in the final report so the omission is visible and intentional.
8. **Verdicts go stale.** The moment a component gains `await`, a data hook, a lazy `next/dynamic` import, or a browser-API gate, re-run this gate and add the skeleton **in the same change**. A skeleton that already exists for a component that became static is removed the same way, with the reason recorded.
9. **When genuinely undecidable** (for example a client component a future parent may stream), ask the user and record the answer. Never add a skeleton "just in case", and never omit one for a component that can suspend.

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
- **Localized Links & Contextual Feedback:** Every internal `<Link>` comes from `@/i18n/navigation` (next-intl `createNavigation`), which applies the active locale prefix automatically; a raw `next/link` href loses the prefix and forces a proxy redirect. `next/link` is permitted only for hash anchors, external URLs, and the locale-less root `not-found.tsx`. For pending navigation feedback, render a child that calls `useLinkStatus()` from `next/link` (see [`link-status-button.template.tsx`](./resources/templates/link-status-button.template.tsx)); never add a global progress-bar package.
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
     - **Dense Card Grids & Scoped Link Feedback:** NEVER use blanket `prefetch={true}` across dozens of cards in feeds. Retain default `<Link>` or use hover/focus intent prefetching (`router.prefetch()`), and pair with `useLinkStatus` to provide instant localized feedback when un-prefetched dynamic links are clicked.
- **Granular Loading States (Anti-Full-Page Flash)**: Never wrap an entire component or page in a single top-level `<Suspense>` boundary that flashes full skeletons. Keep titles, layout frames, and cached content visible immediately; place `<Suspense>` strictly around dynamic streaming slots.
- **Native Next.js 16 Caching Directives**: Consult [`references/instant-navigation-and-prefetching.md`](./references/instant-navigation-and-prefetching.md) and [`references/caching-and-revalidation.md`](./references/caching-and-revalidation.md).

### 7. TanStack Query & Server Prefetching

- **Unified Cache Contract:** Define `key`, `tag`, and `queryOptions` with explicit `staleTime` (e.g. `30_000` ms).
- **Server Prefetch:** Trigger unawaited prefetch (`void queryClient.prefetchQuery(...)`) calling internal DB functions directly (zero relative fetch on server). Dehydrate with `<HydrationBoundary>`.
- **Streamed Components:** Use `useSuspenseQuery` inside `<Suspense fallback={<[ComponentName]Skeleton />}>`.
- **Optimistic Mutations:** Use `useMutation` with `onMutate` cache snapshots and `onError` rollbacks; call Server Actions with `updateTag(cache.tag)`.

### 8. Test Ownership (`nextjs-test`)

- **Creation only.** This skill never writes, edits, scaffolds, or plans tests. Jest + RTL, Playwright, test plans, and adversarial suites live exclusively in [`nextjs-test`](../nextjs-test/SKILL.md), which is the only test-writing skill in the Next.js set.
- **Separate step.** Test authoring runs after creation, or before implementation when the user deliberately invokes `nextjs-test` in `baseline` mode. Never block component creation on a test suite, and never invent one to satisfy this workflow.
- **Read-only feedback.** If tests already exist (companion backfill), run the targeted files and report failures; never change an assertion. Fix the component instead.
- **Fast tier only.** Never run Playwright, the full Jest project, `build`, or Storybook builds during development: those are the expensive tier and run at `git push` through `.husky/pre-push`.
- **Handoff.** At the end of creation, state that no tests were written and name `nextjs-test` as the follow-up owner.

### 9. Source Tree Isolation (Worktrees) & Approval-Gated Merge

- **Your own worktree.** Implementation agents do not write in the user's working tree. Create a worktree on branch `agent/<kebab-task-slug>` off `main` before the first write:
  ```powershell
  pwsh .agents/skills/nextjs-dev-setup/scripts/agent-worktree.ps1 -Action create -Slug hero-card
  ```
  ```bash
  bash .agents/skills/nextjs-dev-setup/scripts/agent-worktree.sh create hero-card
  ```
- **One task, one worktree, one branch.** Never reuse another agent's worktree and never write in the main tree while the worktree task is open.
- **Run the fast gates inside the worktree**, then commit the scoped changes on `agent/<slug>`.
- **Merge only on explicit approval.** Present the change set, then stop and wait. Nothing reaches `main` until the user approves:
  ```powershell
  pwsh .agents/skills/nextjs-dev-setup/scripts/agent-worktree.ps1 -Action review -Slug hero-card
  pwsh .agents/skills/nextjs-dev-setup/scripts/agent-worktree.ps1 -Action merge -Slug hero-card -Approved
  ```
  ```bash
  bash .agents/skills/nextjs-dev-setup/scripts/agent-worktree.sh review hero-card
  bash .agents/skills/nextjs-dev-setup/scripts/agent-worktree.sh merge hero-card --approved
  ```
  `review` prints the commits, diffstat, and changed paths without touching `main`. `merge` without `-Approved`/`--approved` prints the same review and exits `4` with `[APPROVAL REQUIRED]` — that exit is a stop signal, not an error to work around. Never simulate approval with a raw `git merge`.
- **Conflicts are not yours to resolve.** Abort the merge, keep the branch, and ask the user how to resolve it. Full contract: [`agent-worktree-isolation.md`](../nextjs-dev-setup/references/agent-worktree-isolation.md).

---

## Phase 0: Implementation Plan & Approval Gate

> [!IMPORTANT]
> **Plan Before Execution:** Always generate and present an `implementation_plan.md` artifact detailing all planned file creations, modifications, TypeScript contracts, and translation dictionary additions before executing any write operations, modifying dictionaries, or creating components in the repository. Wait for user confirmation/approval before proceeding with execution.

The implementation plan must cover:

1. **Target Surface, Path & Classification**: The owning surface folder (`<page-segment>/`, `header/`, `footer/`, `sidebar/`, `shared/`, or `ui/`) with the **renderer evidence** found in §1.1 (which page or layout file renders it, or "no renderer yet → page segment being built"), the exact flat file path `<new_component_dir>/<surface>/<component_name>.tsx`, and classification (RSC, Eager Client leaf, Lazy Client leaf with `next/dynamic`, or Client-only with `ssr: false`).
2. **Next.js Local Docs Consulted**: Specific doc paths checked under `node_modules/next/dist/docs/` (e.g. `04-api-reference/04-components/image.md`, `03-directives/use-cache.md`, `04-api-reference/02-functions/use-router.md`).
3. **TypeScript Contracts**: Prop interfaces and types with strict English TSDoc annotations.
4. **Dictionary Strategy**: Explicit translation namespaces and keys to add to `messages/[locale].json` across all `supported_languages` in `docs/project.json` (zero hardcoded strings or in-file mock dictionaries).
5. **Theme Tokens & Styling**: Identified semantic OKLCH CSS variables and logical layout classes.
6. **Testing Handoff (`nextjs-test` owns it)**: Do not enumerate or plan test cases in this artifact. Record that this skill writes no tests and that `nextjs-test` owns the suite as a separate step.
7. **Verification Gate**: `verify-dev.ps1`/`.sh` for companion files and i18n. Existing tests may be run read-only for feedback; Playwright, the full Jest project, and builds are the expensive tier and run at `git push` (pre-push), not here.
8. **Skeleton Verdict (§1.2)**: The classification evidence — whether the component can suspend, lazy-load, or wait on I/O, or is static — and the resulting verdict. When required: the skeleton file path, the exact parent file and boundary that imports it (`Suspense fallback`, `next/dynamic` `loading`, or `loading.tsx`), and the geometry elements mirrored from the component (wrapper classes, grid/flex, breakpoints, item and line counts). When not required: `skeleton: not required — static (<evidence>)`. Ambiguous cases are escalated to the user, never defaulted.
9. **Approval Gate**: The worktree branch `agent/<slug>`, the fact that all work lands there, and that merging into `main` waits for explicit user approval after the `review` summary.

---

## Workflow Steps

- [ ] **Step 0: Implementation Plan Generation & Approval Gate**
  - Search and inspect `node_modules/next/dist/docs` via `codebase-memory` MCP (`search_code`, `search_graph`) for any Next.js APIs, directives, hooks, or components utilized by the planned component to ensure up-to-date context.
  - Synthesize component requirements, scan `docs/project.json`, and generate `implementation_plan.md` documenting consulted docs, the surface decision with its renderer evidence (§1.1), and the skeleton verdict with its trigger or static evidence (§1.2).
  - Set `request_feedback = true` and `user_facing = true` on the artifact.
  - Wait for user review and explicit approval before writing any code.
  - **Form / Mutation Component Routing Gate**: If the component renders a form or accepts user mutations, read references/form-server-actions.md. Grill the user on whether to include useOptimistic and document the recommendation in implementation_plan.md.

- [ ] **Step 0.5: Create the Isolated Worktree**
  - Create branch `agent/<kebab-task-slug>` off `main` with `agent-worktree.ps1` / `.sh` (`-Action create`).
  - Install dependencies inside the worktree; it shares `.git` but not `node_modules`.
  - Do all reads, writes, and commands from the worktree path for the rest of the task.
  - The branch stays isolated until Step 6: nothing is merged into `main` before explicit user approval.

- [ ] **Step 1: Dev Server Verification & Next DevTools Connection**
  - Query `next-devtools` MCP via `nextjs_index` to detect running Next.js dev server instances.
  - **If Dev Server is running:** Tune into the active port and server instance; continue developing without restarting.
  - **If Dev Server is NOT running:** Start the dev server in the background (`pnpm dev`, `IsDaemon: true`) and verify connection via `nextjs_index`.

- [ ] **Step 2: Dictionary Population & TypeScript Contract Definition**
  - Read `docs/project.json` to resolve `dictionaries_dir` (`messages` is default) and `supported_languages`.
  - Define the component's translation namespace and keys.
  - **Populate all dictionary files** (`messages/en.json`, `messages/fa.json`, etc.) with authentic translations for every supported language before writing JSX.
  - Define prop interfaces with strict **English TSDoc** annotations (`@param`, `@defaultValue`, `@returns`).
  - If there are more than one supported language, component must fetch the translation first and if failed use fallbacks.

- [ ] **Step 3: Component Implementation & Conditional Skeleton**
  - Create the primary component at the exact flat path resolved in Phase 0: `<new_component_dir>/<surface>/<component_name>.tsx`. Never invent a new top-level folder and never create a per-component subfolder.
  - Implement it (RSC or Client Component) consuming translations via `next-intl` (`getTranslations` or `useTranslations`) with zero hardcoded placeholders or in-file mock dictionary objects. For heavy or conditionally rendered interactive leaves, wrap via `next/dynamic` with `loading: () => <ComponentNameSkeleton />` (or `{ ssr: false }` for browser-only APIs). When building interactive cards or dense feed items with links, pair with `useLinkStatus` for contextual click feedback.
  - **Apply the skeleton gate (§1.2) before writing any fallback.** If the component can suspend, lazy-load, or wait on I/O, create `<component_name>_skeleton.tsx` alongside it, mirroring the outer wrapper, padding, grid/flex, breakpoints, item and line counts, and token classes so it renders in the component's exact box with **CLS = 0**, then **wire it in the same change** by importing it in the owning parent — the page, layout, section, or `next/dynamic` call — as the `<Suspense fallback>` (or `loading.tsx` composition). A skeleton that no boundary imports is an orphan and does not satisfy this step.
  - **If the component is static, skip the skeleton deliberately.** No `_skeleton.tsx` file, no `<Suspense>` wrapper added only to host a fallback. Record `skeleton: not required — static (<evidence>)` in `implementation_plan.md` and name that decision in the report.
  - Follow the surface's existing naming; do not add a per-component `index.ts` barrel (an area-level `<surface>/index.ts` is optional).
  - **No tests here.** Do not create `<component_name>.test.tsx`, `<component_name>.edge.test.tsx`, `<component_name>.test-plan.md`, or Playwright specs; `nextjs-test` owns them.

- [ ] **Step 4: Fast Verification Gate (no expensive suites)**
  - **Next DevTools Runtime Inspection & Navigation Inspector:** Use `next-devtools` MCP server (`nextjs_call`) to check for compilation errors, runtime exceptions, hydration issues, or broken routes. Use Navigation Inspector ("Pause on navigations") to verify the static shell and App Shell render instantly with granular fallbacks.
  - **Companion & i18n Verification:** Run `verify-dev.ps1`/`.sh` (file presence + skeleton verdict + dictionary compliance; it does not execute tests) against the component file. Pass `-SkeletonMode required` when §1.2 demands a skeleton and `-SkeletonMode not-required` for a static component; the default `auto` infers the verdict from the component source (`await`, `next/dynamic`, `useSuspenseQuery`, `cookies()`/`headers()`, `ssr: false`):
    - **Windows (PowerShell):** `pwsh .agents/skills/nextjs-component-dev/scripts/verify-dev.ps1 -ComponentPath <new_component_dir>/<surface>/<component_name>.tsx`
    - **Linux / macOS (Bash):** `bash .agents/skills/nextjs-component-dev/scripts/verify-dev.sh <new_component_dir>/<surface>/<component_name>.tsx`
  - **Existing Suite Feedback (read-only, optional):** when companion backfill finds tests that already exist, run only those files (e.g. `pnpm test -- <new_component_dir>/<surface>/<component_name>.test.tsx`) and report failures. Never author or edit them.
  - **Forbidden here:** `pnpm run test:e2e`, `pnpm exec playwright test`, bare `pnpm test`, `pnpm run test:all`, `pnpm build`, `storybook build`. These are expensive and belong to the pre-push gate.
  - Fix syntax errors, missing dictionary keys, or implementation defects until the creation gates pass.

- [ ] **Step 5: Implementation Plan Checklist Synchronization**
  - When orchestrated, the orchestrator checks off the completed component item (`- [x]`) in `docs/plan/05-pages-and-components.md`.
  - If all sub-components and page infrastructure tasks for the parent page are completed, the orchestrator checks off the parent page item (`- [x]`).
  - When invoked directly without the orchestrator, perform this step yourself.

- [ ] **Step 6: Present for Approval, Then Merge into `main`**
  - `git add <changed paths>` and commit on `agent/<slug>` (scoped commits inside the worktree are the only permitted commits).
  - Run the review from the main worktree and include its output in the report: `agent-worktree.ps1 -Action review -Slug <slug>` / `agent-worktree.sh review <slug>` (commits, diffstat, changed paths).
  - **STOP here and wait for explicit user approval.** Do not merge, do not remove the worktree, and do not report the work as landed before that approval. Running `merge` without `-Approved`/`--approved` prints the review and exits `4` — that is the gate working, not a failure to route around.
  - After approval, merge with the approved flag: `agent-worktree.ps1 -Action merge -Slug <slug> -Approved` / `agent-worktree.sh merge <slug> --approved` (local `--no-ff` merge).
  - **On a merge conflict:** do not resolve it. The helper aborts the merge, keeps the branch, prints the conflicting paths, and exits `3`. Report `BLOCKED: merge conflict` and ask the user to choose rebase / keep main / manual resolution.
  - Merging is local only. Never `git push`, never `--no-verify`; the expensive tier runs at push from `.husky/pre-push`.

---

## Pre-Report Self-Audit (run before answering the user)

Even when this skill is invoked alone, do not report a component as done until every line is true:

- [ ] **Surface resolved with evidence** — the file sits in the surface folder that actually renders it, and the renderer path (page, layout, or "no renderer yet → page segment") is named in the plan and in the report.
- [ ] **No forbidden folders** — no `global/`, no `components/<component_name>/`, no folder named after the component.
- [ ] **Skeleton verdict recorded** — `implementation_plan.md` states either `skeleton: required — <trigger>` or `skeleton: not required — static (<evidence>)`; no component is shipped without a stated verdict.
- [ ] **Skeleton matches the verdict** — a streaming/lazy component has `<component_name>_skeleton.tsx` as a flat sibling and a boundary that imports it (`<Suspense fallback>`, `next/dynamic` `loading`, or `loading.tsx`); a static component has **no** skeleton file and no fallback boundary added for show.
- [ ] **Geometry parity (only when a skeleton exists)** — wrapper, padding, grid/flex, breakpoints, item and line counts match the component; skeleton tokens only (`bg-muted`, `animate-pulse`).
- [ ] **Translations complete** — every string lives in `messages/[locale].json` for all `supported_languages`; no in-file dictionaries.
- [ ] **Creation gate green** — `verify-dev` passes with no missing dictionaries.
- [ ] **No tests written** — no `*.test.ts(x)`, `*.edge.test.tsx`, `*.test-plan.md`, or Playwright spec was created or edited; `nextjs-test` is named as the next owner.
- [ ] **Merge withheld until approval** — the work is committed on `agent/<slug>`, `review` output is in the report, and `main` is untouched until the user explicitly approves.

---

## Edge Cases & AI Pitfalls

- **Surface-First Placement:** Never derive a component's folder from its own name, never resurrect the retired `global/` folder, and never nest a per-component folder. Decide the owning surface before the first write: layout region (`header/`, `footer/`, `sidebar/`) when a layout renders it, the page segment when exactly one page renders it, `shared/` when two or more surfaces do, `ui/` for design-system primitives. Promote a page-scoped component to `shared/` the moment a second surface imports it.
- **Ambiguous surface:** A card that one page renders today but three pages will render tomorrow is `shared/` from the start only when the user confirms the reuse. Otherwise place it in the page segment and apply the promotion rule on the second import. Never guess silently.
- **Skeleton on a static component:** A synchronous, prop/literal-driven component (a `ui/` primitive, static footer, static heading) must not ship a `_skeleton.tsx`. The fallback never paints, and it becomes a second layout to maintain. If the component is static, say so in the plan and skip it.
- **Stale skeleton verdict:** Adding `await`, a data hook, `next/dynamic`, or a browser-API gate to a previously static component invalidates `skeleton: not required`. Re-run §1.2 and add the wired skeleton in the same change; conversely, delete the skeleton when the async source is removed.
- **Orphan skeleton:** A `<component_name>_skeleton.tsx` that no `<Suspense>` boundary, `next/dynamic` call, or `loading.tsx` imports does not satisfy §1.2 — the user still sees a blank gap. Wire it in the same change.
- **Skeleton geometry drift:** A generic `h-96 w-full animate-pulse` block is not a skeleton. Copy the component's real wrapper classes, grid, and breakpoints, or the layout jumps when the content streams in.
- **Local Docs Verification via Codebase Memory MCP:** Always search `node_modules/next/dist/docs/` using `codebase-memory` MCP tools (`search_code`, `search_graph`) before authoring components. Never assume deprecated Next.js API signatures or outdated caching mechanisms; local docs reflect the exact runtime version installed.
- **Zero In-File i18n Fallbacks:** Never hardcode dictionary objects or fallbacks (`const DEFAULT_CONTENT = {...}`) in TSX files. All text must come from `messages/[locale].json`.
- **Hydration Warning Detection & Browser APIs:** Never access browser-only globals (`window`, `localStorage`) during SSR. Use `dynamic(() => import('./Widget'), { ssr: false, loading: () => <WidgetSkeleton /> })` instead of double-rendering `useEffect(mounted)` flags to eliminate hydration crashes cleanly.
- **Strict Logical Styling (BiDi):** Never use physical directions (`ml-`, `mr-`, `pl-`, `pr-`, `left-`, `right-`). Always use logical alternatives (`ms-`, `pe-`, `ps-`, `me-`, `start`, `end`).
- **Test Separation:** Never write, edit, or scaffold test files (`*.test.tsx`, `*.edge.test.tsx`, `*.test-plan.md`, `tests/e2e/**`). Test authoring is owned exclusively by `nextjs-test` and runs as a separate step. Existing tests may be run read-only for feedback.
- **Isolation Before Code:** Never start a component in the user's working tree. Create the `agent/<slug>` worktree first and write there.
- **Never merge before approval:** The worktree branch is a proposal, not a delivery. Commit there, run `review`, and stop. `merge` without `-Approved`/`--approved` exits `4` by design; present the review to the user and wait. Bypassing the flag with a raw `git merge`, `-X ours`, or a force-push is a contract violation, not a shortcut.
- **Merge Conflicts Are a Stop Signal:** Abort the merge, keep the branch, and ask the user. Never `-X ours`/`-X theirs`, never force-push, never rewrite history.
- **Storybook Story Separation:** Do not author `.stories.tsx` or run Storybook builds during standard component development unless the `nextjs-storybook-story` skill is specifically requested. Consult [`references/storybook-reference.md`](./references/storybook-reference.md).
