# Implementation Plan: [ComponentName]

- **Page / Scope**: `[page-name / global]`
- **Component Path**: `[new_component_dir]/[page_or_global]/[ComponentName]/`
- **Component Classification**: `[RSC (Server Component) | Client Component (Interactive)]`
- **Design Spec Reference**: `docs/design/components/[page]/[component]/design-spec.md`
- **Next.js Docs Consulted**: `node_modules/next/dist/docs/01-app/...`

---

## 1. Target Directory & Planned Files

- [ ] `[new_component_dir]/[page_or_global]/[ComponentName]/[ComponentName].tsx` (Primary Component)
- [ ] `[new_component_dir]/[page_or_global]/[ComponentName]/[ComponentName]Skeleton.tsx` (Suspense Skeleton)
- [ ] `[new_component_dir]/[page_or_global]/[ComponentName]/[ComponentName].test.tsx` (Baseline TDD Unit Tests)
- [ ] `[new_component_dir]/[page_or_global]/[ComponentName]/[ComponentName].edge.test.tsx` (Adversarial Edge-Case Tests)
- [ ] `[new_component_dir]/[page_or_global]/[ComponentName]/index.ts` (Barrel Export)

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

## 5. TDD Unit Test Plan & Edge Case Test Matrix

### 5.1 Baseline Unit Tests
- **Default Rendering**: Verify component renders translated strings and semantic ARIA landmarks.
- **Interactive Callbacks**: Simulate user events on Client leaf components and assert callback invocations (`@testing-library/user-event`).
- **Suspense Skeleton**: Assert skeleton renders with matching layout geometry.
- **RTL / BiDi Orientation**: Assert logical classes (`dir="rtl"`) and layout behavior in RTL direction.

### 5.2 TDD Edge Case Test Matrix
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

- Run targeted test suite:
  ```pwsh
  pwsh .agents/skills/nextjs-component-dev/scripts/verify-dev.ps1 -ComponentPath <target_component_dir>
  ```
- Run targeted unit & edge test execution:
  ```bash
  pnpm test -- <target_component_dir>/[ComponentName].test.tsx <target_component_dir>/[ComponentName].edge.test.tsx
  ```
