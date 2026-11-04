# Typography & Visual Attenuation Hierarchy

Signature UX/UI design specifications and grilling templates for optical hierarchy and Google-style subtitle attenuation.

---

## 1. Overview & Intent
- **Component / Scope**: Typography Hierarchy, Section Headers, Subtitles, Eyebrows (`Typography`, `SectionHeader`, `Headings`, `Subtitles`, `ContentSection`).
- **Inspiration**: Google Design System & Material Design optical hierarchy standards.
- **Core Concept**: Deliberately attenuating the opacity and luminance of secondary typography—subtitles, lead paragraphs, eyebrow badges, and metadata ($60\%\text{–}70\%$ opacity / `text-muted-foreground`)—relative to primary headings ($100\%$ contrast `text-foreground`). This optical contrast differential makes primary headlines "flash" and command immediate visual attention while keeping long-form supporting copy comfortable and readable without visual clutter.
- **Job-to-be-Done**: Guides the visitor's eye sequence through a scannable narrative: 1st focal hook (high-contrast title), 2nd contextual comprehension (attenuated subtitle), 3rd action trigger (CTA).

---

## 2. Grilling Question Template
When designing section headers, article intros, or text-heavy components, **grill the user** in Round 2:

> **Question**: "For the section headings and supporting copy, what visual contrast hierarchy should we apply?"
> 1. `(Recommended)` **Google-Style Optical Attenuation**: Primary headings render in 100% high-contrast foreground (`text-foreground`), while subtitles and supporting material are attenuated to 60–70% opacity (`text-muted-foreground` / `text-foreground/70`) so key headlines flash and command immediate focus.
> 2. **Uniform High-Contrast**: Subtitles and headlines share full-opacity foreground colors, relying exclusively on font size and weight differentials for hierarchy.
> 3. **Accent Eyebrow Focus**: Subtitles remain muted, but an overline badge/pill is highlighted in saturated primary accent color.

---

## 3. Detailed Design Specifications (For AI Designers)

### A. Opacity & Contrast Tiering Matrix
| Typography Role | Opacity / Token Scale | Weight & Tracking | Visual Purpose |
| :--- | :--- | :--- | :--- |
| **Eyebrow / Category Tag** | `text-primary` or `text-muted-foreground` (70%) | `font-mono` / `font-medium`, `tracking-wider`, `text-xs uppercase` | Pre-classifies context before reading title. |
| **Primary Headline (`h1`, `h2`)** | `100%` (`text-foreground`) | `font-bold` / `font-semibold`, `tracking-tight` | The primary focal hook that "flashes" to the eye. |
| **Secondary Subtitle / Lead** | `60%–70%` (`text-muted-foreground` / `text-foreground/70`) | `font-normal` / `font-light`, `leading-relaxed`, `text-base` to `text-lg` | High readability without competing with the headline. |
| **Metadata / Tertiary Notes** | `50%–60%` (`text-muted-foreground/80`) | `font-normal`, `text-xs` to `text-sm` | Ambient supporting details. |

### B. Light vs. Dark Mode Tuning
- **Dark Mode**: Deep canvas (`bg-background`) requires careful optical tuning:
  - Headline: Crisp off-white (`hsl(0 0% 98%)`).
  - Subtitle: Slate/zinc muted foreground (`hsl(240 5% 65%)` or `text-foreground/70`). Prevents eye fatigue and chromatic glare.
- **Light Mode**: High-luminance canvas (`bg-background`):
  - Headline: Deep near-black (`hsl(240 10% 4%)`).
  - Subtitle: Mid-tone neutral slate (`hsl(240 4% 46%)` or `text-foreground/65`).

### C. WCAG Accessibility & Contrast Gate
- **Strict WCAG AA Conformance**: All attenuated subtitles must maintain a minimum contrast ratio of **$\ge 4.5:1$** against the underlying background surface. Never reduce opacity below the WCAG AA threshold.
- **Large Text Exemption**: Headlines $\ge 24\text{px}$ (or bold $\ge 18.5\text{px}$) must maintain $\ge 3:1$ contrast.
- **BiDi (RTL) Consistency**: Maintain identical opacity scales across both LTR and RTL directions.
