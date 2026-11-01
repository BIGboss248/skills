# Next.js Component Architecture Standards

Canonical rules enforced by `nextjs-component-create` and delegated to `nextjs-component-dev`, `nextjs-storybook-story`, and `nextjs-adversarial-qa`.

---

## 1. Planning Context & Single Source of Truth

Before creating or modifying components, read the planning artifacts created by `nextjs-plan`:

- **`docs/project.json`** — `package_manager`, `new_component_dir`, `style_file_dir`, `component_library`, `animation_library`, `dictionaries_dir`, `supported_languages`. Never guess paths.
- **`lib/routes.ts`** — all internal links, redirects, and action targets use `ROUTES` from `@/lib/routes`.
- **`lib/site-config.ts`** — author bio, contacts, socials, and base metadata use `SITE_CONFIG` from `@/lib/site-config`.
- **`docs/design/`** — `02-sitemap-and-routes.md` (SSG/ISR/SSR matrix) and `03-ui-design-tokens.md` (OKLCH palette, fonts, radii).
- **`docs/plan.md` / `docs/plan/05-pages-and-components.md`** — active milestones and page checklists.

---

## 2. RSC Placement, Boundaries & Folder Hierarchy

1. **Server Components by default.** Keep components server-rendered; push `"use client"` down to interactive leaves.
2. **RSC composition.** Pass Server Components as `children` or props into Client wrappers. Never import an RSC inside a `"use client"` file.
3. **Dedicated folder per component** under `<new_component_dir>/<page_or_global>/<ComponentName>/`:

   ```text
   <new_component_dir>/<page_or_global>/<ComponentName>/
   ├── [ComponentName].tsx               # Primary component
   ├── [ComponentName]Skeleton.tsx       # Suspense fallback matching geometry
   ├── [ComponentName].stories.tsx       # Storybook (only when in scope)
   ├── [ComponentName].test.tsx          # QA baseline suite
   ├── [ComponentName].edge.test.tsx     # QA adversarial suite (immutable)
   ├── test-plan.md                      # QA coverage matrix
   ├── [ComponentName].types.ts          # Extracted interfaces (if complex)
   └── index.ts                          # Barrel export

   tests/e2e/components/<page>/[ComponentName].spec.ts   # QA Playwright suite
   ```

4. **Category folders.** `global/` for shared chrome (header, footer, drawers); `<page-name>/` for page-scoped sections.
5. **Responsive in-component.** Use Tailwind breakpoints (`sm:`, `md:`, `lg:`) rather than separate mobile components.

---

## 3. Styling, Links & Logical Properties

- **Theme tokens only.** Use semantic variables from `app/globals.css` (`bg-background`, `text-foreground`, `border-border`, `text-muted-foreground`). Hardcoded hex or palette scales are forbidden.
- **Class merging.** Always use `cn(...)` (`clsx` + `tailwind-merge`).
- **BiDi.** Use logical properties (`ms-`, `me-`, `ps-`, `pe-`, `start`, `end`). Physical directions (`ml-`, `mr-`, `pl-`, `pr-`, `left`, `right`) are forbidden.
- **Progress-aware links.** `@vercel/react-transition-progress` `<Link>` for primary navigation/CTAs; `next/link` for static utility links; raw `<a>` is forbidden.
- **Images.** `next/image` with explicit dimensions or `fill`, responsive `sizes`, and `priority` for above-the-fold LCP assets.

---

## 4. Storybook CSF3 Standards (`[ComponentName].stories.tsx`)

- **Main composite component only.** Never create stories for micro leaf helpers.
- **Controls and spies.** Map props to `argTypes`; bind `fn()` from `storybook/test` to callback props so interactions log to Actions.
- **Docs.** Document overview, RSC/Client boundaries, interactions, and accessibility in `parameters.docs.description.component`.
- **Exactly four variants** in semantic token containers with scoped `.light` / `.dark` classes:
  1. `Light` — `themeOverride: "light"`, `backgrounds.default: "light"`, label `"Light Mode"`.
  2. `Dark` — `themeOverride: "dark"`, `backgrounds.default: "dark"`, label `"Dark Mode"`.
  3. `SkeletonLight` — renders `[ComponentName]Skeleton`, label `"Skeleton (Light)"`.
  4. `SkeletonDark` — renders `[ComponentName]Skeleton`, label `"Skeleton (Dark)"`.
