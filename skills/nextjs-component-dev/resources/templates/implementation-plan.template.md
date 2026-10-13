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

## 5. TDD Unit Test Plan

- **Default Rendering**: Verify component renders translated strings and semantic ARIA landmarks.
- **Interactive Callbacks**: Simulate user events on Client leaf components and assert callback invocations.
- **Suspense Skeleton**: Assert skeleton renders with matching layout geometry.
- **RTL / BiDi Orientation**: Assert logical classes and layout behavior in RTL direction.

---

## 6. Verification Gate

- Run targeted test suite:
  ```pwsh
  pwsh .agents/skills/nextjs-component-dev/scripts/verify-dev.ps1 -ComponentPath <target_component_dir>
  ```
