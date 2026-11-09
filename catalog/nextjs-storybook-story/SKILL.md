---
name: nextjs-storybook-story
description: >-
  Write co-located Storybook CSF3 stories. Use when creating or updating a
  .stories.tsx file, adding controls, docs, or theme variants.
---

# Storybook Story Standards

How a correct story is written. This skill writes stories only: it does not run
builds, and it does not write tests.

## 1. Scope

- Only the main component of a surface gets a story. Internal micro leaf clients
  (a toggle, a click handler) do not.
- One story file per component, colocated as
  `<surface>/<component_name>.stories.tsx`.

## 2. CSF3 structure

- `Meta<typeof Component>` and `StoryObj<typeof Component>`.
- `tags: ["autodocs"]`.
- Map props to controls (`text`, `select`, `boolean`, `number`) in `argTypes`.
- Provide realistic default values in `args`; no placeholder lorem ipsum.

## 3. Action spies

- Bind `fn()` from `storybook/test` to every callback prop (`onClick`,
  `onSubmit`, `onToggle`) in the default `args` so interactions land in the
  Actions panel.

## 4. Documentation

Write `parameters.docs.description.component` with:

- **Overview** — what the component is and why it exists.
- **Architecture** — server or client, hooks, caching.
- **Interactions** — handlers, state, animation.
- **Accessibility** — roles, labels, reduced-motion behavior.

Annotate individual stories with `parameters.docs.description.story`.

## 5. Four canonical variants

Export exactly four:

| Story | Theme | Contents |
| :--- | :--- | :--- |
| `Light` | `themeOverride: "light"`, light background | The component |
| `Dark` | `themeOverride: "dark"`, dark background | The component |
| `SkeletonLight` | light | `<ComponentSkeleton />` |
| `SkeletonDark` | dark | `<ComponentSkeleton />` |

Each variant renders inside a semantic container card using production tokens
(`bg-background`, `text-foreground`, `border-border`, `text-muted-foreground`)
with a scoped `.light` or `.dark` class.

If the component has no skeleton (static), omit the two skeleton stories and say
so in the docs block rather than shipping an invented skeleton.

## 6. Providers

- Components using localized navigation or translations need
  `NextIntlClientProvider` with real messages in the preview decorator.
- Components using TanStack Query need a `QueryClientProvider`.
- Details: `nextjs-i18n-usage`.

## Definition of Done

- [ ] The story file sits beside the component in its surface folder.
- [ ] Controls, `args`, and `fn()` spies are bound for every public prop.
- [ ] The docs block covers overview, architecture, interactions, a11y.
- [ ] Four variants exist, or two when the component is static, with the reason
  recorded.
- [ ] No hex color or non-token utility appears.
- [ ] No test was authored here; `tdd` owns tests.

## Edge Cases & Pitfalls

- **Hardcoded colors** — `#FAFAFA`, `border-zinc-200`, and friends are forbidden;
  use tokens.
- **Missing provider** — stories throw "No intl context found".
- **Story for a leaf** — a leaf client helper is exercised through its parent.
- **Invented skeleton** — a static component has no skeleton to show.
- **Fake data** — placeholder copy in `args` hides layout defects.
- **Build during authoring** — storybook builds run in CI or the pre-push hook,
  not during authoring.

## References

- [Reference stories](./examples/)
- [Verification script](./scripts/verify-storybook.ps1)
