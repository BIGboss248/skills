# Next.js Page Streaming & UI Boundaries Reference

This guide details streaming architecture, route-level fallback skeletons (`loading.tsx`), client error boundaries (`error.tsx`), and section orchestration.

---

## 1. Route-Level Loading Fallbacks (`loading.tsx`)

Next.js App Router automatically wraps `page.tsx` in a React `<Suspense>` boundary using `loading.tsx` as the fallback during streaming navigation.

### Guidelines

- Mirror the visual layout geometry and grid of the page to eliminate Cumulative Layout Shift (CLS).
- Compose individual section skeleton components created during component development (e.g. `<HeroSectionSkeleton />`, `<ProjectGridSkeleton />`).
- Use semantic token skeleton classes (`bg-muted/40 animate-pulse rounded-md`).

---

## 2. Route-Level Error Boundaries (`error.tsx`)

`error.tsx` isolates runtime exceptions to the current route segment without crashing the root layout.

### Rules

- Must be a Client Component (`"use client"`).
- Accepts `error: Error & { digest?: string }` and `reset: () => void`.
- Includes localized retry actions and error logging.

```typescript
"use client";

import { useEffect } from "react";
import { useTranslations } from "next-intl";

export default function ErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const t = useTranslations("Common.errors");

  useEffect(() => {
    // Log error to monitoring (e.g. Sentry / OpenTelemetry)
    console.error("[Route Error]", error);
  }, [error]);

  return (
    <div className="flex min-h-[50vh] flex-col items-center justify-center p-6 text-center">
      <h2 className="text-xl font-bold tracking-tight text-foreground">{t("title")}</h2>
      <p className="mt-2 text-sm text-muted-foreground">{t("description")}</p>
      <button
        onClick={() => reset()}
        className="mt-4 inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90"
      >
        {t("retry")}
      </button>
    </div>
  );
}
```

---

## 3. Section Composition & Instant Streaming Architecture

### A. Granular Suspense vs Monolithic `loading.tsx`
While `loading.tsx` defines the fallback for the entire page segment, wrapping the whole page in a single fallback replaces the entire screen on navigation.
- **Push Suspense Down**: Keep the page title, navigation breadcrumbs, and cached sub-components (`"use cache"`) outside the `<Suspense>` boundary so they render as part of the **Static Shell** and **App Shell** immediately.
- Wrap only the dynamic, uncached, or request-specific child components in granular `<Suspense fallback={<SectionSkeleton />}>`.

```tsx
// app/[locale]/products/[slug]/page.tsx
import { Suspense } from "react";
import { ProductHeader } from "@/components/products/ProductHeader";
import { ProductInfo } from "@/components/products/ProductInfo";
import { LiveInventory } from "@/components/products/LiveInventory";
import { InventorySkeleton } from "@/components/products/InventorySkeleton";

export default function ProductPage({ params }: PageProps<'/products/[slug]'>) {
  return (
    <div className="space-y-6">
      {/* 1. Static/Cached Header: renders immediately in shell */}
      <ProductHeader />

      {/* 2. Cached Product Details: renders immediately */}
      <ProductInfo params={params} />

      {/* 3. Live Inventory: dynamic streaming slot */}
      <Suspense fallback={<InventorySkeleton />}>
        <LiveInventory params={params} />
      </Suspense>
    </div>
  );
}
```

---

## 4. Segment Configuration (`export const instant`)

When a route segment relies heavily on dynamic, non-cacheable data or when structural instant refactoring is not warranted, you can opt out of instant validation feedback:

```tsx
// app/dashboard/layout.tsx or app/dashboard/page.tsx
export const instant = false;
```

- Setting `export const instant = false` suppresses dev overlay "blocking-route" insights for navigations entering this segment.
- Navigations between sibling segments nested below are still validated.
