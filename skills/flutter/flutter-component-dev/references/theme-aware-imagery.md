# Design concept: theme-aware imagery (day/night artwork)

#design #theming #flutter #images

One subject, two renders: the light theme shows the scene in daylight, the dark
theme shows the same scene at night. The image swaps because the artwork changes
lighting, not because the layout changes.

Same concept as the web version in
`nextjs-component-dev/references/theme-aware-imagery.md`, observed on
[adrin-innovation.ir](https://adrin-innovation.ir/) (inspected 2026-11-23): two
hero plates, one shot in daylight, one at night, swapped by the theme.

## When to use it

| Use it | Skip it |
| :--- | :--- |
| Onboarding, splash, empty-state, and marketing hero backdrops | Logos, icons, data tables, captured screenshots |
| Illustration or photography that can be relit | Artwork whose dark version hides real product detail |
| One camera and composition can be shared | You only have one plate and cannot produce the second |

## How the switch works

Resolve both asset paths from the theme, never from a `brightness` branch in
`build()`.

```dart
@immutable
class AppBrandTokens extends ThemeExtension<AppBrandTokens> {
  const AppBrandTokens({
    required this.heroImageAsset,
    required this.heroDayImageAsset,
    required this.radiusMd,
  });

  final String heroImageAsset;
  final String heroDayImageAsset;
  final double radiusMd;

  @override
  AppBrandTokens copyWith({
    String? heroImageAsset,
    String? heroDayImageAsset,
    double? radiusMd,
  }) {
    return AppBrandTokens(
      heroImageAsset: heroImageAsset ?? this.heroImageAsset,
      heroDayImageAsset: heroDayImageAsset ?? this.heroDayImageAsset,
      radiusMd: radiusMd ?? this.radiusMd,
    );
  }

  @override
  AppBrandTokens lerp(ThemeExtension<AppBrandTokens>? other, double t) => this;
}
```

The light theme registers `assets/images/hero_day.webp`, the dark theme
`assets/images/hero_night.webp`. The widget reads only
`Theme.of(context).extension<AppBrandTokens>()!.heroImageAsset`, so:

- No conditional in `build()` and no second source of truth.
- A theme switch rebuilds once, through `Theme`, which is exactly the frame you
  wanted to repaint anyway.
- Widget tests override one theme object instead of mocking `PlatformDispatcher`.

Register both files in `pubspec.yaml` under `assets:`; Flutter has no
theme-based asset variant folders, so the theme extension is the mechanism.

## The five rules that keep it correct

1. **One box, one aspect ratio.** Both plates fill a fixed `AspectRatio` (or
   `SizedBox`) with `BoxFit.cover`, so the swap moves nothing and text below
   does not jump.
2. **`gaplessPlayback: true`.** Samsung/Flutter image decode happens
   asynchronously; without it a theme switch can show one blank frame.
3. **Precache or accept the flash.** A large plate decodes after the switch.
   Either `precacheImage` both assets during startup (costs memory) or keep each
   plate under roughly 1 MP and let `gaplessPlayback` cover the gap. Do not run
   a `FadeTransition` over a hero: a crossfade holds both decoded bitmaps at
   once on desktop.
4. **Same composition, only lighting moves.** Identical camera, crop, subject
   placement, and an empty area for the title. A re-framed night plate reads as
   a different screen.
5. **Overlay is a token.** Put a gradient scrim from `colorScheme.surface` (or a
   token color with alpha) between the plate and the text so contrast holds on
   both renders. A literal `Colors.black54` fails on the daylight plate.

## Accessibility

- Decorative plate: `excludeFromSemantics: true` and no label.
- Meaningful plate: give both renders distinct localized labels from the ARB
  catalogue (`AppLocalizations.of(context)!.heroImageSemantics`).
- Never bake text into the artwork.
- Keep the swap instant; directional layout is unaffected because the plate is
  full-bleed. Any caption over it uses `AlignmentDirectional`.

## Pitfalls

- **`Theme.of(context).brightness` checked in `build()`** to choose an asset —
  duplicates the theme's own source of truth and drifts the moment a custom
  dark theme is added.
- **`MediaQuery.platformBrightnessOf(context)`** — follows the OS and ignores
  the in-app toggle.
- **Different plate sizes** — the hero grows or shrinks on every toggle.
- **Uncompressed pair** — two 4000 px JPEGs cost both load time and RAM; ship
  WebP/AVIF at display resolution and set `cacheWidth`.
- **`Image.asset` inside `build()` without `const` keys** — the element is
  recreated on every rebuild and re-decodes the bitmap.

Shipped template:
[`resources/templates/theme_aware_image.dart.template`](../resources/templates/theme_aware_image.dart.template).

## Web equivalent

The Next.js version swaps two `<Image>` plates with `dark:hidden` /
`hidden dark:block` instead of a theme extension:
`nextjs-component-dev/references/theme-aware-imagery.md`.
