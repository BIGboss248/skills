# N13 — Theming & Light/Dark Mode

**Category:** Foundation · **Default:** on · **Depends on:** N2 (N8 recommended,
N7 for Storybook parity)

Adds a light/dark theme system driven by the project's **existing** token layer.
It never dictates a CSS structure, token list, or selector — it detects what the
project already has and only fills the missing pieces.

Full reference: [theming-guide.md](../theming-guide.md).

## Enable when

The app has (or will have) a visual surface and users expect light/dark or
system-following appearance. Skip for API-only services, email-only repos, and
one-off scripts; record `[SKIPPED]`.

## Questions

1. **Token source (detect first)** — confirm `style_file_dir` and report what
   was found: existing dark selector (`.dark`, `[data-theme]`, `[data-mode]`,
   media query), color space, and token names. Do not ask for anything the
   stylesheet already answers.
2. **Strategy** — adopt the existing selector; if none exists, choose
   `class` (recommended), `data-theme`, or `data-mode`. This becomes the
   `next-themes` `attribute` value.
3. **Default** — `system` (recommended), `light`, or `dark`.
4. **Palette scope** — (a) keep existing token values and only add a dark layer
   (recommended when tokens exist), (b) derive dark values from the brand
   palette, or (c) leave palette values to design and wire switching only.
   Never re-declare or rename existing tokens.
5. **Toggle** — placement (header, sidebar footer, settings) and shape (icon
   cycle button vs. three-option menu). Reuse the project's primitives; fall
   back to the dependency-free template only when there are none.
6. **Motion** — animate the theme change? Default no
   (`disableTransitionOnChange` on).
7. **Storage key** — `theme` unless the app already wrote `localStorage.theme`.

## Steps

1. **Audit** — read `style_file_dir`, `tailwind.config.*` / `@custom-variant`,
   the component library, and any existing `.dark` / `[data-theme]` rules. Record
   the detected strategy in `docs/project.json` → `theme_strategy`. If a working
   theme system already exists, verify it and report `[UNTOUCHED]`.
2. `<pkg_mgr> add next-themes`.
3. **Provider** — compose into the existing provider file (see
   [providers.tsx.template](../../resources/templates/providers.tsx.template)).
   Use the detected attribute, `defaultTheme`, `enableSystem`, the storage key,
   and `disableTransitionOnChange` per question 6. Do not create a second
   provider file or a parallel context.
4. **Dark selector** — if the token layer has no dark variant, append one using
   the project's existing pattern and naming: a `.dark` rule, a
   `[data-theme="dark"]` rule, or a `@custom-variant dark` declaration. Append
   only — never reorder, restructure, rename, or overwrite existing values.
   When tokens already exist, add **only** the missing dark counterpart of each
   role; do not introduce a new token vocabulary.
5. **Root markup** — ensure `<html>` (or the document shell in
   `app/[locale]/layout.tsx` when N4 is enabled) carries `suppressHydrationWarning`
   when the provider writes the attribute client-side, and `lang`/`dir` from N4
   unchanged.
6. **Toggle** — deploy
   [theme-toggle.tsx.template](../../resources/templates/theme-toggle.tsx.template)
   as a starting point when the project has no primitives, then rewrite the
   markup to the project's `Button`/`DropdownMenu`/`Select`. Every variant must
   offer light, dark, and system (unless the notes record a binary-only
   decision), expose an accessible name, and show `resolvedTheme`.
7. **Native UI** — keep `enableColorScheme` (default) so `color-scheme` follows
   the theme for scrollbars and native controls.
8. **Palette (only when question 4 asks for it)** — derive light/dark pairs from
   the brand color, keeping the existing color space, and verify contrast for
   text, muted text, borders, and focus rings in both themes. If N3 is enabled,
   align `theme_color` with the resulting background/primary instead of
   `#000000`.
9. **Storybook (N7 enabled)** — ensure
   [storybook-preview.tsx.template](../../resources/templates/storybook-preview.tsx.template)
   uses the matching decorator (`withThemeByClassName` for class,
   `withThemeByDataAttribute` for `data-theme`) so stories and the app agree.
10. **Record** — write `theme_strategy`, `theme_storage_key`, and
    `theme_toggle_path` in `docs/project.json` when N1 is enabled.
11. **Agent rules** — document the token rule ("no raw palette classes, no
    arbitrary values, every new component in both themes") in `AGENTS.md` when
    N2 is enabled.

## Acceptance

- [ ] `next-themes` is declared and the provider composes with (does not
      replace) the existing providers.
- [ ] One toggle exists in the app shell and offers light, dark, and system.
- [ ] The chosen selector actually flips at least the page background and
      default text in a real browser (`<PM_RUN> dev`, not a type-check).
- [ ] The choice persists across reload; "system" follows
      `prefers-color-scheme`.
- [ ] No flash of the wrong theme on first paint and no hydration warning.
- [ ] Existing token values are unchanged (diff review); no token was renamed.
- [ ] No raw palette class or arbitrary color value in the toggle.
- [ ] `color-scheme` follows the theme.
- [ ] No second theme context/provider and no manual `localStorage` reads.
- [ ] Storybook decorator matches the app strategy when N7 is enabled.

## Notes

- **Structure is not fixed.** Do not create `globals.css` sections, rename
  variables, or introduce a token system the project did not choose. The only
  structural requirement is "the token layer has a dark variant that the app's
  components already consume".
- If the project has no token layer at all, do not invent one on the fly: wire
  the provider and toggle, theme the few real surfaces, and record the partial
  scope as a degraded result for N8 to finish later.
- `theme` is `undefined` during SSR and the first render — guard any icon that
  reads `resolvedTheme`.
- Do not enable `disableTransitionOnChange` and theme-change animation at the
  same time; they cancel each other.
- A manually requested global progress bar is unrelated to theming; keep it out
  of the provider file.
