# React Server Components (RSC), State Boundaries & Data Fetching

This reference details the architectural standards for RSC composition, Client Component leaf push-down, and TanStack Query caching in Next.js App Router applications.

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
