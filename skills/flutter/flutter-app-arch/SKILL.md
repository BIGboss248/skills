---
name: flutter-app-arch
description: >-
  Architect Flutter apps with layered data, domain, and presentation code. Use
  when designing models, repositories, data providers, BLoCs, or dependency
  wiring.
---

# Flutter Architecture Standards

How the layers are shaped. This skill designs structure only: it does not build
screens, write tests, or plan the roadmap.

## Layers

| Layer | Contains | May depend on |
| :--- | :--- | :--- |
| Presentation | Widgets, screens, theme | Domain (events/state), theme tokens |
| Domain | BLoC/Cubit, events, states, entities | Data abstractions, pure Dart |
| Data | Repositories | Providers |
| Data source | File system, Excel, archive, DB, HTTP | Platform APIs |

Dependencies point inward: presentation knows the domain, the domain knows
abstractions, and only providers know the platform. A widget must never call a
provider directly.

## Rules

- States are immutable and `Equatable`; emit new instances, never mutate a
  collection inside a state.
- Events describe user intent, not widget calls.
- Business logic contains no `BuildContext`, no platform import, and no UI type.
- Repositories coordinate providers; a provider performs one I/O concern.
- Heavy work (spreadsheet parsing, compression, large JSON) runs in
  `Isolate.run()`, never on the UI isolate.
- Dependency injection is explicit and configured at the composition root.
- The state library comes from `docs/project.json` when present; otherwise follow
  the library already imported by the app and do not introduce a second one.

## File layout

```text
lib/src/
├── data/models/         entities
├── data/providers/      one I/O concern each
├── data/repositories/   coordination + mapping
├── logic/<feature>/     event, state, bloc
└── presentation/        screens/, widgets/, theme/
```

## Definition of Done

- [ ] Each new file sits in its layer and imports only inward.
- [ ] States are immutable and comparable.
- [ ] No platform, file system, or network call exists in the domain.
- [ ] Heavy work is isolated.
- [ ] The state library matches the project's declared choice.
- [ ] No widget, test, or roadmap file was written.

## Edge Cases & Pitfalls

- **UI thread blocking** — parsing or compressing on the main isolate freezes
  frames; use `Isolate.run()`.
- **`CardTheme` type mismatch** — Material 3 `ThemeData.cardTheme` requires
  `CardThemeData`, not `CardTheme`.
- **State mutation** — mutating a list in a state means `Equatable` reports no
  change and the UI never rebuilds.
- **Provider in a widget** — direct I/O in `build()` re-runs on every rebuild.
- **Two state libraries** — mixing BLoC and Riverpod in one feature doubles the
  wiring and the failure modes.
- **Fat repository** — a repository that also parses, formats, and caches is
  three responsibilities in one seam.

## References

- [Architecture and BLoC deep dive](./references/architecture_guide.md)
- [Theming guidelines](./references/theming_guide.md)
- [Theme template](./resources/templates/app_theme.dart.template)
