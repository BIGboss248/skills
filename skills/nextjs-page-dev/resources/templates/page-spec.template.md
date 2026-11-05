# Page Specification: `{{route}}`

> Scaffolded by the `nextjs-page-dev` skill. Consumed by `nextjs-test`
> (`page` mode and page boundaries) and `nextjs-dev`.
> Do not start implementation until §7 is complete.

---

## 1. Route & Locale Matrix

| Item | Value |
| :--- | :--- |
| Route path | `app/[locale]/{{route}}/page.tsx` |
| Public URL | `/{locale}/{{route}}` |
| Dynamic segments | `{{segments_or_none}}` |
| Locales | `{{locales}}` |
| `generateStaticParams()` | required / not required |
| Default locale redirect | handled by `proxy.ts` / `middleware.ts` |
| Route registry key | `ROUTES.{{routeKey}}` |

---

## 2. Purpose & Audience

- Primary intent:
- Primary audience:
- Primary action / CTA:
- Success looks like:

---

## 3. Data & Caching

| Source | Access path | Caching strategy | Revalidation |
| :--- | :--- | :--- | :--- |
| {{source}} | server function / API / static | `'use cache'` + `cacheLife` / uncached | `cacheTag` |

- Session or cookie dependence:
- Prefetch strategy:
- Failure mode when the source is down:

---

## 4. Layout & Streaming

- Above-the-fold static shell:
- Dynamic subtrees wrapped in `<Suspense>`:
- Skeleton geometry per subtree:
- `instant = false` segments (if any) and why:

---

## 5. Metadata & Structured Data

- `title` template:
- `description`:
- Canonical / `alternates`:
- Open Graph / Twitter fields:
- JSON-LD `@type` (`schema-dts` `WithContext<T>`):
- Escaping requirement: `<` as `\u003c`

---

## 6. Internationalization

- Dictionary namespace: `{{namespace}}`
- Required keys: `title`, `description`, `{{section}}.*`
- RTL considerations:
- Number/date/currency formatting:

---

## 7. Edge Cases & Boundary States

Every row maps to a test ID in `<component_name>.test-plan.md`. No row may be left unimplemented
without an explicit `N/A` reason.

| ID | Case | Expected behavior | Layer |
| :--- | :--- | :--- | :--- |
| PAGE-1 | 404 for an unknown locale prefix | Redirect or boundary, never a 500 | Playwright |
| PAGE-2 | 404 for an unknown child route | `not-found` boundary renders | Playwright |
| PAGE-3 | Data source returns empty | Empty state with dictionary copy | Playwright |
| PAGE-4 | Data source throws | `error.tsx` boundary with retry | Playwright |
| PAGE-5 | Slow data source | `loading.tsx` or Suspense skeleton, no CLS | Playwright |
| PAGE-6 | RTL locale | `dir="rtl"`, logical spacing intact | Playwright |
| PAGE-7 | Missing dictionary key | Build-time failure, not a blank string | Jest / build |
| PAGE-8 | Metadata per locale | Localized title/description/canonical | Playwright |
| PAGE-9 | JSON-LD validity | Parses, correct `@type`, escaped `<` | Playwright |
| PAGE-10 | Direct deep-link load | Renders without client navigation | Playwright |

Add page-specific rows below; keep IDs stable once tests reference them.

---

## 8. Acceptance Checklist

- [ ] `page.tsx` implements the route with async `params` / `searchParams`.
- [ ] `generateMetadata()` resolves localized title, description, canonical.
- [ ] `generateStaticParams()` covers every locale when localized.
- [ ] `loading.tsx` exists when the page streams or fetches.
- [ ] `error.tsx` exists for recoverable failures.
- [ ] JSON-LD injected with the declared schema type and escaping.
- [ ] Every string exists in `messages/[locale].json` for all locales.
- [ ] Section components are created through the component track.
- [ ] Page suite authored by `nextjs-test` as a separate step (not by this skill).
- [ ] Plan checklist updated by the orchestrator.
