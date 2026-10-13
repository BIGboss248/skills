# Next.js App Router Page Conventions & Lifecycle

Deep architectural reference for page routing, dynamic segment resolution, static param pre-rendering, and streaming lifecycles.

> [!NOTE]
> **Local Next.js Documentation Reference:**
> Consult `node_modules/next/dist/docs/01-app/01-getting-started/04-routing.md` and `node_modules/next/dist/docs/01-app/04-api-reference/01-file-conventions/page.md` for runtime version specifics.

---

## 1. Async Route Parameters & Search Params

In modern Next.js App Router, page props `params` and `searchParams` are asynchronous `Promise` objects. You MUST `await` them before reading properties.

```tsx
interface PageProps {
  params: Promise<{ locale: string; slug?: string }>;
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}

export default async function Page({ params, searchParams }: PageProps) {
  const { locale, slug } = await params;
  const { q } = await searchParams;
  // ...
}
```

### App Shell Prefetching vs Parameter Access

- **Top-Level `await searchParams`**: Accessing `searchParams` directly at the top level of `page.tsx` makes the entire page render request-dynamic, preventing Next.js from generating a prefetchable static shell unless wrapped in `<Suspense>`.
- **Pushing URL Parameters Down**:
  - Keep the root `page.tsx` layout and header synchronous or static.
  - Pass the unawaited `searchParams` / `params` promise down to leaf Server Components wrapped in `<Suspense>`.
  - This allows Next.js to prefetch the **App Shell** (layout + static chrome) via standard `<Link>`, while dynamic search query results stream in gracefully.
- **Per-Link URL Data Resolution (`<Link prefetch={true}>`)**:
  - When linking to a page with dynamic `params` or `searchParams`, `<Link prefetch={true}>` sends an unawaited prefetch request that evaluates dynamic params on the server, populating the Client Router Cache before the user clicks.

---

## 2. Static Pre-Rendering (`generateStaticParams`)

For localized or dynamic route segments (`app/[locale]/...` or `app/[locale]/products/[id]/...`), export `generateStaticParams()` to allow Next.js to pre-render static HTML at build time.

```tsx
import { routing } from "@/i18n/routing";

export function generateStaticParams() {
  return routing.locales.map((locale) => ({ locale }));
}
```

For nested dynamic resources (e.g. `[id]` or `[slug]`):

```tsx
export async function generateStaticParams() {
  const items = await fetchAllProductSlugs();
  return routing.locales.flatMap((locale) =>
    items.map((item) => ({
      locale,
      id: item.id,
    }))
  );
}
```

---

## 3. Streaming Lifecycles & Skeleton Boundaries (`loading.tsx`)

Next.js automatically creates a React `<Suspense>` boundary around `page.tsx` when a companion `loading.tsx` file is placed in the same folder.

- **Layout Stability:** Ensure `loading.tsx` mirrors the layout grid, container padding, and approximate element heights of `page.tsx` to achieve zero Cumulative Layout Shift (CLS < 0.1).
- **Granular vs Page-Level:** When a page has multiple independent slow sections, prefer wrapping individual sub-components in `<Suspense fallback={<SectionSkeleton />}>` rather than blocking the entire page shell behind `loading.tsx`.

---

## 4. Root Boundaries vs Page Boundaries

- **Global Safety Net:** The root layout segment (`app/[locale]/error.tsx`, `app/[locale]/not-found.tsx`, and `app/global-error.tsx`) catches unhandled exceptions for the entire website.
- **When to add Route-Level `error.tsx`:** Only create a nested route-level `error.tsx` when a specific sub-tree (such as a complex dashboard or interactive checkout wizard) needs to maintain surrounding page navigation while resetting its inner state.
