# Next.js Instant Navigation, Prefetching & Granular Caching Architecture

This guide details the core principles, patterns, and validation workflows for building React components and routes that navigate instantly in Next.js App Router applications.

---

## 1. What "Instant Navigation" Means

A navigation is **instant** when the browser starts rendering the new page the moment the user clicks, with static, cached, and fallback skeleton content displaying immediately, while the server streams dynamic content into its fallbacks in the background.

```
User Click / Navigation
 │
 ├──▶ [Instant UI Phase (0ms)]
 │     ├── Static Layout Shell
 │     ├── Cached Sub-components ('use cache' / Warm Cache)
 │     ├── Granular <Suspense> Skeleton Fallbacks
 │     └── Prefetched Per-link URL Data (params & searchParams via prefetch={true})
 │
 └──▶ [Streaming Phase (Async)]
       └── Server resolves dynamic DB/API fetches -> Streams into Suspense slots
```

### Direct Page Loads vs. Client Navigations

| Dimension | Direct Visit (Hard Page Load) | Client Navigation (Soft Navigation via `<Link>`) |
| :--- | :--- | :--- |
| **Render Root** | Entire tree renders from the document root. | Only re-renders components **below the shared layout**. |
| **Shell Source** | Static shell served as initial HTML (e.g. from CDN). | App Shell prefetched in background by `<Link>`. |
| **`<Suspense>` Boundary Scope** | Caught by the nearest `<Suspense>` anywhere in the full tree (including root layout). | `<Suspense>` boundaries **above** the shared layout do NOT trigger; only boundaries below the shared layout take effect. |
| **`useSearchParams()`** | Suspends during SSR (search params not available at build time). | Resolves **synchronously** (router already has URL params from link). |

---

## 2. Prefetching Models: App Shell vs. Per-Link Prefetching

Under Next.js Partial Prefetching (`partialPrefetching: true` in `next.config.ts`), there are two distinct prefetch behaviors:

| Dimension | Default App Shell Prefetch (`<Link>`) | Per-Link Prefetch (`<Link prefetch={true}>`) |
| :--- | :--- | :--- |
| **Prefetch Scope** | **One per route** (reused across all links to that route). | **One per visible link**. |
| **Content Included** | Static layout shell + session-specific UI. | Static shell + session UI + **resolved per-link URL data** (`params`, `searchParams`). |
| **Server Cost** | **Bounded by route count** (lightweight). | **1 server invocation per prefetchable link** entering viewport. |
| **UX Outcome** | Navigation is instant with skeleton fallbacks for URL-dependent data. | Navigation is instant with URL-dependent cached data **already resolved (no skeleton fallback)**. |

```tsx
// 1. Default Link: Prefetches shared App Shell (low cost, ideal for dense grids)
<Link href={`/store/${product.slug}`}>
  {product.name}
</Link>

// 2. High-Intent Link: Resolves per-link URL data + cached search ahead of click
<Link href={`/search?q=${query}`} prefetch={true}>
  Search "{query}"
</Link>
```

---

## 3. The Three Levers for Instant Components

### Lever 1: Push Down Async I/O
Extract dynamic, uncached, or request-specific work (`await params`, `await searchParams`, `cookies()`, `headers()`, uncached `fetch()`) into leaf sub-components wrapped in `<Suspense>`.

- **Result**: The parent container and static siblings lift into the **Static Shell** and render immediately on navigation.

```tsx
// ✅ GOOD: Static parent lifts into shell; dynamic work pushed down
export default function ProductPage({ params }: PageProps<'/store/[slug]'>) {
  return (
    <div className="container mx-auto p-6">
      {/* 1. Cached Product Details: Renders immediately */}
      <Suspense fallback={<ProductInfoSkeleton />}>
        <ProductInfo params={params} />
      </Suspense>

      {/* 2. Live Inventory: Streams in without blocking the page */}
      <Suspense fallback={<InventorySkeleton />}>
        <LiveInventory params={params} />
      </Suspense>
    </div>
  );
}
```

### Lever 2: Granular Caching & Session Bridging Patterns
Pair `'use cache'` with `cacheLife` and `cacheTag` to cache data at function or component level so it is packaged directly into the App Shell.

#### Pattern A: Extract and Pass (Shared Across Sessions)
When data depends on a cookie (e.g. `teamId`, `tenantId`, `locale`) but is shared across multiple users with that same attribute, read `cookies()` **outside** the cached function and pass it as an argument.
```tsx
import { cookies } from "next/headers";

async function TeamDashboard() {
  const teamId = (await cookies()).get("team_id")?.value;
  const metrics = await getTeamMetrics(teamId);
  return <MetricsGrid data={metrics} />;
}

async function getTeamMetrics(teamId: string | undefined) {
  "use cache";
  // Cache key is deterministic based on teamId; traffic scales with team count, NOT session count!
  return db.metrics.forTeam(teamId);
}
```

