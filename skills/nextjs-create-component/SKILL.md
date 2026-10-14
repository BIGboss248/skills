---
name: nextjs-create-component
description: Workflow for creating or backfilling Next.js App Router components with TDD unit tests, Suspense skeletons, CSF3 Storybook stories, and adversarial QA audits.
description: Master orchestrator skill for creating or backfilling Next.js App Router components by coordinating component development, Storybook stories, and adversarial QA.
metadata:
  author: BIGboss248
  version: "2.0"
  version: "2.1"
---

# Next.js Component Creation Skill (`nextjs-create-component`)
# Next.js Component Creation Orchestrator (`nextjs-create-component`)

Step-by-step workflow, architectural rules, and engineering standards for creating or backfilling production-ready React components (RSC and Client Components) in Next.js App Router applications.
Master workflow orchestrator that coordinates specialized micro-skills to create or backfill production-ready Next.js React components with Suspense skeletons, CSF3 Storybook stories, and adversarial QA test suites.

> [!TIP]
> **Modular Assets Available:**
>
> - Reference implementations (RSC & TanStack Query): [`examples/`](./examples/)
> - Comprehensive anti-patterns & pitfalls: [`references/pitfalls.md`](./references/pitfalls.md)
> - JSON Plan Schema: [`resources/plan-schema.json`](./resources/plan-schema.json)
> - File Verification Script: [`scripts/verify-component-files.ts`](./scripts/verify-component-files.ts)
> **Specialized Sub-Skills Coordinated by this Orchestrator:**
> 1. [`nextjs-component-dev`](../nextjs-component-dev/SKILL.md): Component, Suspense skeleton, and TDD unit tests.
> 2. [`nextjs-storybook-story`](../nextjs-storybook-story/SKILL.md): CSF3 stories with controls, action spies, and 4 theme variants.
> 3. [`nextjs-adversarial-qa`](../nextjs-adversarial-qa/SKILL.md): Independent subagent QA audit and adversarial edge tests.

---

## Architectural Rules & Core Constraints
## High-Level Orchestration Pipeline

### 1. Planning Context & Single Source of Truth
```
                 [Step 0: Load Context (docs/project.json, design, plan)]
                                         │
                                         ▼
                 [Step 1: Check Existence & Companion File Gap Analysis]
                                         │
                   ┌─────────────────────┴─────────────────────┐
                   ▼                                           ▼
             [Scratch Mode]                        [Companion Backfill Mode]
                   │                                           │
                   ├───────────────► Phase 1 ◄─────────────────┤
                   │   Invoke nextjs-component-dev (if missing)│
                   │   Verify via verify-dev.ps1 / .sh         │
                   │                                           │
                   ├───────────────► Phase 2 ◄─────────────────┤
                   │   Invoke nextjs-storybook-story (if miss.)│
                   │   Verify via verify-storybook.ps1 / .sh   │
                   │                                           │
                   ├───────────────► Phase 3 ◄─────────────────┤
                   │   Invoke nextjs-adversarial-qa (if miss.) │
                   │   Execute edge tests via test runner      │
                   │                                           │
                   └─────────────────────┬─────────────────────┘
                                         ▼
                           [Step 5: Completion & Handoff]
```

Before creating or modifying components, read the planning artifacts created by `nextjs-plan`:

- **`docs/project.json`**: Read via `view_file` to determine `package_manager`, `new_component_dir`, `style_file_dir`, `component_library`, `animation_library`, and `supported_languages`. **Never guess paths.**
- **`lib/routes.ts`**: All internal links, redirects, and action targets MUST use `ROUTES` from `@/lib/routes`.
- **`lib/site-config.ts`**: All author bio, contacts, socials, and base metadata MUST use `SITE_CONFIG` from `@/lib/site-config`.
- **`docs/design/`**: Consult `02-sitemap-and-routes.md` (SSG/ISR/SSR rendering matrix) and `03-ui-design-tokens.md` (OKLCH palette, font pairings, radii).
- **`docs/plan.md`**: Identify active milestones (Reusable Components, Layout Shell, Pages).

