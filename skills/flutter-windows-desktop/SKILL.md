---
name: flutter-windows-desktop
description: >-
  Build and package Flutter Windows desktop apps. Use when configuring desktop
  targets, release builds, obfuscation, MSIX or installer packaging, or release
  CI.
---

# Flutter Windows Desktop Standards

How a Windows build is produced and shipped. This skill covers the platform only.

## Platform rules

- Desktop embedding is enabled once: `flutter config --enable-windows-desktop`.
- `flutter doctor` must be clean before a release build.
- Debug, profile, and release are three distinct launch configurations; profile is
  the only one that reports real frame and memory behavior.

## Release build

- Build with symbols split so a production stack trace can be de-obfuscated:
  `flutter build windows --release --obfuscate --split-debug-info=build/windows/symbols`.
- Archive `build/windows/symbols/` with every release; a release without its
  symbol map cannot read crash reports.
- Never distribute `<app>.exe` alone. The plugin DLLs, `flutter_windows.dll`, and
  the `data/` folder ship together.

## Packaging order

1. Compress the portable archive (`.zip`).
2. Compile the installer (`ISCC.exe "/DMyAppVersion=<version>" windows\installer\setup.iss`).
3. Run `dart run msix:create` **last**.

Running MSIX before the zip and installer bundles the `.msix` inside them.

`setup.iss` resolves relative paths from its own directory; keep
`SetupIconFile=..\runner\resources\app_icon.ico` and
`OutputDir=..\..\build\windows`.

## MSIX rules

- `msix_config.capabilities` is a comma-separated string
  (`capabilities: internetClient`), never a YAML list — a list crashes
  `msix:create` with `type 'YamlList' is not a subtype of type 'String?'`.
- `install_certificate: false`, and pass `--install-certificate false` in CI so
  the build never blocks on an interactive prompt.
- The output file is
  `build/windows/x64/runner/Release/<pubspec_name>.msix` unless `output_name` is
  set.

## CI and release

- PR validation workflow: [ci template](./resources/templates/ci.yml.template).
- Release workflow: [release-please template](./resources/templates/release-please.yml.template).
- Release Please tracks versions through `release-please-config.json` and
  `.release-please-manifest.json`.
- `concurrency: cancel-in-progress: false` on release jobs so a push never
  cancels an in-flight build.
- Upload the `.zip`, the `.exe` installer, and the `.msix` as release assets.
- Fastlane targets mobile stores; it has no role in Windows desktop.

## Definition of Done

- [ ] `flutter doctor` clean and desktop embedding enabled.
- [ ] Release build produced with obfuscation and symbols archived.
- [ ] Packaging ran in order: zip, installer, MSIX.
- [ ] The archive does not contain the `.msix`.
- [ ] Release workflow uploads all three artifacts.
- [ ] No secret appears in the workflow or the bundle.
- [ ] Release build, installer, and CI artifacts were produced.

## Edge Cases & Pitfalls

- **Isolated exe** — missing DLLs or `data/` means an instant crash on another
  machine.
- **Lost symbols** — obfuscated crash reports become unreadable.
- **MSIX capabilities list** — the most common CI crash in this setup.
- **Certificate prompt** — blocks CI until it times out.
- **Install order** — MSIX created first bloats the zip and installer.
- **Release PR permissions** — GitHub blocks `GITHUB_TOKEN` from opening PRs
  unless the repository allows it.
- **Cancelled releases** — default concurrency cancels a running release build.

## References

- [Windows deployment and packaging](./references/deployment_guide.md)
- [CI/CD and release automation](./references/cicd_automation_guide.md)
- [PR validation template](./resources/templates/ci.yml.template)
- [Release workflow template](./resources/templates/release-please.yml.template)