- **Scope rule.** Create stories only when the `nextjs-storybook-story` skill is invoked or the user requests them.

---

## 5. TanStack Query & Server Prefetching

- **Unified cache contract.** Define `key`, `tag`, and `queryOptions` with explicit `staleTime` (e.g. `30_000`).
- **Server prefetch.** `new QueryClient()` per request; `void queryClient.prefetchQuery(...)` calling internal DB/service functions directly (no relative fetch on the server); dehydrate with `<HydrationBoundary>`.
- **Streamed components.** `useSuspenseQuery` inside `<Suspense fallback={<Skeleton />}>`.
- **Optimistic mutations.** `useMutation` with `onMutate` cache snapshots, `onError` rollback, and Server Actions calling `updateTag(cache.tag)`.

---

## 6. i18n, SEO & English TSDoc

- **i18n.** Extract every string to `messages/[locale].json`; wrap internal routes with `localizePath(...)`; use native `Intl` for currency/date.
- **SEO and JSON-LD.** Typed JSON-LD via `schema-dts` in `@graph` format with interlinked `@id` references; escape `<` as `\u003c`.
- **TSDoc.** Document every exported function, component, prop, generic, and return type in strict English TSDoc (`@param`, `@defaultValue`, `@returns`).

---

## 7. Existing Component Detection & Companion Backfill

Before generating files, always audit whether the component already exists:

1. **Mandatory scan.** Check `new_component_dir`, `component_library`, `components/ui/`, and root `components/`.
2. **If the component exists → Companion Backfill Mode:**
   - **Preserve code.** Never delete, recreate, or overwrite `[ComponentName].tsx`.
   - **Audit companions.** `Skeleton.tsx`, `.test.tsx`, `test-plan.md`, `.edge.test.tsx`, Playwright spec, TSDoc, and `.stories.tsx` (only when Storybook is in scope).
   - **Backfill only missing artifacts** that match the existing component contract.
3. **If the component is missing** → run the full pipeline from Phase 0.

---

## 8. Test Ownership

All test authoring and execution is delegated to [`nextjs-adversarial-qa`](../../nextjs-adversarial-qa/SKILL.md) in `baseline`, `page`, `adversarial`, or `repair` mode. This orchestrator never writes assertions directly and never weakens an edge test.

---

## 9. Page Track

A page target is a route directory, not a component directory:

| Artifact | Path | Owner |
| :--- | :--- | :--- |
| Page spec | `docs/design/pages/<route>/page-spec.md` | orchestrator |
| Page RSC | `app/[locale]/<route>/page.tsx` | `nextjs-dev` |
| Loading skeleton | `app/[locale]/<route>/loading.tsx` | `nextjs-dev` |
| Error boundary | `app/[locale]/<route>/error.tsx` | `nextjs-dev` |
| Metadata | `generateMetadata()` in `page.tsx` | `nextjs-dev` |
| JSON-LD | `<JsonLd>` with `schema-dts` | `nextjs-dev` |
| Page suite | `tests/e2e/pages/<route>.spec.ts` | `nextjs-test-author` |
| Adversarial page assertions | same file or `tests/e2e/components/**` | `nextjs-qa-auditor` |

Rules:

1. Resolve the route from `lib/routes.ts`; never hardcode a URL string.
2. `generateStaticParams()` is mandatory when the route sits under `[locale]` and more than one locale is configured.
3. Section components are separate targets: run the component track for each one, do not inline complex JSX in `page.tsx`.
4. `page-spec.md` §7 must cover metadata, JSON-LD, locale routing, loading/error boundaries, and empty states before the page suite is authored.
5. Backfill mode applies to pages too: preserve an existing `page.tsx` and fill only missing companions.

