# Design concept: theme-aware imagery (day/night artwork)

#design #theming #nextjs #images

One subject, two renders: the light theme shows the scene in daylight, the dark
theme shows the same scene at night. The hero swaps because the artwork changes
lighting, not because the layout changes.

Observed in production on [adrin-innovation.ir](https://adrin-innovation.ir/)
(inspected 2026-11-23, light/dark hero plates `Hero-Light-Desktop-v2.png` and
`Hero-Dark-Desktop.png`, mobile crops served through a `<source media>` inside
each `<picture>`).

## When to use it

| Use it | Skip it |
| :--- | :--- |
| Hero, chapter dividers, empty states, onboarding backdrops: one big atmospheric plate | Product screenshots, UI mockups, logos, icons |
| The subject reads in both lightings | The dark render would hide product detail |
| Two renders can share one camera and composition | You only have one image and no budget to relight it |

A UI screenshot cannot be "night lit" without lying about the product. Art
direction, photography, and 3D scenes can.

## How the switch works

Decide with CSS, never with React state.

- `next-themes` writes `.dark` on `<html>` after a blocking inline script. The
  server cannot know the theme, so both plates ship in the HTML and one class
  hides the other.
- Reading `useTheme()` in a client leaf and rendering one plate causes the
  classic flash: server HTML light, hydration dark.
- Both plates live in the same absolutely positioned box. The box owns the
  size; the plates only fill it with `object-cover`.

```tsx
<div className="relative isolate min-h-[560px] overflow-hidden">
  <Image
    src="/images/hero_day.webp"
    alt=""
    fill
    priority
    sizes="100vw"
    className="object-cover object-top lg:object-[55%_center] dark:hidden"
  />
  <Image
    src="/images/hero_night.webp"
    alt=""
    fill
    loading="lazy"
    fetchPriority="low"
    sizes="100vw"
    className="hidden object-cover object-top lg:object-[55%_center] dark:block"
  />
  <div className="relative z-10">{children}</div>
</div>
```

Run the theme variant on the `class` strategy (`@custom-variant dark
(&:where(.dark, .dark *))` in Tailwind v4, `darkMode: "class"` in v3). With the
`media` strategy the swap follows the OS and ignores the site toggle, which
breaks any app that owns a theme button.

Shipped example: [`examples/theme-aware-hero/`](../examples/theme-aware-hero/).

## The five rules that keep it fast

1. **One box, one aspect ratio.** Both plates fill the same wrapper, so the
   switch moves nothing. No `height` on the image, no re-layout, zero CLS.
2. **One `priority`, not two.** Two `priority` images emit two preload links
   that compete in the LCP window. Mark the variant that matches the default
   theme; give the other `loading="lazy"` and `fetchPriority="low"`. If dark is
   the default, flip which one gets `priority`, and set `color-scheme` in the
   theme script so the browser paints dark chrome on the first frame.
3. **Both plates download.** `display: none` does not stop a fetch. Budget
   them as a pair: two ~120 KB WebP/AVIF plates are fine, two 900 KB PNGs are
   not. Compress the daylight plate first, then generate the night plate from
   it.
4. **Same composition, only lighting moves.** Identical camera, focal length,
   crop, horizon, subject placement, and empty area for the headline. A
   re-framed night plate reads as a different page.
5. **Overlays are tokens.** Text sits on `from-background/80` style gradients
   built from semantic tokens, so contrast holds over both plates. A hardcoded
   `bg-black/40` fails on the daylight render.

## Mobile and desktop art

Two options, in order of preference:

- **One plate, responsive crop.** Keep one square-ish composition and move the
  focal point with `object-position` plus `sizes`. Cheapest, one file per theme.
- **Separate mobile plate.** Use a raw `<picture>` with `<source
  media="(min-width: 1024px)">` and a manual `/_next/image?url=…` srcset, as the
  reference site does. More files, better crop, and you lose `next/image`'s
  automatic `srcset` for the `<img>` fallback, so hand-write the widths.

## Accessibility and semantics

- Purely atmospheric plate: `alt=""`, wrapper is not announced.
- The plate carries meaning (e.g. "the city at night"): give both plates
  distinct translated alts from the dictionary. Never bake text into the
  artwork.
- No crossfade by default. An instant swap reads as day turning to night; a
  fade needs two stacked, always-decoded images. If a fade is required, drive
  `opacity` with `motion-safe:` only.

## Pitfalls

- **Theme branch in JSX** — hydration flash; both plates must be server
  rendered.
- **`hidden dark:block` on the light plate instead of `dark:hidden`** — light
  art stays visible under the night plate.
- **Different aspect ratios** — CLS on every toggle.
- **Two `priority` props** — double preload, worse LCP on both themes.
- **Uncompressed PNG pair** — the hero now weighs twice as much on every visit,
  on every theme.
- **Storybook** — story files are only written when `nextjs-storybook-story` is
  invoked; the concept itself needs no story.

## Flutter equivalent

The same concept in Flutter resolves the two asset paths from the theme
extension instead of a CSS class: `flutter-component-dev/references/theme-aware-imagery.md`.
