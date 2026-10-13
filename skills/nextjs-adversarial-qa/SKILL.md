---
name: nextjs-adversarial-qa
description: Workflow for spawning an independent subagent to conduct unbiased code reviews and inject adversarial edge-case tests ([ComponentName].edge.test.tsx).
metadata:
  author: BIGboss248
  version: "1.0"
---

# Next.js Adversarial QA & Edge-Case Injection (`nextjs-adversarial-qa`)

Specialized workflow for eliminating author confirmation bias by delegating code review and edge-case testing to an independent adversarial auditor subagent.

> [!TIP]
> **Reference Document:**
> - Common Pitfalls & Anti-Patterns: [`references/pitfalls.md`](./references/pitfalls.md)

---

## Architectural Rules & Standards

### 1. The Unbiased Auditor Principle
* The primary agent who wrote the component MUST NOT self-certify edge cases.
* You MUST spawn an independent subagent using `invoke_subagent` to audit the code and inject adversarial assertions.

### 2. Adversarial Edge-Case Scope (`[ComponentName].edge.test.tsx`)
The subagent MUST write `[ComponentName].edge.test.tsx` targeting scenarios developers frequently overlook:
* **Boundary Values:** Empty strings, null/undefined inputs, extremely long strings, Unicode & Persian RTL glyphs (`"سلام دنیا"`).
* **Prop Permutations:** Unhandled combinations of optional flags.
* **Network & Error States:** Async rejection, malformed payloads, slow streams.
* **Deep Accessibility & Motion:** Keyboard navigation (`Enter`, `Space`, `Tab`, `Escape`), `aria-expanded`, `aria-busy`, `aria-live`, focus trapping, and `prefers-reduced-motion`.
* **Stress & Lifecycle:** Rapid re-renders, unmount cleanup, timer teardown.

### 3. The Immutable Adversarial Tests Principle
* **Modifying or Softening Tests is Strictly FORBIDDEN:** The developer is NOT permitted to delete or weaken assertions in `[ComponentName].edge.test.tsx`.
* **Fix the Code, Not the Tests:** If an adversarial test fails, modify the component (`[ComponentName].tsx`) or story (`[ComponentName].stories.tsx`) to properly handle the edge case.

---

## Workflow Steps

- [ ] **Step 1: Spawn Adversarial Auditor Subagent**
  - Call `invoke_subagent` with:
    * `TypeName`: `"self"`
    * `Role`: `"Adversarial Code & QA Auditor"`
    * `Model`: `"inherit"`
    * `Prompt`: Instruct the auditor to inspect `[ComponentName].tsx`, `[ComponentName]Skeleton.tsx`, `[ComponentName].test.tsx`, and `[ComponentName].stories.tsx`, then generate `[ComponentName].edge.test.tsx` in the component directory.

- [ ] **Step 2: Auditor Injects `[ComponentName].edge.test.tsx`**
  - Auditor writes edge-case assertions and completes review.

- [ ] **Step 3: Execute Adversarial Tests & Auto-Repair**
  - Run the edge-case test suite:
    ```bash
    pnpm test -- <target_component_dir>/[ComponentName].edge.test.tsx
    ```
  - If any test fails, patch the component implementation until all edge tests pass with 0 errors.

