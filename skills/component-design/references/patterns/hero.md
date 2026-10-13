# Hero Section (`Hero`, `HeroSection`)

Signature UX/UI design specifications and grilling templates for palette-relative dynamic Hero section backgrounds.

---

## 1. Overview & Intent
- **Component**: Hero Section / Above-the-Fold Landing Surface (`Hero`, `HeroSection`, `LandingHero`).
- **Core Concept**: Replacing flat, static mono-color dark or light backgrounds with depth-rich, palette-derived atmospheric treatments. The background uses either a structured contextual picture/render with a calibrated contrast scrim OR layered multi-stop mesh/radial gradients tied directly to the project's color palette and tokens.
- **Job-to-be-Done**: Captures initial visitor intrigue, establishes brand emotional resonance within the first 3 seconds, and provides dimensional depth without competing with or compromising the legibility of hero headlines, value propositions, and CTAs.

---

## 2. Grilling Question Template
When designing a Hero section, **grill the user** in Round 1 or Round 2:

> **Question**: "What background treatment should we design for the Hero section to establish depth and brand tone?"
> 1. `(Recommended)` **Palette-Relative Atmospheric Gradient**: Dynamic multi-stop radial gradient blooms or mesh backdrop derived directly from canonical theme tokens (e.g. `primary` and `accent` blending into `background`), creating depth while ensuring high text contrast.
> 2. **Structured Thematic Image Backdrop**: Curated high-resolution image/render with a calibrated gradient scrim overlay (opacity fade from `background` to transparent) to keep typography WCAG AA compliant.
> 3. **Minimalist Clean Monotone**: Flat solid background using the standard semantic `bg-background` token without gradients or imagery.

---

## 3. Detailed Design Specifications (For AI Designers)

### A. Palette Derivation & Token Binding
- **Strict Token Relativity**: The gradient stops and color washes must NEVER use arbitrary hardcoded hex codes. They must reference the project's canonical palette tokens defined in `docs/project.json` / `app/globals.css`:
  - **Primary Bloom**: `hsl(var(--primary) / 0.15)` to `hsl(var(--primary) / 0.25)` in dark mode; `hsl(var(--primary) / 0.08)` to `hsl(var(--primary) / 0.12)` in light mode.
  - **Secondary / Accent Accentuation**: `hsl(var(--accent) / 0.10)` to `hsl(var(--accent) / 0.18)` positioned diagonally or offset from the primary bloom.
  - **Base Canvas**: Blends smoothly into `bg-background` so there is zero hard boundary line where the hero section transitions into subsequent content sections.

### B. Variant 1: Atmospheric Token-Driven Mesh / Radial Gradients
- **Spatial Arrangement**:
  - Primary focal bloom positioned behind or slightly offset from the hero title/visual hook (e.g. `radial-gradient(ellipse 80% 60% at 50% -20%, hsl(var(--primary) / 0.2), transparent)`).
  - Ambient secondary bloom at the corner or bottom-end edge to create chromatic balance.
  - Optional subtle CSS dot-grid or subtle noise overlay (`pointer-events-none opacity-30 mix-blend-overlay`) to add tactile texture and eliminate digital gradient banding.
- **Light vs. Dark Theme Tuning**:
  - **Dark Mode**: Higher contrast against deep canvas (`bg-background`); luminous translucent glows (`primary / 20%`, `accent / 15%`) creating a modern tech or premium studio feel.
  - **Light Mode**: Softer, high-luminance pastel tints (`primary / 6%`, `accent / 5%`) ensuring white or light-slate surfaces remain airy and crisp without muddy undertones.

### C. Variant 2: Structured Imagery / Renders with Calibrated Scrims
- **Layering & Composition**:
  - **Layer 1 (Base Asset)**: High-resolution thematic photography, architectural render, or 3D abstract object positioned `absolute inset-0 object-cover` or pinned to the visual focal column.
  - **Layer 2 (Gradient Scrim & Contrast Mask)**:
    - Vertical scrim: `linear-gradient(to bottom, transparent 0%, hsl(var(--background) / 0.8) 70%, hsl(var(--background)) 100%)` ensuring seamless bottom fusion with page content.
    - Directional text mask: Radial or horizontal gradient overlay over the text column (`from-background/95 via-background/70 to-transparent`) guaranteeing WCAG AA ($\ge 4.5:1$) contrast for headlines and subtext regardless of underlying image luminance.
  - **Layer 3 (Foreground Content)**: Hero headline (`h1`), value badge, description, CTAs, and trust metrics.
- **Image Asset Prompt Guidance (Rule 23 Compliance)**:
  - When designing with a picture background, provide a structured prompt block for the user to generate externally (e.g., aspect ratio `16:9`, specific lighting matching the brand palette).

### D. Layout, Ergonomics & Accessibility
- **WCAG Contrast Guarantee**: Text layers must maintain $\ge 4.5:1$ contrast against the combined background layer (calculated at the brightest/darkest point of the gradient or image).
- **Seamless Waterfall Transition**: The bottom boundary of the hero section must terminate in $100\%$ `bg-background` to guarantee a seamless visual waterfall into the next section.
- **Reduced Motion**: If ambient gradient breathing or parallax is applied, enforce static position under `@media (prefers-reduced-motion: reduce)`.
