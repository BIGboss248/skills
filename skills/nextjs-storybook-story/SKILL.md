---
name: nextjs-storybook-story
description: Workflow and engineering standards for crafting co-located Storybook CSF3 stories ([ComponentName].stories.tsx) with interactive controls, action spies, and 4 canonical theme variants.
metadata:
  author: BIGboss248
  version: "1.0"
---

# Next.js Storybook CSF3 Story Generation (`nextjs-storybook-story`)

Specialized workflow for generating and updating co-located Storybook stories (`[ComponentName].stories.tsx`) in Component Story Format 3 (CSF3).

> [!TIP]
> **Modular Assets:**
> - Reference story implementations: [`examples/`](./examples/)
> - Verification Scripts: [`scripts/verify-storybook.ps1`](./scripts/verify-storybook.ps1) (Windows) / [`scripts/verify-storybook.sh`](./scripts/verify-storybook.sh) (Linux)

---

## Architectural Rules & Standards

### 1. Main Component Scope Only (Micro Leaf Client Exclusion)
* Interactive client logic is pushed down to small leaf Client Components (e.g. toggle buttons, click listeners).
* **DO NOT** create stories for internal micro leaf client helpers.
* **ONLY the main component** (primary feature section or composite UI block) requires a Storybook story.

### 2. CSF3 Structure & Interactive Controls
* Use Component Story Format 3 (CSF3) with `Meta<typeof ComponentName>` and `StoryObj<typeof ComponentName>`.
* Include tags: `tags: ["autodocs", "ai-generated"]`.
* Map TypeScript props to interactive controls (`text`, `select`, `boolean`, `number`) in `meta.argTypes`.
* Provide realistic default prop values in `args`.

### 3. Action Spies (`fn()` from `'storybook/test'`)
* For all callback and mutation props (e.g. `onClick`, `onToggle`, `onSubmit`), bind `fn()` from `'storybook/test'` in default `args` so user interactions log cleanly to the Storybook Actions panel.

### 4. Structured Documentation (`parameters.docs`)
* Write comprehensive markdown in `meta.parameters.docs.description.component`:
  * **Overview & Purpose:** What the component is and why it exists.
  * **Architecture & Boundaries:** RSC vs leaf Client Component (`"use client"`), hooks, caching.
  * **Key Interactions:** Click handlers, state toggles, and animations.
  * **Accessibility & Motion:** ARIA roles/labels and `prefers-reduced-motion`.
* Annotate individual stories with `parameters.docs.description.story`.

### 5. Four Canonical Story Variants & Production Tokens (MANDATORY)
* **Zero Hardcoded Colors:** Under NO circumstances use arbitrary hex values (`#FAFAFA`, `#050505`) or non-token palette colors (`border-zinc-200`, `text-zinc-500`).
* **Semantic Production Tokens:** Exclusively use semantic theme tokens from `app/globals.css` (`bg-background`, `text-foreground`, `border-border`, `text-muted-foreground`).
* Export strictly four story variants wrapped in semantic container cards with scoped `.light` and `.dark` classes:
  1. **`Light`**: Configured with `{ themes: { themeOverride: "light" }, backgrounds: { default: "light" } }` in a `.light bg-background text-foreground border-border` card labeled `"Light Mode"`.
  2. **`Dark`**: Configured with `{ themes: { themeOverride: "dark" }, backgrounds: { default: "dark" } }` in a `.dark bg-background text-foreground border-border` card labeled `"Dark Mode"`.
  3. **`SkeletonLight`**: `render: () => <[ComponentName]Skeleton />` in a `.light bg-background text-foreground border-border` card labeled `"Skeleton (Light)"`.
  4. **`SkeletonDark`**: `render: () => <[ComponentName]Skeleton />` in a `.dark bg-background text-foreground border-border` card labeled `"Skeleton (Dark)"`.

---

## Workflow Steps

- [ ] **Step 1: Inspect Component Contract & Props**
  - Read `[ComponentName].tsx` and resolve all exported props, callback handlers, and visual states.

- [ ] **Step 2: Generate Co-Located Story (`[ComponentName].stories.tsx`)**
  - Place `[ComponentName].stories.tsx` directly alongside `[ComponentName].tsx`.
  - Implement CSF3 metadata, `argTypes`, `fn()` action spies, markdown docs, and the 4 canonical story variants.

- [ ] **Step 3: Verification & Smoke Test Execution**
  - Run verification script to check story presence and execute Storybook smoke test:
    * **Windows (PowerShell):**
      ```pwsh
      pwsh .agents/skills/nextjs-storybook-story/scripts/verify-storybook.ps1 -ComponentPath <target_component_dir>
      ```
    * **Linux / macOS (Bash):**
      ```bash
      bash .agents/skills/nextjs-storybook-story/scripts/verify-storybook.sh <target_component_dir>
      ```
  - Fix any syntax collisions or missing export errors.

