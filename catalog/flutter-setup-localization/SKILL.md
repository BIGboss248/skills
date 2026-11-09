---
name: flutter-setup-localization
description: >-
  Set up Flutter localization with ARB files and generated delegates. Use when
  adding a language, wiring l10n.yaml, or fixing missing or untranslated strings.
---

# Flutter Localization Setup

How localization is configured and consumed. Setup is procedural, so the stages
below are the job.

## 1. Dependencies

- `flutter pub add flutter_localizations --sdk=flutter`
- `flutter pub add intl:any`
- Both appear under `dependencies` in `pubspec.yaml`.

## 2. Code generation

- Enable `flutter: generate: true` in `pubspec.yaml` so the generated
  `AppLocalizations` refreshes on `pub get`.
- Create `l10n.yaml` at the project root:

| Key | Value |
| :--- | :--- |
| `arb-dir` | `lib/l10n` |
| `template-arb-file` | `app_en.arb` |
| `output-localization-file` | `app_localizations.dart` |
| `synthetic-package` | `true` |
| `use-escaping` | `true` |

- With `synthetic-package: false`, the generated file lands under
  `lib/l10n/` and must be imported from that path instead.

## 3. App wiring

- Inject the delegates: `AppLocalizations.delegate`,
  `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`,
  `GlobalCupertinoLocalizations.delegate`.
- List every supported `Locale`.
- `AppLocalizations.of(context)` is only valid below the `MaterialApp`.

## 4. ARB workflow

- New string: add the key to the template (`app_en.arb`) with a `description`.
- Changed string: update the key in **every** locale file in the same change.
- Regenerate with `flutter pub get` (or `flutter gen-l10n`).
- A key present in one locale and missing in another is a defect, not a
  fallback.

## 5. Dynamic messages

| Form | Syntax | Rule |
| :--- | :--- | :--- |
| Placeholder | `"Hello {userName}"` with a typed `placeholders` entry | Type and example are mandatory |
| Plural | `"{count, plural, =0{none} =1{one} other{{count} items}}"` | `other` is mandatory |
| Select | `"{gender, select, male{he} female{she} other{they}}"` | Every branch has copy |
| Number/date | `{value, number}` / `{value, date}` | Format from `intl`, not string concatenation |

## 6. RTL

- If any supported locale is RTL, layouts use `EdgeInsetsDirectional` and
  `AlignmentDirectional`.
- Directional icons flip; numerals, code, and phone numbers stay LTR.
- Allow 30–50% text expansion in buttons, tabs, and cards.

## Definition of Done

- [ ] Dependencies and `generate: true` are present.
- [ ] `l10n.yaml` matches the project's directory layout.
- [ ] Delegates and locales are wired at the app root.
- [ ] Every key exists in every ARB file with a description.
- [ ] Plurals include `other`; selects cover every branch.
- [ ] Generated files were regenerated, not hand-edited.
- [ ] `flutter analyze` and the parity check pass.

## Edge Cases & Pitfalls

- **Missing `generate: true`** — `AppLocalizations` never regenerates and new keys
  silently do not exist.
- **Hand-edited generated file** — overwritten on the next `pub get`.
- **Wrong import path** — with `synthetic-package: false`, the package import
  fails.
- **Translating a placeholder name** — placeholder identifiers are code; only the
  surrounding text is translated.
- **Plural without `other`** — generation fails.
- **Concatenated strings** — word order differs per language; compose inside the
  ARB message, not in Dart.
- **Locale without ARB** — listed in `supportedLocales` but renders fallback
  English.
- **Hardcoded direction** — `EdgeInsets.only(left: ...)` breaks RTL.

## References

- [Flutter internationalization guide](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [ARB message syntax](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#messages)