### 2. RSC Placement, Boundaries & Folder Hierarchy

1. **Default to Server Components (RSC):** Keep components server-rendered by default. Push `"use client"` down to micro leaf components (interactive buttons, input handlers).
2. **RSC Composition:** Pass Server Components as `children` or props into Client wrappers. Never import Server Components inside `"use client"` files.
3. **Dedicated Folder Structure:** Every component and its companion files MUST reside in a dedicated folder under `<new_component_dir>/<page_or_global>/<ComponentName>/`:

   ```text
   <new_component_dir>/<page_or_global>/<ComponentName>/
   ├── [ComponentName].tsx               # Primary component (RSC or Client Component)
   ├── [ComponentName]Skeleton.tsx       # Suspense fallback skeleton matching geometry
   ├── [ComponentName].stories.tsx       # Co-located Storybook CSF3 story (main components only)
   ├── [ComponentName].test.tsx          # Baseline TDD unit tests
   ├── [ComponentName].edge.test.tsx     # Adversarial edge-case test suite
   ├── [ComponentName].types.ts          # Extracted TypeScript interfaces (if complex)
   └── index.ts                          # Clean barrel export
   ```

   - Category folder: `global/` for shared layout chrome (headers, footers, switchers, drawers); `<page-name>/` (e.g. `home/`, `about/`, `lab/`) for page-scoped sections.
   - Handle responsive viewports directly within the component using Tailwind CSS breakpoint classes (`sm:`, `md:`, `lg:`).

### 3. Styling, Links & Logical Properties

- **Theme Tokens:** Exclusively use semantic CSS variables from `app/globals.css` (`bg-background`, `text-foreground`, `border-border`, `text-muted-foreground`). Hardcoded hex/color scales (`bg-blue-500`, `#FAFAFA`) are strictly FORBIDDEN.
- **Class Merging:** Always merge classes using `cn(...)` (`clsx` + `tailwind-merge`).
- **BiDi RTL/LTR:** Exclusively use Tailwind logical properties (`ms-`, `pe-`, `ps-`, `me-`, `start`, `end`). Physical properties (`ml-`, `mr-`, `pl-`, `pr-`, `left-`, `right-`) are FORBIDDEN.
- **Progress-Aware Links:** Use `<Link>` from `@vercel/react-transition-progress` for primary navigation, hero CTAs, and interactive cards; use standard `next/link` for static footers/utility links. Raw `<a>` tags are forbidden.
- **Images:** Always use `next/image` with explicit dimensions or `fill`, responsive `sizes`, and `priority` for above-the-fold LCP assets.

### 4. Storybook CSF3 Component Standards (`[ComponentName].stories.tsx`)

- **Main Component Scope Only:** Interactive client logic is pushed down to leaf Client Components. Do NOT create stories for micro leaf helpers. Create stories ONLY for the main composite component.
- **Interactive Controls & Spies:** Map props to `argTypes` controls and bind `fn()` from `storybook/test` to all callback props in default `args` so interactions log to the Actions panel.
- **Comprehensive Docs (`parameters.docs`):** Document overview, RSC/Client boundaries, interactions, and accessibility in `meta.parameters.docs.description.component`.
- **Four Canonical Story Variants (Zero Hardcoding):** Export strictly four variants wrapped in semantic token containers (`bg-background text-foreground border-border`) with scoped `.light` and `.dark` classes:
  1. `Light`: `parameters: { themes: { themeOverride: "light" }, backgrounds: { default: "light" } }` with `.light` wrapper and `"Light Mode"` label.
  2. `Dark`: `parameters: { themes: { themeOverride: "dark" }, backgrounds: { default: "dark" } }` with `.dark` wrapper and `"Dark Mode"` label.
  3. `SkeletonLight`: `render: () => <[ComponentName]Skeleton />` with `.light` wrapper and `"Skeleton (Light)"` label.
  4. `SkeletonDark`: `render: () => <[ComponentName]Skeleton />` with `.dark` wrapper and `"Skeleton (Dark)"` label.

