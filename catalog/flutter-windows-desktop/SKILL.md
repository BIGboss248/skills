---
name: flutter-windows-desktop
description: >-
  Develop, debug, build, obfuscate, and package Flutter desktop applications on Windows with automated Release Please CI/CD. Use when configuring build flavors, obfuscation, VS Code launch options, or CI/CD pipelines.
---

# Flutter Windows Desktop (`flutter-windows-desktop`)

Comprehensive orchestration guide for developing, packaging, and deploying Flutter Windows applications referencing official [Flutter Windows Deployment](https://docs.flutter.dev/deployment/windows), [Continuous Delivery](https://docs.flutter.dev/deployment/cd), and [Fastlane & Release Automation](https://docs.fastlane.tools/).

---

## Windows Desktop Workflow Checklist

Follow this procedure for desktop development and distribution:

- [ ] **Phase 1: Environment & Platform Enablement**
  - Enable desktop embedding: `flutter config --enable-windows-desktop`.
  - Validate system prerequisites with `flutter doctor`.
  - Configure `.vscode/launch.json` and `.vscode/settings.json` for target device `windows`.
- [ ] **Phase 2: Local Run & DevTools Profiling**
  - Launch debug instance: `flutter run -d windows`.
  - Profile frame rendering and memory: `flutter run -d windows --profile`.
  - Monitor DevTools layout and inspect CPU isolates.
- [ ] **Phase 3: Production Build & Obfuscation**
  - Execute release build with symbol splitting to safeguard proprietary logic:
    ```powershell
    flutter build windows --release --obfuscate --split-debug-info=build/windows/symbols
    ```
- [ ] **Phase 4: Packaging & Automated CI/CD Release**
  - Configure PR validation workflow: [ci.yml.template](./resources/templates/ci.yml.template).
  - Configure automated release workflow: [release-please.yml.template](./resources/templates/release-please.yml.template).
  - Track versions with `release-please-config.json` and `.release-please-manifest.json`.
  - Automated release pipeline packages `build/windows/x64/runner/Release/` and uploads `.zip` directly to GitHub Releases.

---

## Edge Cases & Known Pitfalls

- **Redistributable DLLs**: Windows standalone executables require accompanying DLLs (`flutter_windows.dll`, plugin DLLs) and the `data/` folder in the same directory as `<app>.exe`. Never distribute `<app>.exe` in isolation.
- **Obfuscation Symbols**: Keep `build/windows/symbols/` archived alongside every release; stack traces from production crashes cannot be de-obfuscated without the matching symbol map.
- **Workflow Concurrency on Main**: In release workflows on `main`, configure `concurrency: cancel-in-progress: false` to prevent release builds from being cancelled by subsequent pushes.
- **Fastlane Scope**: Fastlane automates mobile store deployments (iOS App Store / Google Play); for Windows desktop, use native GitHub Actions Windows runners with PowerShell and Flutter CLI.

---

## Deep References

- [Windows Deployment & Packaging Specs](./references/deployment_guide.md)
- [CI/CD & Fastlane / Release Automation Guide](./references/cicd_automation_guide.md)
- [PR Validation Workflow Template](./resources/templates/ci.yml.template)
- [Release Please Windows Workflow Template](./resources/templates/release-please.yml.template)
