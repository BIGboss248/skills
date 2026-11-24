# Flutter Windows Desktop CI/CD & Fastlane / Release Automation

References:
- [Flutter Continuous Delivery](https://docs.flutter.dev/deployment/cd)
- [Conventional Commits & Release Please](file:///d:/Scripts/Obsidian/Computer/Software%20design/Conventional%20Commits%20and%20Release%20Please.md)
- [Fastlane Docs](https://docs.fastlane.tools/)

## 1. Automated Release Strategy (Release Please)

For desktop and cross-platform Flutter repositories, Google's **Release Please** provides automatic SemVer version bumping and changelog curation:
1. Pushes to `main` evaluate Conventional Commits (`feat:`, `fix:`, `chore:`, `feat!:`).
2. Release Please maintains an active Release PR bumping the version in `pubspec.yaml` and `.release-please-manifest.json`.
3. When the Release PR is merged, GitHub Actions builds the Windows release bundle, packages it into a `.zip`, and uploads it directly to the created GitHub Release using `gh release upload <tag> <file>`.

## 2. Fastlane vs. GitHub Actions on Windows

- **Fastlane**: Predominantly designed for mobile deployment (iOS App Store & Android Google Play) handling provisioning profiles, code signing, and beta testing (TestFlight / Play Console).
- **Windows Desktop Target**: Desktop automation is executed natively through GitHub Actions Windows runners (`windows-latest` or self-hosted) using PowerShell and the Flutter CLI:
  - `flutter config --enable-windows-desktop`
  - `flutter build windows --release --obfuscate --split-debug-info=...`
  - `Compress-Archive` to package the executable, DLLs, and data directory.
  - Fastlane can be chained in multi-platform repos if mobile targets (iOS/Android) are added later.

## 3. GitHub Actions Workflows

- PR Validation: [ci.yml.template](../resources/templates/ci.yml.template)
- Automated Release & Windows Upload: [release-please.yml.template](../resources/templates/release-please.yml.template)
