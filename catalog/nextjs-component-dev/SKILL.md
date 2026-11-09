---
name: nextjs-component-dev
description: >-
  Build Next.js App Router components to project standards. Use when creating a
  component, section, card, or widget, or fixing RSC, skeleton, styling, i18n, or
  caching problems.
---

# Next.js Component Standards

How a correct Next.js component is built. This skill writes implementation only:
it does not plan, verify, or author tests.

## Inputs & fallbacks

Resolve configuration in this order; never block on a missing file.

1. `docs/project.json` — `package_manager`, `new_component_dir`,
   `dictionaries_dir`, `supported_languages`.
2. Derive from the workspace: package manager from the lockfile, components
   directory from `tsconfig` path aliases and existing folders, dictionaries from
   `messages/` or the next-intl request config, locales from `messages/*.json`
   filenames or `i18n/routing.ts`.
3. Ask at most two questions if the surface or skeleton verdict is genuinely
   ambiguous.

## 1. Surface placement

A component's folder is decided by **who renders it**, never by its own name.

| Surface | Use when | Example |
| :--- | :--- | :--- |
| `<page-segment>/` | Exactly one route segment renders it | `home/hero.tsx` |
| `<layout-region>/` | A `layout.tsx` renders it on every route | `header/navbar.tsx` |
| `shared/` | Two or more surfaces import it | `shared/empty_state.tsx` |
| `ui/` | Design-system primitive, no route or business knowledge | `ui/button.tsx` |

- Find the renderers first. Zero renderers → the page segment being built.
- Target path: `<new_component_dir>/<surface>/<component_name>.tsx`.
- Flat files, `snake_case` filename, `PascalCase` export.
- Forbidden: a `global/` folder, `components/<name>/`, per-component `index.ts`.
- Promote to `shared/` the moment a second surface imports it.

## 2. Skeleton verdict

A skeleton is a streaming fallback, not a companion file. Record one verdict
before writing code.

| Verdict | Trigger |
| :--- | :--- |
| **Required** | Async RSC awaiting data, `await params`/`searchParams`, `cookies()`/`headers()`, `useSuspenseQuery`, lazy `next/dynamic` leaf, `ssr: false`, a route composing `loading.tsx` |
| **Not required** | Sync RSC with props or literal copy and no `await`; static layout chrome; `ui/` primitives; client leaves that paint immediately |

When required: create `<component_name>_skeleton.tsx` as a flat sibling, wire it
in the same change (`<Suspense fallback>`, `next/dynamic` `loading`, or
`loading.tsx`), and match the component's wrapper, padding, grid, breakpoints,
and item counts so CLS is zero.

When not required: create nothing. Do not add a `<Suspense>` boundary to justify
a file. Re-run this verdict whenever a component gains `await`, a data hook, a
lazy import, or a browser-API gate.

## 3. Server and client boundaries

- Server Components by default; push `"use client"` to small leaves.
- Never import a Server Component inside a `"use client"` file. Pass it as
  `children` or a prop instead.
- Heavy or below-the-fold client work goes through `next/dynamic` with a
  skeleton fallback; browser-only leaves add `{ ssr: false }`.
- Import heavy libraries inside the handler, not at module top level.

## 4. Styling and layout

- Semantic tokens only (`bg-background`, `text-foreground`, `border-border`,
  `text-muted-foreground`). Hardcoded hex and raw color scales are forbidden.
- Merge classes with `cn(...)`.
- Logical properties only: `ms-`, `me-`, `ps-`, `pe-`, `start`, `end`,
  `text-start`, `text-end`. Physical `ml-`, `mr-`, `pl-`, `pr-`, `left-`,
  `right-` are forbidden.
- Internal links come from the localized navigation module. Raw `next/link` is
  allowed only for hash anchors, external URLs, and the locale-less root
  `not-found.tsx`.
- Images use `next/image` with dimensions or `fill`, responsive `sizes`, and
  `priority` for above-the-fold LCP assets.

## 5. Copy and translation

- No user-facing string in JSX. Keys live in `messages/[locale].json` for every
  supported locale, populated in the same change.
- No in-file fallback dictionaries.
- Server Components use `getTranslations`; client leaves use `useTranslations`.
- Provider and hook details: `nextjs-i18n-usage`.

## 6. Caching, streaming, and prefetch

- Push request-specific reads (`params`, `searchParams`, `cookies()`,
  `headers()`, uncached calls) into leaf components under `<Suspense>` so static
  content lifts into the shell.
- Pair `'use cache'` with `cacheLife` and `cacheTag`; pass session attributes in
  as arguments rather than reading `cookies()` inside a cached function.
- Default `<Link>` prefetch for dense grids; `prefetch` on a per-link basis only
  for high-intent actions.
- Never wrap a whole page in one top-level `<Suspense>`; fallbacks belong in the
  dynamic slots.
- Details: [instant navigation](./references/instant-navigation-and-prefetching.md) ·
  [caching](./references/caching-and-revalidation.md).

## 7. Data fetching with TanStack Query

- One key/tag/`queryOptions` per resource with an explicit `staleTime`.
- Prefetch on the server through internal data functions, dehydrate with
  `<HydrationBoundary>`.
- Streamed reads use `useSuspenseQuery` inside `<Suspense>`.
- Mutations snapshot on `onMutate`, roll back on `onError`, invalidate by tag.
- Forms and Server Actions: [form guide](./references/form-server-actions.md).

## Definition of Done

- [ ] The file sits in the surface folder that actually renders it.
- [ ] The skeleton verdict is recorded, and the artifact matches it.
- [ ] Every string resolves from a dictionary in every supported locale.
- [ ] No hardcoded color, physical direction, or unmerged class string.
- [ ] No test was authored here; `tdd` owns tests.
- [ ] Type checking and the targeted checks pass.

## Edge Cases & Pitfalls

- **Folder named after the component** — placement follows the renderer, not the
  name.
- **Skeleton on a static component** — a fallback that cannot paint is dead
  layout that will drift.
- **Orphan skeleton** — a skeleton no boundary imports fails the job.
- **Geometry drift** — a generic `h-96 animate-pulse` block is not a skeleton.
- **Stale verdict** — adding `await` or a data hook invalidates "not required".
- **`useTranslations` in an async RSC** — use `getTranslations`.
- **Hydration crashes** — do not gate browser APIs behind a `mounted` flag; use
  `ssr: false` with a fallback.
- **Guessed APIs** — the installed package's docs under
  `node_modules/next/dist/docs` are the source of truth; search them before
  assuming an API shape.

## References

- [RSC and state boundaries](./references/rsc-and-state-boundaries.md)
- [Instant navigation and prefetching](./references/instant-navigation-and-prefetching.md)
- [Caching and revalidation](./references/caching-and-revalidation.md)
- [Forms and Server Actions](./references/form-server-actions.md)
- [Token verification matrix](./references/token-verification-matrix.md)
- [Dev server and DevTools](./references/next-devtools-debugging.md)
- [Next.js docs lookup](./references/nextjs-docs-lookup.md)
- [Templates](./resources/templates/)
