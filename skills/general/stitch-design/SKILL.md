---
name: stitch-design
description: >-
  Generate Stitch screens and variants from a design spec. Use when scaffolding a
  screen visually, exploring layout variants, or downloading Stitch assets.
---

# Stitch Prototyping

How a design spec becomes a visual prototype. This skill produces Stitch assets
only.

## Inputs

- A spec from `to-spec` (design decisions, states, and constraints). If none
  exists, run `grilling` or `grill-with-docs`, then `to-spec`.
- `docs/project.json` for the design system and the Stitch project id.

## 1. One project per repository

- If `docs/project.json → stitch.project_id` exists, reuse it. Never call
  `create_project`.
- If absent, list projects; reuse a matching repository project, otherwise
  create one and persist `project_id`, `project_name`, and `title` immediately.
- Seed the canonical design system once (`upload_design_md` or
  `create_design_system_from_design_md`) so colors, fonts, and radii are global.

## 2. Generate

- Synthesize the prompt from the spec: purpose, persona, tone, hierarchy, tokens,
  and breakpoints.
- Set the device type to match the target (`DESKTOP`, `TABLET`, `MOBILE`).
- Generate the primary screen with `generate_screen_from_text`; record the screen
  id and resource name.
- Generate exactly **one** variant with `generate_variants`, exploring a
  different density, layout, or flow.

## 3. Download assets

- Target folder: `docs/design/components/<page>/<component>/stitch/`.
- Files: `screen.jpg`, `screen.html`, `variant-1.jpg`, `variant-1.html`,
  `stitch-meta.json`.
- Download with PowerShell `Invoke-WebRequest -Uri <url> -OutFile <path>`, one
  command per file. Never use a text fetcher — it corrupts binaries and mangles
  HTML.
- Signed URLs expire; download immediately.
- Verify each file is non-zero and a JPG is larger than 10 KB.

## 4. Update the spec

- Embed both screenshots under a Stitch layout section.
- Record the spatial grid, visual weight, whitespace rhythm, and typography
  hierarchy each prototype demonstrates.
- Compare the primary and the variant, naming the strength of each.

## 5. Visual assets

If a bespoke background, illustration, or icon is needed, output a prompt block
to the user (target path, aspect ratio, prompt). Never generate the image.

## 6. Audit

- Re-check file presence, size, and type; confirm `stitch-meta.json` parses and
  carries `projectId`, `screenId`, `generationPrompt`, and `variantIds`.
- Confirm the spec embeds both images.
- When a fresh-context reviewer is available, hand it the file list; otherwise do
  the check manually and say so.

## Definition of Done

- [ ] The spec was ingested and a project was reused or created once.
- [ ] The design system was seeded once.
- [ ] One primary screen and one variant exist.
- [ ] Five files exist with non-zero sizes and correct types.
- [ ] `stitch-meta.json` is valid JSON.
- [ ] The spec embeds both screenshots and benchmark notes.
- [ ] No image was generated.

## Edge Cases & Pitfalls

- **Text fetcher on a binary** — the JPG is corrupted and the HTML is markdown.
- **Expired URL** — a delayed download returns 403.
- **Duplicate projects** — one repository, one project.
- **Unpersisted project id** — the next run creates another project.
- **Spec drift** — prototypes generated without the spec produce a screen nobody
  asked for.
- **Multiple variants** — one variant is the exploration; more is noise.
- **Broken HTML check** — a file that starts with `{"` is JSON, not HTML.

## References

- Work spec — owned by `to-spec`
- [Stitch MCP tool reference](https://developers.google.com/stitch)
