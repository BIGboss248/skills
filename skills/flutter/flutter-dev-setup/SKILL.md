---
name: flutter-dev-setup
description: >-
  Bootstrap a Flutter development environment. Use when initializing a Flutter
  project, or adding linting, logging, crash reporting, flavors, hooks, triage,
  or release CI.
---

# Flutter Environment Setup

Setup is procedural, so the stages below are the job.

## Pre-conditions

- Read `docs/project.json` when present for platforms, state, and localization.
- Verify the SDK and desktop embedding: `flutter doctor`.
- Scan `pubspec.yaml`, `analysis_options.yaml`, and `.vscode/` before generating
  anything. Never overwrite an existing file; merge.
- Tooling profiles: [VS Code and tooling](./references/vscode-and-tooling.md).

## Stage 1 — IDE and launch targets

- `.vscode/launch.json` with three configurations: debug, profile (`--profile`),
  and release (`--release`).
- `.vscode/settings.json` with formatting on save and the default target device.
- Template: [launch.json](./resources/templates/launch.json.template).

## Stage 2 — Analysis contract

- Deploy `analysis_options.yaml` from
  [the template](./resources/templates/analysis_options.yaml.template).
- Enforce at minimum: `prefer_const_constructors` (rebuild garbage),
  `avoid_print` (structured logging only), `unawaited_futures` (silent async
  drops), and `use_build_context_synchronously` (async-gap context use).
- Lint and hook details: [git hooks and lints](./references/git-hooks-and-lints.md).

## Stage 3 — Structured logging

- Add `logger`; deploy `lib/core/logging/app_logger.dart` from
  [the template](./resources/templates/app_logger.dart.template).
- Named output `[Tag] LEVEL message`, optional error, and a short stack trace.
- Levels by environment: development `trace`, release `info`, tests `warning`.
- Use `ProductionFilter`, **not** `DevelopmentFilter`: the latter checks inside
  an `assert`, so logs vanish under plain `dart run`.
- Create loggers lazily; never in `build()`; never pass a logger across an
  isolate boundary.
- Deeper guidance: [logging and observability](./references/logging-and-observability.md).

## Stage 4 — Flavors

- `config/dev.json` and `config/prod.json` from the
  [config template](./resources/templates/config.template.json).
- Entry points `lib/main_dev.dart` and `lib/main_prod.dart` read them through
  `--dart-define-from-file`.
- Details: [flavors and defines](./references/flavors-and-defines.md).

## Stage 5 — Crash reporting (Sentry)

- Ask the client to create a Sentry project for the app.
- Ask them to copy the setup prompt Sentry produces for a coding agent and paste
  it into the chat.
- Follow that prompt: it decides the packages, the initialization, and the symbol
  upload. Do not restate it here or fill the gaps from memory.
- No account and no prompt → record `[BLOCKED]`; never invent a DSN.

## Stage 6 — Hooks

- Use `lefthook`, not Node/Husky, to keep a pure Dart toolchain.
- Pre-commit: `dart format --set-exit-if-changed .` and
  `flutter analyze --fatal-infos`.
- Commit message: `dart run commitlint_cli --edit {1}`.
- Pre-push: `flutter test`.
- Config: [git hooks and lints](./references/git-hooks-and-lints.md).

## Stage 7 — Triage infrastructure

- Run `scripts/init_triage_infra.ps1` to scaffold issue forms and register the
  triage labels used by `triage`.
- Templates: [bug report](./resources/templates/bug_report.yml.template) ·
  [issue config](./resources/templates/issue_config.yml.template).

## Stage 8 — Release CI

- Deploy [the release workflow](./resources/templates/release-please.yml.template)
  and the Release Please config and manifest.
- Windows: MSIX capabilities as a comma-separated string, `install_certificate:
  false`, installer compiled before `msix:create`.
- Android: Gradle ≥ 9.1.0, AGP ≥ 8.11.1, Kotlin ≥ 2.2.0,
  `android.newDsl=false`.
- `concurrency: cancel-in-progress: false` on release jobs.
- Details: [release and CI/CD](./references/release-please-and-cicd.md).

MCP server configuration is owned by `ag-customizer`, not this skill.

## Definition of Done

- [ ] `flutter doctor` clean and desktop embedding enabled when targeted.
- [ ] Launch targets, analysis options, logger, and flavors exist.
- [ ] Crash reporting followed the client's pasted Sentry prompt, or is recorded
      as `[BLOCKED]` with the reason.
- [ ] Hooks run format, analyze, commitlint, and test.
- [ ] Triage forms and labels exist.
- [ ] Release workflow builds and uploads every declared platform artifact.
- [ ] No existing config was overwritten; changes were merged.
- [ ] No secret was written into a tracked file.

## Edge Cases & Pitfalls

- **`DevelopmentFilter`** — silently drops logs under `dart run`.
- **Logger in `build()`** — floods output and adds layout-time I/O.
- **Logger across isolates** — native-backed objects cannot cross; pass plain
  values and create the logger inside the worker.
- **Sensitive paths** — file and document names may carry user data; keep them at
  trace/debug and never log credentials.
- **Standalone Windows build** — the exe needs its DLLs and `data/`.
- **MSIX capabilities** — a YAML list crashes `msix:create`.
- **Android Gradle/Kotlin skew** — validate with `flutter analyze --suggestions`.
- **Release PR permissions** — `GITHUB_TOKEN` cannot open PRs unless the repo
  allows it.

## References

- [Flavors and defines](./references/flavors-and-defines.md)
- [Logging and observability](./references/logging-and-observability.md)
- [VS Code and tooling](./references/vscode-and-tooling.md)
- [Git hooks and lints](./references/git-hooks-and-lints.md)
- [Release Please and CI/CD](./references/release-please-and-cicd.md)
- [Templates](./resources/templates/)
