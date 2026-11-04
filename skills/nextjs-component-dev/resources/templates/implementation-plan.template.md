# Implementation Plan: [ComponentName]

- **Page / Scope**: `[page segment / header / footer / sidebar / shared / ui]`
- **Component Path**: `[new_component_dir]/[surface]/[component_name].tsx` (flat file; `[surface]` = page segment, layout region, `shared`, or `ui`)
- **Owning Surface**: `[page segment / header / footer / sidebar / shared / ui]` — rendered by `[page or layout file]`
- **Component Classification**: `[RSC (Server Component) | Client Component (Interactive)]`
- **Design Spec Reference**: `docs/design/components/[page]/[component]/design-spec.md`
- **Next.js Docs Consulted**: `node_modules/next/dist/docs/01-app/...`

---

## 1. Target Directory & Planned Files

- [ ] `[new_component_dir]/[surface]/[component_name].tsx` (Primary Component)
- [ ] `[new_component_dir]/[surface]/[component_name]_skeleton.tsx` (Suspense Skeleton)
- [ ] `[new_component_dir]/[surface]/[component_name].test.tsx` (Baseline TDD Unit Tests)
- [ ] `[new_component_dir]/[surface]/[component_name].edge.test.tsx` (Adversarial Edge-Case Tests)

> Flat files inside the surface folder. No per-component subfolder and no per-component `index.ts`; an optional area-level `[surface]/index.ts` barrel may re-export the surface.

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

## 5. Test Plan (owned by `nextjs-adversarial-qa`)

> Do not author test code in this plan. Invoke the QA skill in `baseline` mode; it produces `<component_name>.test-plan.md` with the coverage matrix and `<component_name>.test.tsx`, both as flat siblings in the surface folder. Mirror the test IDs below.

### 5.1 Baseline Coverage (QA baseline mode)
- **Default Rendering**: Translated strings and semantic ARIA landmarks.
- **Interactive Callbacks**: `@testing-library/user-event` assertions on Client leaves.
- **Suspense Skeleton**: Matching layout geometry.
- **RTL / BiDi Orientation**: `dir="rtl"` behavior for RTL locales.

### 5.2 TDD Edge Case Test Matrix (QA adversarial mode)
| # | Edge Case Scenario | Test Type | Input / State Condition | Expected Assertion / Behavior |
| :- | :----------------- | :-------- | :---------------------- | :---------------------------- |
| 1 | **Empty Collection / No Data** | Unit | `items = []` or `data = null` | Renders dedicated empty-state fallback without crashing |
| 2 | **Null / Undefined Prop Safety** | Unit | Optional props omitted | Uses default values, renders cleanly |
| 3 | **Extreme String Overflow** | Unit / Visual | 200+ char title / description | Applies `line-clamp`, wraps with `break-words`, title attr present |
| 4 | **Network / Async Error State** | Unit | Server Action rejects / API throws 500 | Renders error fallback card with retry trigger |
| 5 | **BiDi / RTL Text Expansion** | Visual / E2E | `locale = "fa"`, RTL direction | Flips start/end alignments, no container overflow |
| 6 | **Keyboard Focus & Trapping** | Unit (a11y) | `Tab`, `Enter`, `Escape` events | Cycles focus properly, visible focus rings, ARIA state updates |
| 7 | **Hydration Boundary Safety** | E2E | SSR render vs Client hydration | 0 console hydration warnings, dynamic values guarded |

---

## 6. Verification Gate

Fast tier (run during development):

- Companion files and i18n:
  ```pwsh
  pwsh .agents/skills/nextjs-component-dev/scripts/verify-dev.ps1 -ComponentPath <new_component_dir>/<surface>/<component_name>.tsx
  ```
- Targeted Jest (baseline + adversarial):
  ```pwsh
  pwsh .agents/skills/nextjs-adversarial-qa/scripts/verify-qa.ps1 -TargetPath <new_component_dir>/<surface>/<component_name>.tsx -Mode all
  ```

Expensive tier (deferred to `git push` via `.husky/pre-push`; never run here):

- Playwright component spec, full Jest project, production build.
