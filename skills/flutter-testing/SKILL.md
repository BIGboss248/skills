---
name: flutter-testing
description: >-
  Author and execute Flutter unit tests, widget tests, and BLoC state verification tests. Use when testing providers, repositories, BLoCs, or widgets.
---

# Flutter Testing (`flutter-testing`)

Orchestrates unit testing, widget testing, and BLoC testing in Flutter projects following the official [Flutter Testing Overview](https://docs.flutter.dev/testing/overview) and the vault's [Testing conventions](file:///d:/Scripts/Obsidian/Computer/Front%20end/Flutter/Flutter.md#Testing).

---

## Testing Workflow Checklist

Execute testing phases systematically:

- [ ] **Phase 1: Unit & Domain Tests**
  - Verify individual functions, providers, and repositories in `test/unit/`.
  - Use [unit_test.dart.template](./resources/templates/unit_test.dart.template) as the baseline.
  - Test edge cases: empty files, invalid spreadsheet schemas, unreadable directories, locked files.
- [ ] **Phase 2: BLoC State Transition Tests**
  - Test deterministic event-to-state emissions using `bloc_test`.
  - Use [bloc_test.dart.template](./resources/templates/bloc_test.dart.template).
  - Verify loading, progress percentage emissions, error handling, and terminal states.
- [ ] **Phase 3: Widget Tests**
  - Test UI components in isolation with `testWidgets`.
  - Verify widget interactions: picking files, triggering sort, and updating progress bars.
- [ ] **Phase 4: Test Suite Execution**
  - Run targeted test suites:
    ```powershell
    flutter test test/unit/
    ```

---

## Edge Cases & Known Pitfalls

- **Directory Context**: Flutter test commands must run from the root of the project where `pubspec.yaml` resides (use `-C <dir>` with `dart test` or execute inside the project directory).
- **Async Streams in Tests**: Ensure stream controllers or BLoCs are closed in `tearDown()` to prevent memory leaks or hung test runners.
- **Isolate Testing**: `Isolate.run()` calls in unit tests need proper mock data setup; avoid referencing file system paths that do not exist in test environments.

---

## Deep References

- [Unit & BLoC Testing Patterns](./references/unit_testing_guide.md)
- [Unit Test Template](./resources/templates/unit_test.dart.template)
- [BLoC Test Template](./resources/templates/bloc_test.dart.template)
