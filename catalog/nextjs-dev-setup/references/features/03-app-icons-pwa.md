# N3 — App Icons & PWA Manifest

**Category:** Foundation · **Default:** on · **Depends on:** N2

## Enable when

The app is installable or needs a stable browser identity (favicon, touch icon,
manifest). Skip for internal tools without a brand asset.

## Questions

1. **Favicon source** — path to the user's `.ico` / `.png`, or reuse an existing
   `app/favicon.ico`?
2. **Manifest identity** — app name, short name, `theme_color`,
   `background_color` (derive from the project palette — never leave `#000000`
   when N13 recorded one), display mode (`standalone` recommended)?
3. **Icon set** — 192, 512, and a maskable 512 icon, or the minimum single icon?

## Steps

1. Place `app/favicon.ico` and `app/icon.png` from the supplied asset; generate
   `app/apple-icon.png` (180×180) from it.
2. Deploy [manifest.ts.template](../../resources/templates/manifest.ts.template)
   to `app/manifest.ts` and set the confirmed name, colors, and icons.
3. Keep every icon under 256 KB and reference it from the manifest with explicit
   `sizes` and `purpose`.
4. Follow [app-icons-and-pwa-guide.md](../app-icons-and-pwa-guide.md) for the
   file-convention matrix.

## Acceptance

- [ ] `app/favicon.ico`, `app/icon.png`, and `app/apple-icon.png` exist (or the
      `public/` fallbacks).
- [ ] `app/manifest.ts` exists and exports a valid `MetadataRoute.Manifest`.
- [ ] Every manifest icon path resolves to a real file.
- [ ] `theme_color` and `background_color` are explicit, not defaults or
      placeholders, and match the project palette (light background / brand
      primary).

## Notes

- Prefer App Router file conventions over `public/` links; they generate the
  `<link>` tags automatically.
- A maskable icon needs safe-zone padding; do not simply scale the square icon.
