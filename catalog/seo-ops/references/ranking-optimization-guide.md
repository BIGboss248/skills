# SEO Ranking & Code Remediation Guide

This guide maps common `seo` audit findings and search performance reports directly to Next.js App Router code remediations.

---

## 1. Quick Wins & Low-Hanging Fruit (`quick-wins`)

- **Discovery**: `seo reports run quick-wins --params '{"site":"sc-domain:example.com"}' --json`
- **Criteria**: Queries ranking between positions 4 and 10 with high impressions but below-average CTR.
- **Remediation**:
  1. Open `app/[locale]/.../page.tsx` or the target route's `generateMetadata()`.
  2. Rewrite `<title>` to frontload high-intent target terms.
  3. Update `description` with compelling copy and clear search intent call-to-action within 150–160 characters.
  4. Add or refine JSON-LD structured data (`Article`, `FAQPage`, `HowTo`) to qualify for rich snippets in SERPs.
- **Verification**: Run `seo audit-page --url <target-page-url>` to confirm updated metadata is rendered in SSR HTML.

---

## 2. Second-Page Striking Distance (`second-page`)

- **Discovery**: `seo reports run second-page --params '{"site":"sc-domain:example.com"}' --json`
- **Criteria**: Queries averaging positions 10 to 20 that are on the verge of first-page ranking.
- **Remediation**:
  1. Add contextual internal links from high-authority parent pages to the target page with descriptive anchor text.
  2. Deepen content sections to directly answer sub-queries identified in the report.
  3. Verify heading structure (`<h1>` strictly once per page, logical `<h2>`/`<h3>` hierarchy).

---

## 3. Technical Blockers Remediation Matrix

| Finding Category | Next.js App Router File | Required Remediation |
| :--- | :--- | :--- |
| **Missing / Duplicate Title** | `app/[locale]/.../page.tsx` | Export dynamic `generateMetadata({ params })` returning distinct `title` template. |
| **Canonical Mismatch** | `app/[locale]/layout.tsx` or `page.tsx` | Define `alternates.canonical` pointing to absolute production URL. |
| **Missing `hreflang` / i18n** | `app/[locale]/layout.tsx`, `middleware.ts` | Ensure `next-intl` generates `alternates.languages` for all supported locales (`en`, `fa`, etc.). |
| **Invalid JSON-LD** | `components/seo/JsonLd.tsx` | Embed `<script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }} />`. |
| **Orphaned / Unlinked Route** | `app/sitemap.ts` | Ensure all published dynamic routes are returned in `generateStaticParams()` and dynamic `sitemap()`. |
| **Broken Internal Links** | Component TSX files | Replace broken internal links with `<Link href="/...">` components. |

---

## 4. Programmatic SEO Optimization (`pseo-patterns` & `pseo-opportunities`)

- **Discovery**: `seo reports run pseo-patterns --params '{"site":"sc-domain:example.com"}' --json`
- **Criteria**: High-frequency query templates (e.g. "[service] in [city]" or "[tool] vs [alternative]").
- **Remediation**:
  1. Implement dynamic route templates with static pre-rendering via `generateStaticParams()`.
  2. Ensure dynamic pages inject unique data attributes, schema, and custom copy rather than shallow boilerplate templates.
  3. Verify internal hub-and-spoke linking between parent category pages and child programmatic instances.