### 5. TanStack Query & Server Prefetching

- **Unified Cache Contract:** Define `key`, `tag`, and `queryOptions` with explicit `staleTime` (e.g. `30_000` ms).
- **Server Prefetch:** Instantiate `new QueryClient()` per request. Trigger prefetch without awaiting (`void queryClient.prefetchQuery(...)`) calling internal DB functions directly (zero relative fetch on server). Dehydrate with `<HydrationBoundary>`.
- **Streamed Components:** Use `useSuspenseQuery` inside `<Suspense fallback={<Skeleton />}>`.
- **Optimistic Mutations:** Use `useMutation` with `onMutate` cache snapshots and `onError` rollbacks; trigger Server Actions calling `updateTag(cache.tag)`.

### 6. i18n, SEO & English TSDoc

- **i18n:** Extract strings into root dictionaries (`messages/[locale].json`). Wrap internal routes with `localizePath(...)`. Use native `Intl` for currencies/dates.
- **SEO & JSON-LD:** Inject typed JSON-LD using `schema-dts` in `@graph` array format with interlinked `@id` references.
- **TSDoc:** Document all exported functions, components, props, generics, and return types in **strict English TSDoc** (`@param`, `@defaultValue`, `@returns`).

---

## Existing Component Detection & Companion Gap Analysis
## Step-by-Step Orchestrator Workflow

Before generating files, always audit whether the component already exists:

1. **Mandatory Scan:** Check `new_component_dir`, `component_library`, `components/ui/`, and root `components/`.
2. **If Component Exists -> ENTER COMPANION BACKFILL MODE:**
   - **Preserve Code:** DO NOT delete, re-create, or overwrite `[ComponentName].tsx`.
   - **Audit Missing Companion Files:** Check for missing `[ComponentName]Skeleton.tsx`, `[ComponentName].test.tsx`, `[ComponentName].stories.tsx`, `[ComponentName].edge.test.tsx`, or TSDoc.
   - **Backfill:** Generate only the missing companion artifacts matching the existing component contract.
3. **If Component is Missing:** Execute standard workflow from scratch (Steps 2–8).

---

## Step-by-Step Implementation Workflow

- [ ] **Step 0: Load Project Context & Design Specifications**
  - Read `docs/project.json` using `view_file` to resolve paths, package manager, and libraries.
  - Read `docs/project.json` using `view_file` to resolve base paths (`new_component_dir`), package manager, and libraries.
  - Read `docs/design/03-ui-design-tokens.md` and `docs/design/02-sitemap-and-routes.md`.
  - Verify routes from `lib/routes.ts` and author metadata from `lib/site-config.ts`.
  - Verify routes from `lib/routes.ts` (`ROUTES`) and author metadata from `lib/site-config.ts` (`SITE_CONFIG`).

- [ ] **Step 1: Check Component Existence & Audit Gap**
  - Search target directories. If component exists, audit missing companion files and set mode to `companion_backfill`; otherwise, set mode to `scratch`.
- [ ] **Step 1: Check Component Existence & Gap Analysis**
  - Search target directories.
  - **Component Missing:** Proceed with full pipeline (Phases 1–3).
  - **Component Exists:** Do NOT overwrite `[ComponentName].tsx`. Audit missing companion files (`Skeleton.tsx`, `.test.tsx`, `.stories.tsx`, `.edge.test.tsx`) and execute only the corresponding phases.

- [ ] **Step 2: Requirement Alignment & Clarification**
  - If requirements, props, or behaviors are underspecified, interview the user (suggest `/grill-me`). Never guess missing requirements.
- [ ] **Step 2: Phase 1 — Component & Skeleton Development**
  - Apply [`nextjs-component-dev`](../nextjs-component-dev/SKILL.md).
  - Define TypeScript contract and TDD baseline unit tests (`[ComponentName].test.tsx`).
  - Implement component (`[ComponentName].tsx`) and skeleton (`[ComponentName]Skeleton.tsx`).
  - **Verify Phase 1:** Run `pwsh .agents/skills/nextjs-component-dev/scripts/verify-dev.ps1 -ComponentPath <target_dir>` (or `bash .../verify-dev.sh`).

