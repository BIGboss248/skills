---
name: flutter-component-dev
description: >-
  Build Flutter widgets and screens to project standards. Use when creating a
  widget or screen, or fixing state wiring, theming, localization, logging, or
  desktop ergonomics.
---

# Flutter Widget Standards

How a correct widget or screen is built. This skill writes presentation code
only: it does not write tests and it does not plan.

## Inputs & fallbacks

1. `docs/project.json` — `state_management.library`,
   `theming.semantic_tokens`, `i18n.supported_locales`, `i18n.rtl_supported`,
   `platforms`.
2. If absent, derive from the code: the state library already imported, the
   `ThemeExtension` already defined, the ARB files present, and the platforms in
   `pubspec.yaml`.
3. Ask at most two questions when the state contract is genuinely unclear.

## 1. Presentation purity

- No database, file system, or network call inside `build()`.
- Bind to state through the project's library: `BlocBuilder`, `BlocSelector`,
  or `BlocConsumer` for BLoC; `ref.watch()` for Riverpod.
- The widget receives data and callbacks; it does not decide business outcomes.

## 2. Theming

- Bind colors to `Theme.of(context).colorScheme` or
  `Theme.of(context).extension<AppThemeExtension>()`.
- No literal `Color(0x...)` outside the theme definitions.
- Spacing and radius come from the token extension, not from scattered numbers.
- Details: [theme and tokens](./references/theme-and-tokens.md).

## 3. Loading, error, and empty states

- Every async surface renders three states: loading, data, failure with retry.
- Desktop: prefer inline progress (linear or circular) or a button spinner.
  Full-screen shimmer belongs to large remote grids, not to settings panes.
- An error state names what failed and offers one retry action.

## 4. Localization and RTL

- All user-facing strings come from ARB catalogs for every supported locale.
- Access via `AppLocalizations.of(context)!`.
- When RTL is supported, use `EdgeInsetsDirectional` and `AlignmentDirectional`
  exclusively.
- Details: [l10n and RTL](./references/l10n-and-rtl.md).

## 5. Desktop ergonomics

Apply only when a desktop platform is targeted:

- `MouseRegion(cursor: SystemMouseCursors.click)` on custom interactive items.
- Context menus through `ContextMenuRegion`.
- Keyboard focus with `FocusNode`, `Shortcuts`, and `Actions`.
- Minimum 44×44 logical pixels for interactive targets.
- Details: [desktop ergonomics](./references/desktop-ergonomics.md).

## 6. Diagnostics

- Log through `dart:developer.log` or the project logger, with
  `name: '$runtimeType'` for filtering.
- Levels: DEBUG 500 (rebuilds, listeners), INFO 800 (lifecycle, user actions),
  WARN 900 (fallbacks, empty data), ERROR 1000 (caught exceptions, failed
  futures), FATAL 1200 (invariant breaches).
- Log operation boundaries, never every statement, and never from `build()`.
- Details: [component logging](./references/component-logging.md).

## Definition of Done

- [ ] No I/O in `build()`; state comes from the declared library.
- [ ] All colors and spacing come from theme tokens.
- [ ] Loading, data, and failure states all render.
- [ ] Every string resolves from an ARB catalog in every locale.
- [ ] Directional layout uses directional APIs.
- [ ] Desktop affordances exist when desktop is a target.
- [ ] Controllers, focus nodes, and subscriptions are disposed.
- [ ] No test was authored here; `tdd` owns tests.

## Edge Cases & Pitfalls

- **Unmounted context** — check `if (!context.mounted) return;` after an `await`.
- **Text overflow** — long dynamic strings need `ellipsis`, `maxLines`, or a
  scrollable container.
- **Controller leaks** — dispose `TextEditingController`, `ScrollController`, and
  `FocusNode`.
- **Log spam** — unconditional logging in a hot path floods DevTools.
- **Logger in `build()`** — add I/O during layout.
- **Mobile layout on desktop** — a stretched phone layout is not a desktop
  design.
- **Hardcoded copy** — a string literal bypasses every locale.

## References

- [Component logging](./references/component-logging.md)
- [Desktop ergonomics](./references/desktop-ergonomics.md)
- [Theme and tokens](./references/theme-and-tokens.md)
- [Localization and RTL](./references/l10n-and-rtl.md)
- [Logger template](./resources/templates/component_logger.dart.template)
