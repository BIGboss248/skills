# Theming & Light/Dark Mode Guide

How to add a light/dark theme system without imposing a CSS architecture. This
guide is **strategy-agnostic and structure-agnostic**: it tells you what must be
true, never which file layout, selector names, or token set a project must adopt.

**Sources:** `Computer/Front end/Next JS.md` → `# Theme`; shadcn/ui dark-mode
(Next.js) and theming docs; `next-themes`.

---

## 1. The five steps

1. **Palette** — derive from the logo and industry, not from a random preset.
2. **Two palettes** — light and dark variants of the same semantic roles.
3. **Apply through one token layer** — components consume semantic tokens; only
   the token layer differs per theme.
4. **Allow switching** — an explicit user control.
5. **Persist the choice** — `localStorage` (handled by `next-themes`).

Skip a step only with a stated reason. The frequent failure mode is step 3:
components that hardcode colors, so dark mode "works" only on the shadcn
components and the rest of the app stays light.

## 2. Detect before you build

Never scaffold a parallel system next to a working one. Inspect first:

| What to detect | Where | Consequence |
| :--- | :--- | :--- |
| Token stylesheet | `style_file_dir` in `docs/project.json` | Append there; do not create a second token file |
| Existing dark selector | `.dark {}`, `[data-theme]`, `[data-mode]`, `@media (prefers-color-scheme: dark)` | Adopt the existing strategy |
| Tailwind version & dark config | `package.json`, `tailwind.config.*`, `@import "tailwindcss"` + `@custom-variant` | v3 uses `darkMode: "class"`; v4 uses `@custom-variant dark` |
| Component library | `component_library` | Reuse its primitives for the toggle |
| Token naming | existing declarations | Keep the names; add missing roles, never rename silently |
| Color space | existing values | Keep it (`oklch`, `hsl`, hex). Do not convert the whole palette unasked |
| `theme_color` | manifest (N3) | Should match the palette, not `#000000` |

## 3. Choose a switching strategy

`next-themes` supports several; pick one and use it everywhere.

| Strategy | `next-themes` config | Markup | When |
| :--- | :--- | :--- | :--- |
| Class (recommended) | `attribute="class"` | `<html class="dark">` | Default; works with shadcn and Tailwind `dark:` |
| Data attribute | `attribute="data-theme"` | `<html data-theme="dark">` | Design system already uses `[data-theme]` |
| Data mode | `attribute="data-mode"` | `<html data-mode="dark">` | Existing analytics/tests key off `data-mode` |
| Multi-attribute | `attribute={["class", "data-theme"]}` | both | Bridging two libraries |

Rules:

- The **stylesheet wins**. If the tokens already react to `[data-theme]`, set
  `attribute="data-theme"` even when N2 deployed `attribute="class"`.
- System-only (media-query only) theming cannot be overridden by the user —
  acceptable only for read-only docs, and it fails the "switch" requirement.
- Do not read `localStorage` or `matchMedia` manually in components; the provider
  owns that.

## 4. Provider contract

`next-themes` is a client component. It belongs in the app's existing provider
file, composed — never replacing what is already there:

```tsx
"use client";
import { ThemeProvider } from "next-themes";

<ThemeProvider
  attribute="class"            // must match the stylesheet's selector
  defaultTheme="system"        // "light" | "dark" | "system"
  enableSystem                 // follow prefers-color-scheme
  disableTransitionOnChange    // no flash/transition on toggle
  storageKey="theme"           // change only if the app already wrote a key
  // forcedTheme="light"       // print views, embeds, snapshots
>
  {children}
</ThemeProvider>
```

