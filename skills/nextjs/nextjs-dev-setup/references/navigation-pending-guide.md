# Navigation Pending Feedback — `useLinkStatus` Contract

Canonical navigation-feedback contract for this skill. Read it before touching
links, navigation, or "loading bar" code.

**Sources:** Next.js `useLinkStatus` API reference (`v15.3.0`+), Next.js `Link`
prefetch reference, and `Computer/Front end/Next JS.md` (navigation, prefetch,
and `loading.tsx` sections).

---

## 1. The rule

Pending navigation feedback is **per link** and comes from Next's built-in
`useLinkStatus` hook (`next/link`).

- Do **not** install a global progress-bar library: `nprogress`,
  `next-nprogress-bar`, `@bprogress/*`, `react-transition-progress`, or
  `@vercel/react-transition-progress`.
- Do **not** add a progress provider to `providers.tsx`, `layout.tsx`, or the
  Storybook preview. There is nothing to provide — the hook reads the transition
  state of the nearest ancestor `<Link>`.
- Do **not** replace it with `useTransition`, router events, or polling.

A global top bar is a legitimate product decision only when the user explicitly
asks for it. Record it in the selection notes and keep `useLinkStatus`
indicators for inline feedback.

## 2. What the hook does

```tsx
"use client";
import { useLinkStatus } from "next/link";

function Hint() {
  const { pending } = useLinkStatus();
  return <span aria-hidden data-pending={pending} />;
}
```

| Item | Contract |
| :--- | :--- |
| Signature | `useLinkStatus(): { pending: boolean }` — no parameters |
| Version | Introduced in **15.3.0**; not supported in the Pages Router (always `{ pending: false }`) |
| Placement | **Must** be a descendant of the `<Link>` it reports on |
| Scope | Only the most recently clicked link reports `pending` |
| Prefetched routes | Pending state is **skipped** when the destination was prefetched — most useful with `prefetch={false}` or genuinely slow dynamic routes |
| Purpose | Subtle inline acknowledgement, not a route-level loading fallback |

## 3. Avoid layout shift and flashes

The docs are explicit: inline indicators easily cause CLS. Therefore:

1. Always render the indicator element; never conditionally mount it.
2. Give it a fixed size and reserve space (`inline-block size-1.5`).
3. Toggle **opacity** (plus `data-pending` for tests), not `display`.
4. Delay appearance ~100ms so sub-100ms navigations never flash.
5. Respect `prefers-reduced-motion` (`motion-reduce:transition-none`,
   `motion-reduce:animate-none`).
6. Keep it `aria-hidden`; it carries no copy. If a control must announce
   busy state, set `aria-busy` on that control deliberately — never rely on the
   dot itself.

The deployed primitive is
[`Link.tsx.template`](../resources/templates/Link.tsx.template): an outer span
that owns the delayed opacity transition and an inner span that pulses.

## 4. Relationship to `loading.tsx` and `<Suspense>`

Different layers, both wanted:

| Signal | Meaning | Where |
| :--- | :--- | :--- |
| `useLinkStatus` dot | "your click registered, navigation is in flight" | inline, inside the link |
| `loading.tsx` / `<Suspense>` | "this region's content is still streaming" | route segment / subtree |

A route with a `loading.js` boundary navigates instantly, which is why the
pending phase often never appears — prefer the boundary for slow routes and use
the inline hint as the cheap complement.

## 5. Prefetch interplay

- `prefetch={null}` / `"auto"` (default): App Shell / partial prefetch. Pending
  often never shows because navigation is instant.
- `prefetch={true}`: full data prefetch for high-intent CTAs.
- `prefetch={false}`: no viewport or hover prefetch — the case where inline
  feedback matters most, and what to use when demonstrating the indicator.

## 6. Testing

The indicator exposes `data-pending`. A Playwright assertion can observe the
transition state without racing the DOM:

```ts
await page.route("**/slow-route*", async (route) => {
  await new Promise((r) => setTimeout(r, 800));
  await route.continue();
});
await page.click('a[href="/slow-route"]');
await expect(page.locator('[data-pending="true"]')).toHaveCount(1);
```

Jest: assert the primitive renders a hidden-by-default indicator and that
`showPendingIndicator={false}` omits it. `useLinkStatus` requires the Next
runtime, so mock `next/link` in unit tests rather than simulating navigation.

## 7. Storybook and tests

`useLinkStatus` outside a `<Link>` is not meaningful, so:

- Stories that render the composite `Link` work as-is.
- Rendering `LinkStatusIndicator` standalone only makes sense for a visual spec;
  wrap it in a `<Link>` if the pending state matters.
- No provider is required in the preview — see
  [storybook-guide.md](./storybook-guide.md).

## 8. Migration checklist

- [ ] No progress-bar package in `package.json`.
- [ ] No progress provider in `providers.tsx`, `layout.tsx`, or `.storybook/`.
- [ ] `app/components/Link.tsx` (or the component root) imports
      `useLinkStatus` from `next/link`.
- [ ] Every internal `href` goes through the composite link (or
      `@/i18n/navigation` when N4 is enabled).
- [ ] Indicator is always rendered, fixed-size, opacity-toggled, delayed, and
      `motion-reduce` aware.
- [ ] `node_modules/next/dist/docs` was consulted for the current hook shape.
