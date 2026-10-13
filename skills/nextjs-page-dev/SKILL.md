---
name: nextjs-page-dev
description: Step-by-step workflow for designing and building Next.js App Router pages (RSC page.tsx, loading skeleton, metadata, JSON-LD schema, and dynamic static params). Triggers on "/nextjs-page-dev", "create page", "new page", "develop page", "build route", or "implement page".
metadata:
  author: BIGboss248
  version: "1.0"
---

# Next.js Page & Route Development (`nextjs-page-dev`)

Specialized workflow for creating production-ready Next.js App Router pages with async route params, localized translation dictionaries, dynamic metadata, type-safe JSON-LD structured data (`schema-dts`), and static pre-rendering.

> [!TIP]
> **Modular Assets & Deep Guides:**
> - Streaming & UI Boundaries: [`references/streaming-and-boundaries.md`](./references/streaming-and-boundaries.md)
> - Page Conventions & Lifecycle: [`references/page-conventions-and-lifecycle.md`](./references/page-conventions-and-lifecycle.md)
> - SEO & Structured Data Guide: [`references/seo-structured-data-guide.md`](./references/seo-structured-data-guide.md)
> - Reusable Templates: [`resources/templates/`](./resources/templates/)
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

---

## Workflow Steps

- [ ] **Step 0: Implementation Plan Generation & Approval Gate**
  - Read `docs/project.json` and target route definition in `lib/routes.ts`.
  - Formulate page metadata, JSON-LD schema type, translation namespaces, and component layout.
  - Present concise implementation plan to the user if creating major new pages.

- [ ] **Step 1: Populate Translation Dictionaries**
  - Add page title, meta description, and page body copy across all locale files (`messages/en.json`, `messages/fa.json`, etc.) under a dedicated page namespace.

- [ ] **Step 2: Create Companion Skeletons (`loading.tsx`)**
  - If the page streams content or fetches data, deploy `loading.tsx` from [loading.tsx.template](./resources/templates/loading.tsx.template).

- [ ] **Step 3: Implement Page Component (`page.tsx`)**
  - Deploy and customize [page.tsx.template](./resources/templates/page.tsx.template):
    1. Define async props interface (`params: Promise<{ locale: string, ... }>`, `searchParams`).
    2. Export `generateMetadata()` resolving dynamic titles and canonical alternates.
    3. Export `generateStaticParams()` for localized/dynamic routes.
    4. Implement page RSC composing section components from `<new_component_dir>/<page-name>/`.
    5. Render `<JsonLd>` structured data component.

- [ ] **Step 4: Verification & Sanity Check**
  - Run the page verification script:
    - **Windows (PowerShell):**
      ```pwsh
      pwsh .agents/skills/nextjs-page-dev/scripts/verify-page.ps1 -RoutePath <route_dir>
      ```
    - **Linux / macOS (Bash):**
      ```bash
      bash .agents/skills/nextjs-page-dev/scripts/verify-page.sh <route_dir>
      ```
  - Ensure zero TypeScript or missing dictionary errors.

- [ ] **Step 5: Implementation Plan Checklist Synchronization**
  - Check off the completed page infrastructure items (`page.tsx`, `loading.tsx`, `error.tsx`, `generateMetadata`, `JSON-LD Schema`, `generateStaticParams()`) in `docs/plan/05-pages-and-components.md`.
  - If all component sub-checklists and page infrastructure tasks for this page are completed, check off the parent page item (`- [x]`).
