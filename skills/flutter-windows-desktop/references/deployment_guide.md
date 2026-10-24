# Windows Desktop Packaging & Deployment Reference

## 1. Output Directory

When running `flutter build windows --release`, Flutter generates the release binaries in:
`build/windows/x64/runner/Release/`

Required redistributable files:
- `<app_name>.exe`
- `flutter_windows.dll`
- `data/` folder (contains app assets, fonts, and compiled Dart AOT snapshot)
- Any compiled plugin DLLs (e.g. `file_selector_windows_plugin.dll`)

## 2. Inno Setup / MSIX Packaging

To distribute the app as a single installer:
- Package the entire contents of `build/windows/x64/runner/Release/` using Inno Setup or the `msix` Flutter package.
- Ensure the executable icon and application version in `windows/runner/Runner.rc` match the desired release metadata.
