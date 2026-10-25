# React Server Components (RSC), State Boundaries & Data Fetching

This reference details the architectural standards for RSC composition, Client Component leaf push-down, TanStack Query caching, and lazy loading in Next.js App Router applications.

---

## 1. RSC Boundaries & Leaf Client Push-Down

1. **Server Components by Default**: Keep components server-rendered (`async function`) by default. This minimizes client bundle size, enables zero-waterfall server data loading, and optimizes SEO.
2. **Push `"use client"` Down**: Isolate interactive event handlers (buttons, modal toggles, form inputs, local state) into tiny leaf Client Components.
3. **RSC Composition**:
   - Pass Server Components as `children` or props into Client Component wrappers.
   - **NEVER** import a Server Component directly inside a `"use client"` file.
   - Example:
     ```tsx
     // ClientWrapper.tsx ("use client")
     export function ClientWrapper({ children }: { children: React.ReactNode }) {
       return <div className="interactive-shell">{children}</div>;
     }

     // ServerParent.tsx (RSC)
     import { ClientWrapper } from "./ClientWrapper";
     import { ServerChild } from "./ServerChild";

     export async function ServerParent() {
       return (
         <ClientWrapper>
           <ServerChild />
         </ClientWrapper>
       );
     }
     ```

---

## 2. TanStack Query & Server Prefetching

When components require client-side caching, polling, or optimistic mutations:

1. **Unified Cache Contract**: Define query key, tag, and query options with explicit `staleTime` (e.g. `30_000` ms) in a dedicated cache file (`product-cache.ts`).
2. **Server Prefetch**:
   - Instantiate `QueryClient` per server request.
   - Trigger unawaited prefetch (`void queryClient.prefetchQuery(...)`) calling internal DB functions or services directly (zero relative fetch calls on server).
   - Wrap streamed content in `<HydrationBoundary state={dehydrate(queryClient)}>`.
3. **Streamed Components**:
   - Use `useSuspenseQuery` inside `<Suspense fallback={<[ComponentName]Skeleton />}>`.
4. **Optimistic Mutations**:
   - Use `useMutation` with `onMutate` cache snapshots and `onError` rollbacks.
   - Call Server Actions with `updateTag(cache.tag)` for atomic cache invalidation.

---

## 3. Suspense Skeletons & Layout Stability (Zero CLS)

- Every composite component must have a matching `[ComponentName]Skeleton.tsx`.
- The skeleton must mirror the exact outer geometry, container padding, grid rows/columns, and responsive breakpoints (`sm:`, `md:`, `lg:`) of the real component to ensure **Cumulative Layout Shift (CLS) = 0**.
- Use semantic token skeleton classes: `animate-pulse bg-muted rounded-md`.

---

## 4. Lazy Loading Client Components & Libraries (`next/dynamic`)

Next.js provides native lazy loading via `next/dynamic` (a composite of `React.lazy()` and `<Suspense>`) and ES dynamic imports (`import()`) to code-split client bundles and defer execution until needed.

### Heuristics: When to Lazy Load
1. **Heavy Interactive Modals / Drawers / Dialogs:** Components only rendered upon user action (e.g. settings dialogs, checkout drawers, image croppers, media lightboxes).
2. **Third-Party Interactive Widgets:** Complex visualization libraries (e.g. Recharts, Chart.js, Mapbox, Leaflet, Monaco / CodeMirror, Canvas/Three.js).
3. **Browser-Only APIs with `ssr: false`:** Components relying on `window`, `document`, `navigator`, `localStorage`, or Web APIs that cannot run on the server.
4. **Action-Driven External Libraries:** Heavy utility modules (e.g. `fuse.js`, `xlsx`, `jspdf`, `canvas-confetti`, `zod` schema resolvers for rare flows) invoked only within event handlers.

### Pattern A: Lazy Client Component with Matching Skeleton
Never lazy load without providing the geometry-matched `[ComponentName]Skeleton` to prevent Cumulative Layout Shift (CLS):

```tsx
import dynamic from "next/dynamic";
import { ChartWidgetSkeleton } from "./ChartWidgetSkeleton";

export const ChartWidget = dynamic(
  () => import("./ChartWidget").then((mod) => mod.ChartWidget),
  {
    loading: () => <ChartWidgetSkeleton />,
  }
);
```

### Pattern B: Skipping SSR for Browser-Only Components (`ssr: false`)
Instead of brittle `useEffect(mounted)` flags (which force a 2-render layout jump), disable server pre-rendering cleanly:

```tsx
import dynamic from "next/dynamic";
import { CanvasVisualizerSkeleton } from "./CanvasVisualizerSkeleton";

export const CanvasVisualizer = dynamic(
  () => import("./CanvasVisualizer").then((mod) => mod.CanvasVisualizer),
  {
    ssr: false,
    loading: () => <CanvasVisualizerSkeleton />,
  }
);
```

> [!NOTE]
> `ssr: false` is only supported on Client Components in Next.js App Router. It cannot be used directly on Server Components.

### Pattern C: On-Demand Library Loading in Event Handlers
Never import heavy single-purpose libraries at the top of a component file. Import them dynamically inside the handler:

```tsx
"use client";

import { useState } from "react";

export function SearchBox() {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState([]);

  const handleSearch = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    setQuery(val);

    if (val.length > 2) {
      // Defer loading Fuse.js until user actually searches
      const { default: Fuse } = await import("fuse.js");
      const fuse = new Fuse(dataset, { keys: ["title", "tags"] });
      setResults(fuse.search(val).map((res) => res.item));
    }
  };

  return <input type="search" value={query} onChange={handleSearch} />;
}
```

### Pattern D: Named vs. Default Exports
`next/dynamic` defaults to default exports. When using named exports (prescribed by workspace standards), chain `.then()` to resolve the module export:

```tsx
const DataGrid = dynamic(() => import("./DataGrid").then((mod) => mod.DataGrid), {
  loading: () => <DataGridSkeleton />,
});
```

### Testing Considerations
- **Jest Unit Tests (`[ComponentName].test.tsx`):**
  - When testing parent components that import dynamic components, either mock `next/dynamic` or wrap the test in `await act(async () => ...)` to ensure dynamic chunk resolution.
  - Test both the initial skeleton state and the resolved dynamic component state.
- **Playwright Verification (`[ComponentName].spec.ts`):**
  - Verify that dynamic chunk scripts (`.js`) are only requested over the network when the trigger condition (e.g. click, scroll into view) occurs.
  - Verify zero hydration console warnings when using `ssr: false`.
