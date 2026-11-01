---
name: nextjs-page-dev
description: >-
  Step-by-step workflow for designing and building Next.js App Router pages (RSC page.tsx, loading.tsx skeleton, error.tsx boundary, generateMetadata, JSON-LD schema, and generateStaticParams). MANDATORY SKILL: MUST ALWAYS be activated, read, and strictly followed every time the agent creates, scaffolds, or implements any new Next.js page, route, or view. Triggers on "/nextjs-page-dev", "create page", "new page", "develop page", "build route", "implement page", or any page creation task.
metadata:
  author: BIGboss248
  version: "1.2"
---

# Next.js Page & Route Development (`nextjs-page-dev`)

Specialized workflow for creating production-ready Next.js App Router pages with async route params, localized translation dictionaries, dynamic metadata, type-safe JSON-LD structured data (`schema-dts`), and static pre-rendering.

> [!CRITICAL]
> **MANDATORY PAGE CREATION INVARIANT:** Whenever you create any new Next.js App Router page or route (`page.tsx`), you **MUST** strictly follow every architectural standard and workflow step in this skill. Furthermore, if implementing a page requires creating any new section or child components, you **MUST** activate and follow [`.agents/skills/nextjs-component-dev/SKILL.md`](../nextjs-component-dev/SKILL.md) for each new component.

> [!TIP]
> **Modular Assets & Deep Guides:**
> - Streaming & UI Boundaries: [`references/streaming-and-boundaries.md`](./references/streaming-and-boundaries.md)
> - Page Conventions & Lifecycle: [`references/page-conventions-and-lifecycle.md`](./references/page-conventions-and-lifecycle.md)
> - SEO & Structured Data Guide: [`references/seo-structured-data-guide.md`](./references/seo-structured-data-guide.md)
> - Reusable Templates: [`resources/templates/`](./resources/templates/)
> - Page Specification Template: [`page-spec.template.md`](./resources/templates/page-spec.template.md)
> - Page Test Suite (delegated): [`../nextjs-adversarial-qa/SKILL.md`](../nextjs-adversarial-qa/SKILL.md) (`page` mode)
> - Verification Script: [`scripts/verify-page.ps1`](./scripts/verify-page.ps1) (Windows) / [`scripts/verify-page.sh`](./scripts/verify-page.sh) (Linux)

---

## Architectural Rules & Standards

### 1. Planning Context & Route Registry
- Read `docs/project.json` to resolve `supported_languages`, `dictionaries_dir` (default: `"messages"`), and `new_component_dir`.
- All navigation URLs MUST reference `ROUTES` from `@/lib/routes` or `@/i18n/navigation`.
- Target page path hierarchy: `app/[locale]/<route-path>/page.tsx` (or `app/<route-path>/page.tsx` if non-localized).

### 2. Zero Hardcoding & Dictionary Population
- **No Hardcoded Copy:** Page headings, titles, descriptions, and static labels must be added to `messages/[locale].json` across all `supported_languages` before writing JSX.
- **RSC Translations:** Read translations in Server Components using `await getTranslations('<namespace>')`.

### 3. SEO, Metadata & JSON-LD
- **Dynamic Metadata:** Export `generateMetadata({ params, searchParams }: Props)` providing dynamic `title`, `description`, and canonical URL (`alternates: { canonical: ... }`).
- **Structured Data:** Inject typed JSON-LD using `schema-dts` (`WithContext<T>`) wrapped in `<script type="application/ld+json">` with `<` characters escaped as `\u003c`.
- Consult [`references/seo-structured-data-guide.md`](./references/seo-structured-data-guide.md) for schemas.

### 4. Static Pre-Rendering (`generateStaticParams`)
- If the page is nested under a `[locale]` dynamic segment (or any dynamic segment) and `supported_languages` contains >1 locale, export `generateStaticParams()` returning `{ locale }` for all supported locales.

### 5. Instant Navigation & Granular Suspense Push-Down
- **Granular Loading States**: Push `<Suspense>` down to specific dynamic sub-components so static/cached sections (header, hero, cached product info) lift into the **Static Shell** and **App Shell** immediately.
- **Opting Out**: If a segment is inherently dynamic and instant feedback is not desired, configure `export const instant = false`.
- Consult [`references/streaming-and-boundaries.md`](./references/streaming-and-boundaries.md) for streaming patterns.

