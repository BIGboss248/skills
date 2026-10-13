# Component Design Patterns Index

A token-optimized routing index of signature UX/UI component designs, interactive micro-patterns, and visual ergonomics.

> [!IMPORTANT]
> **Token Conservation Rule (Targeted Reading Only):**
> Do NOT read all pattern files. When designing a component, check the table below to locate the matching component type, and use `view_file` to read **strictly that component's dedicated reference file**. If no pattern exists for the component being designed, proceed directly with standard adaptive grilling without loading pattern files.

---

## Pattern Routing Table

| Component Type / Aliases | Signature Pattern / Feature | Inspiration Source | Dedicated Reference File |
| :--- | :--- | :--- | :--- |
| **Back-to-Top Button** (`BackToTop`, `ScrollToTop`) | Circular Scroll-Progress Ring Gauge (SVG dashoffset) | Cloudflare Website | [`patterns/back-to-top.md`](./patterns/back-to-top.md) |
| **Hero Section** (`Hero`, `HeroSection`, `LandingHero`) | Palette-Relative Atmospheric Backgrounds (Gradients & Scrims) | Brand Token Harmonization | [`patterns/hero.md`](./patterns/hero.md) |
| **Typography & Section Headers** (`Typography`, `SectionHeader`, `Headings`, `Subtitles`) | Google Optical Attenuation (Subtitles 60–70% Opacity) | Google Design System | [`patterns/typography-and-hierarchy.md`](./patterns/typography-and-hierarchy.md) |

---

## Adding New Patterns

When authoring a new component design pattern:
1. Create a dedicated file under `skills/component-design/references/patterns/<component-slug>.md` containing:
   - §1 Overview & Intent (Component name, inspiration, JTBD)
   - §2 Grilling Question Template (3 structured options for Round 1/2)
   - §3 Detailed Design Specifications (Spatial layout, visual anatomy, tokens, a11y)
2. Add a single corresponding row to the Routing Table above.
