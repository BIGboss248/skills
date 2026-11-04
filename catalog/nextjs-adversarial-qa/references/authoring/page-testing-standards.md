# Page Testing Standards (`app/[locale]/<route>/page.tsx`)

Page suites verify everything a component suite cannot: routing, metadata, structured data, and route-level boundaries. One spec per route at `tests/e2e/pages/<route>.spec.ts`.

---

## 1. Mandatory Assertions

| # | Area | Assertion |
| :- | :--- | :--- |
| PAGE-1 | Render | `page.tsx` returns `200` and renders the primary `<h1>` from the dictionary |
| PAGE-2 | Metadata | `<title>` matches `generateMetadata` output; `meta[name="description"]` present |
| PAGE-3 | Canonical | `link[rel="canonical"]` resolves to the absolute localized URL |
| PAGE-4 | Alternates | `link[rel="alternate"][hreflang]` covers every `supported_languages` entry |
| PAGE-5 | Open Graph | `og:title`, `og:description`, `og:url`, `og:type` present |
| PAGE-6 | JSON-LD | Exactly one `script[type="application/ld+json"]` per expected graph; parses as JSON; `@context` and `@type` correct |
| PAGE-7 | Escaping | No raw `<` inside the JSON-LD script body (must be `\u003c`) |
| PAGE-8 | Locales | Every locale from `generateStaticParams()` renders without 404 |
| PAGE-9 | Loading | `loading.tsx` fallback appears on throttled navigation and is replaced by content |
| PAGE-10 | Error | `error.tsx` renders on a forced failure and exposes a working reset/retry control |
| PAGE-11 | 404 | Unknown nested route returns the localized not-found page |
| PAGE-12 | Instant | Static shell renders inside `instant()` before streamed sections resolve |
| PAGE-13 | RTL | `dir="rtl"` route renders mirrored layout with no horizontal scroll |
| PAGE-14 | Links | Internal links resolve to localized paths from `ROUTES`/`localizePath` |

---

## 2. Metadata Test Pattern

```ts
test("emits localized metadata", async ({ page }) => {
  await page.goto("/en/about");
  await expect(page).toHaveTitle(/About/);
  const description = page.locator('meta[name="description"]');
  await expect(description).toHaveAttribute("content", /.+/);
  const canonical = page.locator('link[rel="canonical"]');
  await expect(canonical).toHaveAttribute("href", /\/en\/about$/);
});
```

---

## 3. JSON-LD Test Pattern

```ts
const jsonLd = await page
  .locator('script[type="application/ld+json"]')
  .first()
  .textContent();

expect(() => JSON.parse(jsonLd!)).not.toThrow();
const graph = JSON.parse(jsonLd!);
expect(graph["@context"]).toBe("https://schema.org");
expect(Array.isArray(graph["@graph"])).toBe(true);
```

- Assert `@id` cross-references resolve inside the graph.
- Assert no `<` characters remain unescaped.

---

## 4. Boundary Tests

| Boundary | Trigger | Expected |
| :--- | :--- | :--- |
| Missing dynamic param | `/en/projects/` (empty slug) | 404 or redirect, never crash |
| Invalid locale | `/xx/about` | Redirect to default locale or 404 |
| Empty search params | `/en/search` | Empty state, no crash |
| Malformed search params | `/en/search?page=abc` | Validation message or default page |
| Forced server error | `page.route` abort on RSC payload | `error.tsx` with reset control |
| Slow stream | Delayed route fulfillment | Skeleton geometry preserved, no CLS |

---

## 5. Rules

1. **No component duplication** — page specs assert page-level contracts, not prop permutations.
2. **Every locale** — iterate `supported_languages` from `docs/project.json`.
3. **No hardcoded copy** — read expected strings from the dictionary or assert against the same source.
4. **No absolute hosts** — use `baseURL`.
5. **One spec per route** — split with `test.describe` blocks per concern.