### 6. Child Component Delegation (`nextjs-component-dev`)
- Never write complex section components inline inside `page.tsx` or create ad-hoc component files without tests/skeletons. Whenever a page requires new section or UI components under `<new_component_dir>/<page-name>/`, activate and strictly execute [`.agents/skills/nextjs-component-dev/SKILL.md`](../nextjs-component-dev/SKILL.md) for each component.
- When orchestrated, every new section component routes through the component track (spec → `nextjs-test-author` baseline → `nextjs-dev` implementation → `nextjs-qa-auditor` edge suite).

### 7. Agent Boundaries
- Implementation is written by `nextjs-dev` when orchestrated. This skill never authors tests.
- Page tests belong to `nextjs-test-author`; adversarial page assertions belong to `nextjs-qa-auditor`.
- Only the orchestrator updates `docs/plan/05-pages-and-components.md`.

---

## Workflow Steps

- [ ] **Step 0: Page Specification & Implementation Plan**
  - Read `docs/project.json` and target route definition in `lib/routes.ts`.
  - Scaffold `docs/design/pages/<route>/page-spec.md` from [page-spec.template.md](./resources/templates/page-spec.template.md); every §7 row must be explicit before implementation.
  - Formulate page metadata, JSON-LD schema type, translation namespaces, and component layout.
  - Present the concise implementation plan and the §7 edge-case table for approval when creating major new pages.

- [ ] **Step 1: Populate Translation Dictionaries**
  - Add page title, meta description, and page body copy across all locale files (`messages/en.json`, `messages/fa.json`, etc.) under a dedicated page namespace.

- [ ] **Step 2: Create Companion Skeletons (`loading.tsx`)**
  - If the page streams content or fetches data, deploy `loading.tsx` from [loading.tsx.template](./resources/templates/loading.tsx.template).

- [ ] **Step 3: Implement Page Component (`page.tsx`)**
  - Deploy and customize [page.tsx.template](./resources/templates/page.tsx.template):
    1. Define async props interface (`params: Promise<{ locale: string, ... }>`, `searchParams`).
    2. Export `generateMetadata()` resolving dynamic titles and canonical alternates.
    3. Export `generateStaticParams()` for localized/dynamic routes.
    4. Implement page RSC composing section components from `<new_component_dir>/<page-name>/` (using `nextjs-component-dev` for any new components).
    5. Render `<JsonLd>` structured data component.

- [ ] **Step 4: Page Test Suite (Delegated to `nextjs-test-author`, `page` mode)**
  - Spawn the `nextjs-test-author` agent with the route definition, `page-spec.md`, and `docs/project.json`.
  - It produces `tests/e2e/pages/<route>.spec.ts` covering metadata, canonical/hreflang, JSON-LD, locale coverage, loading/error boundaries, instant shell, RTL, and route boundaries.
  - Do not author page tests here; consult [`../nextjs-adversarial-qa/SKILL.md`](../nextjs-adversarial-qa/SKILL.md).
  - Gate: page suite green before Step 5.

- [ ] **Step 5: Verification & Sanity Check**
  - Run the page verification script:
    - **Windows (PowerShell):**
      ```pwsh
      pwsh .agents/skills/nextjs-page-dev/scripts/verify-page.ps1 -RoutePath <route_dir>
      ```
    - **Linux / macOS (Bash):**
      ```bash
      bash .agents/skills/nextjs-page-dev/scripts/verify-page.sh <route_dir>
      ```
  - Run the page test suite:
    - **Windows:** `pwsh .agents/skills/nextjs-adversarial-qa/scripts/verify-qa.ps1 -TargetPath <route_dir> -Mode page`
    - **Linux / macOS:** `bash .agents/skills/nextjs-adversarial-qa/scripts/verify-qa.sh <route_dir> page`
  - Ensure zero TypeScript, missing dictionary, metadata, or JSON-LD errors.

- [ ] **Step 6: Implementation Plan Checklist Synchronization**
  - When orchestrated, the orchestrator checks off the completed page infrastructure items (`page.tsx`, `loading.tsx`, `error.tsx`, `generateMetadata`, `JSON-LD Schema`, `generateStaticParams()`) in `docs/plan/05-pages-and-components.md`.
  - If all component sub-checklists and page infrastructure tasks for this page are completed, the orchestrator checks off the parent page item (`- [x]`).
  - When invoked directly without the orchestrator, perform this step yourself.