- Provider file: `app/providers.tsx` (or the project's own). The deployed
  [providers.tsx.template](../resources/templates/providers.tsx.template)
  already contains this wrapper.
- `disableTransitionOnChange` is optional; enable it unless the product wants an
  animated theme change (§9).
- `<html>` may need `suppressHydrationWarning` when the provider injects the
  attribute before hydration. That suppresses the attribute mismatch only.

## 5. Tokens

The token layer is the contract. The **names and roles** below are a checklist,
not a required file, order, or color system. A project may expose all, some, or
differently named equivalents (e.g. `--surface` instead of `--card`) — what
matters is that each role resolves to a light and a dark value.

| Role | Drives |
| :--- | :--- |
| `background` / `foreground` | page shell, default text |
| `card` / `card-foreground` | elevated surfaces, panels |
| `popover` / `popover-foreground` | overlays: menus, popovers, context menus |
| `primary` / `primary-foreground` | high-emphasis actions, brand surfaces |
| `secondary` / `secondary-foreground` | lower-emphasis filled actions |
| `muted` / `muted-foreground` | descriptions, placeholders, empty states |
| `accent` / `accent-foreground` | hover, focus, active, selected surfaces |
| `destructive` / `destructive-foreground` | errors, destructive actions |
| `border` | default borders and separators |
| `input` | form control borders/surfaces |
| `ring` | focus rings |
| `chart-1…5` | chart palette |
| `sidebar*` | sidebar surface, text, accents, borders, ring |
| `radius` | corner radius scale |

Guidelines:

- **Do not add tokens ad hoc.** Use the existing set; a new token is a design
  decision, not an implementation detail.
- Add a token only when a genuinely new role appears in both themes.
- Never duplicate a value in two token layers, and never let a component read
  raw palette classes (`bg-gray-100`) or arbitrary values (`bg-[#123456]`).
- Dark values are not "light values inverted": reduce chroma, lift elevated
  surfaces slightly above the background, and keep contrast ≥ 4.5:1 for text.
- New projects may use `oklch()`; existing projects keep their color space.

### Tailwind v3 / v4 dark selector snippets

```css
/* Tailwind v4 — class strategy */
@custom-variant dark (&:is(.dark *));

/* Tailwind v4 — data-attribute strategy */
@custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *));
```

```js
// Tailwind v3
export default { darkMode: "class" };
```

If the project uses plain CSS instead of Tailwind, a `:root` / `.dark` pair (or
`[data-theme="dark"]`) over the same variables is sufficient. Keep the file the
project already owns.

## 6. Applying styles automatically

Prefer tokens applied at the element level over per-instance overrides — a
`<section>` or `<Button>` rule that reads `--background` / `--primary` survives a
theme change and a palette change for free. Pseudo-elements (`::before`,
`::after`, `::selection`, `::placeholder`) also need token-based colors, or they
stay dark-on-dark.

## 7. No flash of the wrong theme

1. Trust `next-themes`' pre-hydration script; do not add a second inline script.
2. Keep the provider above everything that reads the theme.
3. Server-render the **system** default; never render a hardcoded `dark` class.
4. If the root layout sets the class, add `suppressHydrationWarning` to `<html>`.
5. When a component needs the resolved theme (icons, charts), guard on mount —
   `theme` is `undefined` during SSR and the first client render.
6. `disableTransitionOnChange` prevents the whole tree from animating colors on
   toggle (which looks like a glitch, not a transition).

## 8. The toggle

Requirements, regardless of markup:

- Three explicit options — light, dark, system — unless the product deliberately
  offers only a binary switch **and** the selection notes say so.
- A visible icon that reflects `resolvedTheme`, not `theme`, so "system" can show
  the effective result.
- Accessible name: `aria-label="Toggle theme"` or an `sr-only` label; keyboard
  operable; `aria-pressed` only for a true binary toggle.
- Placed in the app shell (header, sidebar footer, settings page) — one instance
  per shell, not per page.
- Built from the project's existing primitives (`Button`, `DropdownMenu`,
  `Select`) so it inherits token styling. The deployed
  [theme-toggle.tsx.template](../resources/templates/theme-toggle.tsx.template)
  is a dependency-free fallback for projects without primitives.

## 9. Motion on theme change

Only when requested: fade the root surface (e.g. a 150–250ms `background-color`/
`color` transition on `html`), and disable it for
`prefers-reduced-motion: reduce`. Never animate every element individually, and
never animate when `disableTransitionOnChange` is enabled — the two cancel out.

## 10. Native UI and accessibility

- Set `color-scheme: light` / `dark` on the root so scrollbars, form controls,
  and `select` dropdowns match. `next-themes` does this when
  `enableColorScheme` is on (default).
- Verify contrast in both themes, including focus rings and disabled states.
- Do not rely on color alone for state; the toggle needs an icon *and* a label
  for assistive tech.
- RTL: spacing around the toggle and the indicator uses logical properties
  (`ms-`, `me-`), never `ml-`/`mr-`.

## 11. Testing

| Layer | Check |
| :--- | :--- |
| Jest | Toggle renders a stable placeholder before mount and an accessible control after; `setTheme` called with the right value |
| Playwright | Click through light → dark → system; assert the root attribute/class changes; reload and assert persistence; assert `color-scheme` |
| Storybook (N7) | `withThemeByClassName` (or the matching decorator) mirrors the app strategy — see [storybook-guide.md](./storybook-guide.md) |
| Visual | One screenshot per theme for the design system's base components |

Playwright example:

```ts
await page.getByRole("button", { name: /toggle theme/i }).click();
await page.getByRole("menuitem", { name: "Dark" }).click();
await expect(page.locator("html")).toHaveAttribute("class", /dark/);
await page.reload();
await expect(page.locator("html")).toHaveAttribute("class", /dark/);
```

## 12. Anti-patterns

- A second token file that shadows the first.
- Raw palette classes or arbitrary color values in components (N8 rejects these).
- `dark:` variants scattered per component instead of one token layer.
- Media-query-only dark mode with a user toggle that changes nothing.
- Reading `localStorage` in a component and rendering different markup on the
  server.
- Debounced/duplicated theme state (local context + `next-themes`).
- Toggling `body` in one place and `html` in another.
- Assuming `theme === "system"` when the user picked light or dark.

## 13. What this skill does *not* impose

- No required file name beyond `style_file_dir`.
- No required token list, color space, or value set.
- No required selector: `.dark`, `[data-theme]`, and `[data-mode]` are all valid.
- No required component library for the toggle.
- No required CSS framework (Tailwind, plain CSS, SCSS, CSS modules all work).

The acceptance test is behavioral: the toggle flips the app's real tokens, the
choice survives reload, and nothing flashes on first paint.
