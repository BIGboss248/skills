# [Component Name] — Design Specification

- **Page**: `[Page Name]`
- **Component**: `[Component Name]`
- **Spec Path**: `docs/design/components/[page]/[component]/design-spec.md`
- **Design System Reference**: `docs/project.json` (`design_system`)

---

## 1. Executive Summary & Story

- **Component Identifier**: `[e.g., hero-showcase, pricing-matrix, feature-bento]`
- **Section / Element Type**: `[e.g., Hero Section, Interactive Card Grid, Navigation Header]`
- **Target Persona & Job-to-be-Done**: `[Who is using this component and what primary decision/action do they perform?]`
- **Emotional Tone & Attitude**: `[e.g., High-trust editorial, punchy technical minimalism, vibrant modern showcase]`
- **Core Business Goal**: `[e.g., Conversion uplift, feature discovery, reduced cognitive friction]`

---

## 2. Visual Hierarchy & Spatial Flow

- **Primary Focal Point (1st Hook)**: `[Hero visual element, high-impact headline, or key statistic]`
- **Secondary Focal Point (2nd Read)**: `[Supporting narrative cards, feature bullet points, or preview media]`
- **Tertiary Trigger (3rd Action)**: `[Primary call-to-action button, secondary documentation link, or input form]`
- **Eye Flow Navigation**: `[Top-down Z-pattern, central radial focus, or split F-pattern]`

---

## 3. Layout Grid & Responsive Breakpoints

### Mobile (< 768px)

- **Arrangement**: Single-column vertical stack.
- **Ergonomics**: Full-width actionable touch zones ($\ge 44\text{px}$ touch targets), compact vertical padding (`16px`–`24px`).
- **Media Behavior**: Scaled to 100% container width or converted into swipeable horizontal carousel.

### Tablet (768px – 1024px)

- **Arrangement**: 2-column modular grid or wrapped flex layout.
- **Spacing**: Medium gutters (`24px`), balanced content breathing room.

### Desktop ($\ge$ 1024px)

- **Arrangement**: Multi-column asymmetrical or balanced grid (e.g., 60/40 split or 3-column card matrix).
- **Constraints**: Max width container (`1280px` / `1440px`), generous spatial breathing room (`64px`–`96px` section padding).

---

## 4. Design Tokens & Color Mapping

| Element               | Light Mode Token   | Dark Mode Token    | Usage / Role                                   |
| :-------------------- | :----------------- | :----------------- | :--------------------------------------------- |
| **Canvas Background** | `canvas_bg`        | `canvas_bg`        | Page baseline behind component                 |
| **Card / Surface**    | `surface_card`     | `surface_card`     | Modular containers and cards                   |
| **Elevated Surface**  | `surface_elevated` | `surface_elevated` | Floating elements, popovers, badges            |
| **Borders**           | `border_subtle`    | `border_subtle`    | Section dividers and card outlines             |
| **Primary Accent**    | `primary_accent`   | `primary_accent`   | Primary buttons, active tabs, focal highlights |
| **Secondary Accent**  | `secondary_accent` | `secondary_accent` | Badges, secondary pills, subtle glows          |
| **Status Colors**     | `status_*`         | `status_*`         | Alerts, indicators, tags                       |

---

## 5. Typography Scale (Per Locale)

### English / LTR Locales

- **Display / Hero**: `[Heading Font]`, `3rem`–`4rem` (`48px`–`64px`), font-weight: `800`, line-height: `1.1`
- **Section Heading (H2)**: `[Heading Font]`, `2rem`–`2.5rem` (`32px`–`40px`), font-weight: `700`, line-height: `1.2`
- **Subheading (H3/H4)**: `[Heading Font]`, `1.25rem`–`1.5rem` (`20px`–`24px`), font-weight: `600`, line-height: `1.3`
- **Body Regular**: `[Body Font]`, `1rem` (`16px`), font-weight: `400`, line-height: `1.6`
- **Captions / Badges**: `[Body Font]`, `0.75rem`–`0.875rem` (`12px`–`14px`), font-weight: `500`
- **Code / Monospace**: `[Code Font]`, `0.875rem` (`14px`), font-weight: `500`

### Persian / RTL Locales (if supported)

- **Display / Hero**: `[Locale Heading Font]`, `2.75rem`–`3.5rem` (`44px`–`56px`), font-weight: `800`, line-height: `1.3`
- **Section Heading (H2)**: `[Locale Heading Font]`, `1.875rem`–`2.25rem` (`30px`–`36px`), font-weight: `700`, line-height: `1.4`
- **Body Regular**: `[Locale Body Font]`, `1rem` (`16px`), font-weight: `400`, line-height: `1.8`

---

## 6. Interaction States Matrix

| State                  | Visual Behavior & Transitions                                                                             |
| :--------------------- | :-------------------------------------------------------------------------------------------------------- |
| **Default**            | Baseline elevation, subtle borders, crisp readable typography.                                            |
| **Hover**              | Smooth micro-lift (`transform: translateY(-2px)`), border highlight, soft accent glow (`150ms ease-out`). |
| **Active / Pressed**   | Slight scale press (`transform: scale(0.98)`), darkened accent fill.                                      |
| **Focus Visible**      | High-contrast `2px` focus ring with `2px` offset for full keyboard accessibility.                         |
| **Disabled**           | 50% opacity, `cursor: not-allowed`, interactive triggers suppressed.                                      |
| **Skeleton / Loading** | Subtle pulsating shimmer surface matching component dimensions.                                           |

---

## 7. Bidirectional (RTL) Adaptations

- **Reading Direction**: Layout flips horizontally for RTL locales (start alignment moves to right).
- **Icons & Chevrons**: Directional navigation chevrons and back/forward arrows flip (`scaleX(-1)`).
- **Unmirrored Elements**: Monospace code blocks, numeric counters, time digits, and telephone numbers retain LTR directionality.

---

## 8. Accessibility & Ergonomics

- **Contrast Ratios**: Minimum `4.5:1` contrast for body copy and `3:1` for large display headings against surface backgrounds (WCAG AA/AAA).
- **Touch Target Sizing**: All interactive touch targets (buttons, links, icon toggles) are at least $44\text{px} \times 44\text{px}$.
- **Screen Reader Landmarks**: Semantic structure identified (e.g. `<header>`, `<main>`, `<section>`, `<nav>`).

---

## 9. Recommended Visual Assets & Prompts

### Visual Asset 1: `[Asset Name]`

- **Target File Path**: `docs/design/components/[page]/[component]/[filename].png`
- **Recommended Aspect Ratio**: `16:9` / `1:1` / `4:3`
- **Generation Prompt**:
  > "[Detailed prompt describing subject, composition, ambient lighting, color tokens, and style]"
