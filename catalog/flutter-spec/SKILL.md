---
name: flutter-spec
description: >-
  Define the Flutter project specification. Use when a project needs platforms,
  state management, tokens, localization, or dependency decisions recorded before
  work is planned.
---

# Flutter Specification

Produces the stack specification a planner needs. This skill does not plan,
decompose, or implement: work specs and tickets belong to `to-spec` and
`to-tickets`.

## Scope

| Owns | Does not own |
| :--- | :--- |
| Platforms, state, tokens, i18n, DI, networking | Requirement elicitation (`grilling`) |
| `docs/project.json` content | Work spec (`to-spec`) |
| Stack constraints and non-goals | Ticket breakdown (`to-tickets`) |

## Inputs & fallbacks

1. `docs/project.json` when present.
2. Otherwise scaffold it from
   [project template](./resources/templates/project.template.json) and
   [schema](./references/project-json-schema.md).
3. Detect from the workspace: `pubspec.yaml`, `lib/src/` layers, `lib/l10n/`,
   `analysis_options.yaml`, platform folders.
4. Missing user decisions are supplied by `grilling`.

## 1. Inspect

- SDK and `flutter doctor` status; enabled platforms.
- Existing layers, state library actually imported, theme extension, ARB files,
  DI container, HTTP client.
- Analysis options, test layout, CI, and packaging scripts.
- Record what exists versus what must be created.

## 2. Decide

Every row must be answered or explicitly deferred with a revisit trigger.

| Decision | Field |
| :--- | :--- |
| Target platforms and desktop window settings | `platforms` |
| State library and architecture pattern | `state_management` |
| Design system, light/dark palettes, semantic tokens | `theming` |
| Default and supported locales, RTL, ARB paths | `i18n` |
| Dependency injection container | `di_container` |
| HTTP and storage choices | `networking`, `storage` |
| Non-goals and constraints | `non_goals`, `constraints` |

Never introduce a second state library or a second HTTP client: the specification
names one.

## 3. Write the specification

- `docs/project.json` is the single source of truth.
- Every token named in `theming` must be consumable as a `ThemeExtension` value.
- Every locale in `i18n` must map to an ARB catalog.
- Desktop in `platforms` implies desktop decisions: multi-pane layout, keyboard
  shortcuts, window sizing.
- Heavy work (spreadsheet parsing, archives, large JSON) is recorded as isolated
  work.

## 4. Hand off

- State the specification path and the decisions still open.
- Hand to `to-spec` for the work spec, then `to-tickets` for decomposition.
- Do not generate a roadmap, a phase list, `docs/plan/`, or app code.
- Do not invoke downstream skills.

## Definition of Done

- [ ] Every required field is answered or deferred with a trigger.
- [ ] Platforms, state, tokens, and locales agree with the repository.
- [ ] No second library or client is introduced.
- [ ] Every named token and locale is realizable.
- [ ] No roadmap, ticket, or code file was written.

## Edge Cases & Pitfalls

- **Desktop as stretched mobile** — a desktop target without desktop decisions
  produces a phone layout on a monitor.
- **Two sources of truth** — restating platforms or locales outside
  `project.json` guarantees divergence.
- **Invented tokens** — a token not in the theme becomes a hardcoded color.
- **Unconsumed fields** — a specification field no implementation reads is
  decoration.
- **Planning here** — a roadmap or phase list recreates the conflict this split
  removed.
- **Silent library drift** — mixing BLoC and Riverpod doubles the wiring and the
  failure modes.

## References

- [Project JSON schema](./references/project-json-schema.md)
- [Project template](./resources/templates/project.template.json)
