---
name: flutter-observability
description: >-
  Instrument Flutter apps with structured logging and error capture. Use when
  adding logging, BLoC tracing, network interceptors, or global error handlers.
---

# Flutter Observability Standards

How diagnostics are wired. This skill instruments only; it does not build screens
or tests.

## 1. No direct prints

- `print()` is forbidden; `analysis_options.yaml` enforces `avoid_print`.
- Use the project logger or `dart:developer.log` with levels.
- Debug 500, info 800, warn 900, error 1000, fatal 1200.
- Tag each logger with the owning type or service name for filtering.

## 2. Global BLoC observer

- One `BlocObserver` is attached to `Bloc.observer` before `runApp()`.
- It records every transition and every error with the bloc name, current state,
  and next state.
- It never throws: a failing observer must not break the app.

## 3. Network tracing

- One interceptor records method, path, status, duration, and failure.
- Authorization headers, cookies, and bodies are stripped before logging.
- Retries are logged once, not once per attempt.
- A correlation id propagates from the UI action to the request.

## 4. Global error boundaries

| Source | Handler |
| :--- | :--- |
| Framework and build errors | `FlutterError.onError` |
| Async and isolate errors | `PlatformDispatcher.instance.onError` |
| Zone errors | `runZonedGuarded` when used |

- Handlers log with `error` and `stackTrace`, then forward to the crash reporter
  when one is configured.
- A handler must never trigger work that can throw again.

## 5. Desktop log files

- Write to `getApplicationSupportDirectory()`, never the project directory.
- Rotate: maximum 5 MB with 3 backups.
- Never log tokens, credentials, document contents, or personal data; file paths
  stay at trace or debug level.

## Definition of Done

- [ ] No `print()` in the change.
- [ ] The observer is registered before `runApp()`.
- [ ] Interceptors redact credentials and log duration and status.
- [ ] Both global handlers are installed and idempotent.
- [ ] Log rotation exists when logs are written to disk.
- [ ] No secret appears in a log line or span.

## Edge Cases & Pitfalls

- **PII leakage** — passwords, JWTs, and customer data in console or file logs.
- **Log growth** — an unrotated file fills the disk on desktop.
- **Infinite error loops** — a handler that throws inside itself.
- **Observer in tests** — a global observer writes noise into test output; gate it
  by environment.
- **Duplicate handlers** — attaching twice logs every error twice.
- **Production verbosity** — trace-level logging in release floods storage and
  costs frames.

## References

- [Logging standards and desktop rotation](./references/logging-standards.md)
- [Error boundaries and crash reporting](./references/error-boundaries.md)
- [BLoC observer template](./resources/templates/app_bloc_observer.dart.template)
