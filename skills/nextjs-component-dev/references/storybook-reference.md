# Storybook Component Reference & Separation of Concerns

This reference defines Storybook standards, CSF3 story architecture, and the strict separation of concerns between standard component development and Storybook story generation.

---

## 1. Separation of Concerns & Workflow Boundaries

> [!IMPORTANT]
> **Storybook Story Separation Rule:**
> During standard component creation (`nextjs-component-dev`), **DO NOT** author `.stories.tsx` files or run Storybook builds. Standard component development focuses strictly on the component implementation, Suspense skeleton, translation dictionaries, Jest unit tests, and Playwright integration/instant specs.
>
> Storybook stories are created, managed, and verified exclusively via the dedicated [`nextjs-storybook-story`](file:///d:/Scripts/Obsidian/skills/nextjs-storybook-story/SKILL.md) skill.

---

## 2. Storybook Scope & CSF3 Standards

When invoked via `nextjs-storybook-story`:

### A. Main Component Scope Only
* Micro leaf client helpers (e.g. inner icon buttons, inline toggle hooks) do NOT get individual stories.
* Only the primary exported component (the feature section or composite UI block) receives a co-located `[ComponentName].stories.tsx`.

### B. CSF3 Structure & Interactive Controls
* Use Component Story Format 3 (CSF3) with `Meta<typeof ComponentName>` and `StoryObj<typeof ComponentName>`.
* Set `tags: ["autodocs", "ai-generated"]`.
* Map TypeScript props to interactive controls (`text`, `select`, `boolean`, `number`) in `meta.argTypes`.
* Bind `fn()` from `'storybook/test'` to all callback props (e.g., `onClick`, `onToggle`, `onSubmit`) for action logging.

---

## 3. Four Mandatory Canonical Story Variants

All Storybook stories must strictly export four canonical variants styled with semantic OKLCH theme tokens:

1. **`Light`**: Default component in light theme card (`.light bg-background text-foreground border-border`).
2. **`Dark`**: Default component in dark theme card (`.dark bg-background text-foreground border-border`).
3. **`SkeletonLight`**: Renders `<[ComponentName]Skeleton />` in light theme container.
4. **`SkeletonDark`**: Renders `<[ComponentName]Skeleton />` in dark theme container.

---

## 4. `NextIntlClientProvider` & Progress Link Wrapping

If the component renders localized copy or navigation links (`next-intl` or `@vercel/react-transition-progress`), wrap the story decorator with `NextIntlClientProvider` and `ProgressBarProvider` to prevent `No intl context found` runtime errors.
