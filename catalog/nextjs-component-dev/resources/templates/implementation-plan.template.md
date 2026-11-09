# Implementation Plan: [ComponentName]

- **Page / Scope**: `[page segment / header / footer / sidebar / shared / ui]`
- **Component Path**: `[new_component_dir]/[surface]/[component_name].tsx` (flat file; `[surface]` = page segment, layout region, `shared`, or `ui`)
- **Owning Surface**: `[page segment / header / footer / sidebar / shared / ui]` — rendered by `[page or layout file]`
- **Surface Evidence**: `[the page/layout file that renders it, or "no renderer yet → page segment being built"]`
- **Component Classification**: `[RSC (Server Component) | Client Component (Interactive)]`
- **Design Spec Reference**: `docs/design/components/[page]/[component]/design-spec.md`
- **Next.js Docs Consulted**: `node_modules/next/dist/docs/01-app/...`

---

## 1. Target Directory & Planned Files

- [ ] `[new_component_dir]/[surface]/[component_name].tsx` (Primary Component)
- [ ] `[new_component_dir]/[surface]/[component_name]_skeleton.tsx` (Suspense Skeleton — **only when §1.2 verdict is `required`; delete this line for a static component**)

> Test files are **not** part of this plan. `tdd` owns `<component_name>.test-plan.md`, `<component_name>.test.tsx`, and `<component_name>.edge.test.tsx` and runs as a separate step.

> Flat files inside the surface folder. No per-component subfolder and no per-component `index.ts`; an optional area-level `[surface]/index.ts` barrel may re-export the surface.

### 1.1 Surface Decision (evidence required)

| Check | Result |
| :--- | :--- |
| Renderers found (files/imports) | `app/[locale]/<segment>/page.tsx`, `app/[locale]/layout.tsx`, or none yet |
| Renderer count | `[0 / 1 / 2+]` |
| Surface chosen by §1.1 | `[<page-segment> / <layout-region> / shared / ui]` |
| Forbidden-folder check | `[no global/, no components/<component_name>/, no per-component folder]` |

### 1.2 Skeleton Verdict (§1.2)

| Check | Result |
| :--- | :--- |
| Can it suspend, lazy-load, or wait on I/O? | `[yes → await/fetch/DB, `useSuspenseQuery`, `next/dynamic`, `ssr: false`, `loading.tsx` \| no → synchronous static render]` |
| Trigger evidence | `[e.g. "awaits fetchProduct(id) in an async RSC" \| "pure presentational, props only, no await"]` |
| Verdict | `[required \| not required — static]` |

Only when the verdict is **required**:

- **Skeleton file**: `[new_component_dir]/[surface]/[component_name]_skeleton.tsx`
- **Wired in**: `[parent file]` via `[<Suspense fallback> | next/dynamic loading | loading.tsx]`
- **Geometry mirrored**: `[outer wrapper classes, padding, grid/flex, breakpoints, item count, text-line count]`

When the verdict is **not required — static**: state the evidence above and ship **no** `_skeleton.tsx` and no fallback boundary added only to host one.

---

## 2. TypeScript Props & Contracts

```tsx
/**
 * Props for the {@link [ComponentName]} component.
 */
export interface [ComponentName]Props {
  /**
   * [Description of prop]
   */
  title: string;
}
```

---

## 3. Translation Dictionary Strategy (`messages/[locale].json`)

- **Namespace**: `[NamespaceName]`
- **Keys to Populate**:
  - `title`: `"[English text]"` / `"[Persian / Target text]"`
  - `description`: `"[English text]"` / `"[Persian / Target text]"`
  - `cta`: `"[English text]"` / `"[Persian / Target text]"`

---

## 4. Theme Tokens & Styling

- **Semantic Variables**: `bg-background`, `text-foreground`, `border-border`, `text-muted-foreground`
- **Logical Classes**: `ps-`, `pe-`, `ms-`, `me-`, `text-start`, `text-end`
- **Animations / Transitions**: `transition-all duration-200 ease-out`

---

## 5. Testing Handoff (owned by `tdd`)

> Do not plan, author, or scaffold test cases in this document. Test authoring is owned exclusively by the `tdd` skill, which produces `<component_name>.test-plan.md`, `<component_name>.test.tsx`, and `<component_name>.edge.test.tsx` as a separate step. State that handoff here and continue with implementation.

---

## 6. Verification Gate

Creation gate (fast tier, run during development):

- Companion files and i18n:
  ```pwsh
  pwsh .agents/skills/nextjs-component-dev/scripts/verify-dev.ps1 -ComponentPath <new_component_dir>/<surface>/<component_name>.tsx
  ```
- Existing tests, if present, may be run read-only for feedback. Test authoring and the test suite gate belong to `tdd`.

Expensive tier (deferred to `git push` via `.husky/pre-push`; never run here):

- Playwright component spec, full Jest project, production build.