- [ ] **Step 3: Pre-Flight JSON Plan & History Persistence**
  - Create `.agents/history/plan-[component-name].json` following schema in [`resources/plan-schema.json`](./resources/plan-schema.json).
  - Update subtask statuses from `"pending"` to `"completed"` as steps finish.
- [ ] **Step 3: Phase 2 — Storybook CSF3 Story Creation**
  - Apply [`nextjs-storybook-story`](../nextjs-storybook-story/SKILL.md).
  - Create co-located `[ComponentName].stories.tsx` with controls, `fn()` action spies, markdown docs, and 4 theme variants (`Light`, `Dark`, `SkeletonLight`, `SkeletonDark`).
  - **Verify Phase 2:** Run `pwsh .agents/skills/nextjs-storybook-story/scripts/verify-storybook.ps1 -ComponentPath <target_dir>` (or `bash .../verify-storybook.sh`).

- [ ] **Step 4: TypeScript Contract Definition & Baseline TDD**
  - Define prop types with English TSDoc annotations.
  - Write baseline unit tests in `[ComponentName].test.tsx` (or generate them against existing contract in backfill mode) before component code.
  - Cover default props, callbacks, Suspense skeletons, ARIA accessibility, and RTL orientation.
- [ ] **Step 4: Phase 3 — Adversarial QA & Edge-Case Injection**
  - Apply [`nextjs-adversarial-qa`](../nextjs-adversarial-qa/SKILL.md).
  - Spawn independent subagent (`Role: "Adversarial Code & QA Auditor"`) to generate `[ComponentName].edge.test.tsx`.
  - **Verify Phase 3:** Run `pnpm test -- <target_dir>/[ComponentName].edge.test.tsx`.
  - Auto-repair any failing edge cases in component code.

- [ ] **Step 5a: Component & Responsive Development**
  - Develop `[ComponentName].tsx` and `[ComponentName]Skeleton.tsx` using Tailwind responsive breakpoint classes (`sm:`, `md:`, `lg:`). Skip `.tsx` creation if in backfill mode.

- [ ] **Step 5b: Co-Located Storybook Story Creation (`[ComponentName].stories.tsx`)**
  - Create CSF3 story with `parameters.docs` markdown, `argTypes` controls, `fn()` action spies, and the 4 canonical high-contrast theme variants (`Light`, `Dark`, `SkeletonLight`, `SkeletonDark`).

- [ ] **Step 6: Adversarial Auditor Subagent & Edge-Case Injection**
  - Spawn independent subagent via `invoke_subagent` (`Role: "Adversarial Code & QA Auditor"`).
  - The subagent reviews RSC boundaries, tokens, and Storybook setup, then generates `[ComponentName].edge.test.tsx` covering boundary values, empty states, Persian/RTL text, and keyboard navigation.

- [ ] **Step 7: Verification Gate & Auto-Repair Loop (Mandatory Shell Execution)**
  - **Tier 1 (Constraints):** Run `npx tsx .agents/skills/nextjs-create-component/scripts/verify-component-files.ts <target_dir>` via `run_command`.
  - **Tier 2 (Tests):** Run unit and adversarial test suites (`pnpm test`) via `run_command`.
  - **Tier 3 (Storybook Smoke & Build):** Run `pnpm run storybook:smoke` (or `storybook dev --smoke-test`) and `pnpm run build-storybook` via `run_command`.
  - **Auto-Repair:** If any test fails, fix component or story code (adversarial tests are immutable). Re-run until all tiers pass with 0 errors.

- [ ] **Step 8: Final Handoff & Plan Completion**
  - Update `.agents/history/plan-[component-name].json` statuses to `"completed"`.
  - Present summary: file paths, Storybook preview command (`pnpm storybook`), rendering strategy, and props/controls overview.
- [ ] **Step 5: Completion & Handoff**
  - Present summary:
    * Component & companion files created/backfilled
    * Storybook preview command (`pnpm storybook`)
    * Test verification confirmation
