# Flutter Theming & Styling Guidelines

Reference: [Flutter Cookbook - Use Themes to Share Colors and Font Styles](https://docs.flutter.dev/cookbook/design/themes)

## 1. Material 3 Theme Architecture

Centralize styling with `ColorScheme.fromSeed` and configure semantic card/button themes:
- Reference template: [app_theme.dart.template](../resources/templates/app_theme.dart.template)

## 2. Windows Desktop Typography and Spacing
- Maintain consistent spacing tokens (4px, 8px, 16px, 24px).
- Provide high visual hierarchy for file paths and progress metrics.
- Keep components responsive across varying desktop window dimensions.
