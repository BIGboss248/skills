---
name: flutter-theme
description: >-
  Build Material 3 light and dark themes with semantic tokens and persistence.
  Use when adding theme tokens, dark mode, or a theme toggle.
---

# Flutter Theming Standards

How themes are defined and switched. This skill writes theme code only.

## File structure

```text
lib/core/theme/
├── app_semantic_tokens.dart      ThemeExtension for custom tokens
├── app_theme.dart                Light and dark ThemeData
├── theme_repository.dart         Persistence contract
└── widgets/animated_theme_toggle.dart
```

## 1. Semantic tokens

- Every custom token is a field on a `ThemeExtension` with distinct `light` and
  `dark` values and a correct `lerp`.
- Tokens come from `docs/project.json` (`theming.semantic_tokens`); if absent,
  derive them from the design tokens already in the app.
- Widgets read `Theme.of(context).extension<AppSemanticTokens>()`, never a raw
  color.
- Reference: [semantic tokens](./references/semantic-tokens.md).

## 2. ThemeData

- `useMaterial3: true`.
- Palettes from `ColorScheme.fromSeed` or explicit `ColorScheme` mappings.
- Register the token extension in `extensions:` for both themes.
- Component themes are `ThemeData`-level, not per-widget overrides.
- Templates: [app theme](./resources/templates/app_theme.dart.template) ·
  [semantic tokens](./resources/templates/app_semantic_tokens.dart.template).

## 3. Persistence

- Read the saved mode **before** `runApp()` so the first frame is correct.
- Wrap the app in `AdaptiveTheme` with `light`, `dark`, and `initial`.
- The repository is the only writer of the persisted mode.
- Reference: [adaptive theme](./references/adaptive-theme.md).

## 4. Toggle

- The toggle animates between sun and moon with a rotation/scale transition
  around 450 ms.
- It respects `prefers-reduced-motion`; when reduced, switch instantly.
- It reads and writes through the repository, never through local state alone.
- Reference: [animated toggle](./references/animated-toggle.md) ·
  [circular reveal](./references/circular-reveal.md) ·
  [template](./resources/templates/animated_theme_toggle.dart.template).

## 5. Contrast

- Body text ≥ 4.5:1, large text ≥ 3:1, in both modes.
- Status colors (success, warning, destructive) are tokens, not Material
  palette members.
- Disabled states keep a distinguishable contrast, not just opacity alone.

## Definition of Done

- [ ] Both `ThemeData` instances register the token extension.
- [ ] No widget uses a literal color.
- [ ] Saved mode is applied before the first frame.
- [ ] Toggle persists and respects reduced motion.
- [ ] Contrast holds in both modes.
- [ ] `dart analyze` passes.

## Edge Cases & Pitfalls

- **Startup flicker** — reading the saved mode after `runApp()` flashes the wrong
  theme.
- **Missing `lerp`** — theme transitions throw or snap.
- **Token duplication** — the same color defined once as a token and again in a
  widget drifts.
- **Hardcoded status colors** — `Colors.red` ignores dark mode.
- **Toggle local state** — the switch flips but the app does not.
- **`CardTheme` type** — Material 3 expects `CardThemeData`.
- **Legacy toggle animation** — manual `AnimationController` loops rebuild the
  tree and stutter; use the circular-reveal/animated-switcher approach.

## References

- [Semantic tokens](./references/semantic-tokens.md)
- [Adaptive theme](./references/adaptive-theme.md)
- [Theme repository](./references/theme-repository.md)
- [Animated toggle](./references/animated-toggle.md)
- [Circular reveal](./references/circular-reveal.md)
- [Templates](./resources/templates/)
