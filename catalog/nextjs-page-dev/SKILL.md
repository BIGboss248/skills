---
name: nextjs-page-dev
description: >-
  Build Next.js App Router pages and routes. Use when creating a page, route,
  layout, loading state, error boundary, metadata, or JSON-LD.
---

# Next.js Page Standards

How a correct page is built. This skill writes implementation only: it does not
plan, verify, or author tests.

## Inputs & fallbacks

1. `docs/project.json` — `supported_languages`, `dictionaries_dir`,
   `new_component_dir`.
2. Derive from the workspace: locales from `messages/*.json` or
   `i18n/routing.ts`; routes from the route registry and existing `app/` folders.
3. A page spec is optional. If none exists, derive route, intent, data sources,
   and edge states from the request and the surrounding routes, then state the
   assumptions you made.

## 1. Route conventions

- Localized pages live at `app/[locale]/<route-path>/page.tsx`; non-localized at
  `app/<route-path>/page.tsx`.
- Build URLs from the route registry (`lib/routes.ts` or equivalent), never from
  string literals scattered in JSX.
- Async route props: `params` and `searchParams` are promises in Next.js 16 —
  await them.
- Companion files sit beside `page.tsx`: `loading.tsx`, `error.tsx`,
  `not-found.tsx`.

## 2. Copy and translation

- No user-facing text in the page or its metadata. Every title, description, and
  label lives in `messages/[locale].json` for all supported locales.
- Server Components read with `await getTranslations('<namespace>')`.
- Provider and parity details: `nextjs-i18n-usage`.

## 3. Metadata

- Export `generateMetadata` and resolve `title`, `description`, and
  `alternates.canonical` from the active locale.
- Metadata strings come from dictionaries, not literals.
- Do not duplicate metadata already set by a parent layout unless the page must
  override it.
- Details: [metadata and SEO](./references/metadata-and-seo.md).

## 4. Structured data

- Emit JSON-LD with `schema-dts` types, wrapped in
  `<script type="application/ld+json">`.
- Escape `<` as `\u003c` in the serialized payload.
- One graph per page; reference shared entities by `@id`.
- Schemas and examples: [structured data guide](./references/seo-structured-data-guide.md).

## 5. Static pre-rendering

- When the route is under a dynamic segment and more than one locale exists,
  export `generateStaticParams()` returning every supported locale.
- When the route accepts slugs or ids, return the known values or declare the
  route dynamic; never return an empty array silently.
- Details: [static params and i18n](./references/static-params-and-i18n.md).

## 6. Streaming and boundaries

- Push `<Suspense>` down to dynamic slots so static content renders immediately.
- `loading.tsx` composes the section skeletons of the page, not a blank page or a
  full-page spinner.
- `error.tsx` is a client component and needs a reset path; `not-found.tsx`
  renders for unmatched segments.
- Opt out of instant navigation only with a deliberate `export const instant =
  false`, not by accident.
- Details: [streaming and boundaries](./references/streaming-and-boundaries.md).

## 7. Composition

- Section components belong in the page's surface folder and follow
  `nextjs-component-dev`.
- Do not inline complex sections inside `page.tsx`.
- Page lifecycle and file conventions: [page conventions](./references/page-conventions-and-lifecycle.md).

## Definition of Done

- [ ] `page.tsx` awaits `params`/`searchParams` and builds URLs from the registry.
- [ ] Metadata and JSON-LD resolve per locale, from dictionaries.
- [ ] `generateStaticParams()` exists when the route is localized and dynamic.
- [ ] `loading.tsx` and `error.tsx` exist when the page streams or can fail.
- [ ] No string literal reaches the rendered output.
- [ ] No test was authored here; `tdd` owns tests.
- [ ] Type checking and the targeted checks pass.

## Edge Cases & Pitfalls

- **Awaiting props late** — reading `params.locale` before awaiting breaks
  localized metadata.
- **Hardcoded canonical** — a canonical URL without the locale creates duplicate
  content.
- **JSON-LD escaping** — unescaped `<` breaks the script tag.
- **Full-page skeleton** — a single top-level fallback flashes the whole route.
- **Empty static params** — an empty array disables pre-rendering without saying
  so.
- **Client-only page** — a page with no `await` and no data still does not need
  `"use client"`.
- **Shell assumptions** — the page does not own the header, footer, or theme;
  those belong to the layout.

## References

- [Metadata and SEO](./references/metadata-and-seo.md)
- [Structured data guide](./references/seo-structured-data-guide.md)
- [Static params and i18n](./references/static-params-and-i18n.md)
- [Streaming and boundaries](./references/streaming-and-boundaries.md)
- [Page conventions and lifecycle](./references/page-conventions-and-lifecycle.md)
- [Templates](./resources/templates/)