#### Pattern B: `"use cache: private"` (Tied to a Single User Session)
When the lookup is strictly private to a single user session (or auth helpers check cookies deep inside):
```tsx
import { cookies } from "next/headers";
import { cacheLife } from "next/cache";

async function UserProfileBadge() {
  const profile = await getUserProfile();
  return <span>{profile.name}</span>;
}

async function getUserProfile() {
  "use cache: private";
  cacheLife({ stale: 300 }); // stale >= 5m allows App Shell to carry it ahead of click

  const sessionToken = (await cookies()).get("session")?.value;
  return db.users.findByToken(sessionToken);
}
```

#### Pattern C: Multi-Instance Remote Caching (`"use cache: remote"`)
In distributed serverless deployments where in-memory lambdas are ephemeral, use `"use cache: remote"` for persistent distributed caching across instances.

### Lever 3: Per-Link Prefetching (`<Link prefetch>`)
When a route reads `searchParams` or `params` that have a known cache lifetime, `prefetch={true}` tells Next.js to run a prerender for that specific URL ahead of the click. On click, the resolved data appears immediately with no fallback skeleton.

---

## 4. Dense Link Grids & Intent-Based Prefetching

> [!WARNING]
> **Avoid Blanket `prefetch={true}` on Dense Grids/Feeds:**
> Setting `prefetch={true}` on a grid of 50 product cards makes 50 simultaneous server prerender requests as cards scroll into the viewport.

### Recommended Strategy:
1. **Default Links in Grids**: Use standard `<Link>` (without `prefetch={true}`). This prefetches the single shared App Shell once for the entire route at minimal cost.
2. **Hover/Intent-Triggered Prefetch**: Use `<HoverPrefetchLink>` or call `router.prefetch(href)` on `onMouseEnter` / `onFocus` for high-intent links.
3. **Explicit `prefetch={true}`**: Reserve for high-traffic primary calls to action (e.g. Hero CTA, header search suggestions, checkout button).

---

## 5. Granular Loading States vs. Monolithic Skeletons

> [!WARNING]
> **Avoid Monolithic Full-Page Skeletons:**
> Wrapping an entire page in a single top-level `<Suspense>` or relying exclusively on a blank `loading.tsx` causes the entire page to disappear and flash a skeleton on every navigation.

### Best Practice:
1. Keep the page layout, navigation header, breadcrumbs, titles, and cached product information visible **immediately**.
2. Place `<Suspense>` boundaries strictly around the specific UI slots where live data is in flight (e.g. price, stock badge, recommended items).
3. Ensure skeleton fallbacks strictly mirror the geometry and layout classes of the resolved component to prevent Cumulative Layout Shift (CLS).

---

## 6. Development Diagnostics & Next DevTools Navigation Inspector

1. **Navigation Inspector ("Pause on Navigations")**:
   - Open Next.js DevTools (`next-devtools`).
   - Toggle **Pause on navigations**.
   - Navigate or refresh: the browser freezes the page at its initial loading state, allowing you to inspect the exact static shell (on direct visit) or prefetched App Shell (on client navigation).
   - Verify that meaningful cached content renders and fallbacks appear only where necessary.
   - Click **Resume** to stream in remaining content.

2. **Blocking-Route Validation Insights**:
   Next.js validates route instantness in development, surfacing three fix cards for blockers:
   - **Stream**: Extract async work into a child subcomponent wrapped in `<Suspense>`.
   - **Cache**: Add `'use cache'` and `cacheLife` to cache the data access.
   - **Block (`export const instant = false`)**: Intentionally opt out the segment from validation feedback when instant navigation is not applicable.

---

## 7. Automated E2E Regression Guards (`@next/playwright`)

Lock in instant navigation behavior using `@next/playwright`:

```ts
import { test, expect } from "@playwright/test";
import { instant } from "@next/playwright";

test.describe("Product Component Instant Navigation", () => {
  test("direct visit renders static shell instantly", async ({ page, baseURL }) => {
    await instant(
      page,
      async () => {
        await page.goto("/en/store/hats");
        await expect(page.locator("h1")).toContainText("Baseball Cap");
        await expect(page.getByTestId("stock-count")).toHaveCount(0);
      },
      { baseURL }
    );
    await expect(page.getByTestId("stock-count")).toBeVisible();
  });

  test("client navigation renders prefetched App Shell instantly", async ({ page }) => {
    await page.goto("/en/store/shoes");
    await instant(page, async () => {
      await page.click('a[href="/en/store/hats"]');
      await page.waitForURL((url) => url.pathname.includes("/store/hats"));
      await expect(page.locator("h1")).toContainText("Baseball Cap");
      await expect(page.getByTestId("stock-count")).toHaveCount(0);
    });
    await expect(page.getByTestId("stock-count")).toBeVisible();
  });
});
```
