# Back-to-Top Button (`BackToTop`)

Signature UX/UI design specifications and grilling templates for the Back-to-Top floating progress button.

---

## 1. Overview & Intent
- **Component**: Back-to-Top Button / Scroll-to-Top Floating Action Button (`BackToTop`, `ScrollToTop`, `ScrollProgressButton`).
- **Inspiration**: Cloudflare website back-to-top button.
- **Core Concept**: A floating action button that combines instantaneous return-to-top navigation with an ambient reading progress indicator. As the user scrolls down the page, a circular outline track fills clockwise around the button's perimeter, completing into a closed ring when the user reaches the bottom of the page.
- **Job-to-be-Done**: Gives the reader clear spatial awareness of their depth inside long-form documentation, landing pages, or feeds, while providing a 1-tap shortcut to return to top.

---

## 2. Grilling Question Template
When designing a Back-to-Top button or general page layout accessory, **grill the user** in Round 2 or Round 3:

> **Question**: "For the Back-to-Top button, would you like to incorporate the Cloudflare-style circular scroll progress ring (where a perimeter line fills clockwise around the circular button as you scroll down, indicating reading progress)?"
> 1. `(Recommended)` **Circular Scroll-Progress Ring**: Floating circular button wrapped in an SVG progress stroke that extends clockwise from $0\%$ to $100\%$ as the page is scrolled, completing at the bottom of the page.
> 2. **Standard Elevated Icon Button**: Fixed floating circular or rounded-square button with an arrow-up icon and elevation shadow, without scroll progress indication.
> 3. **Text-Label Pill**: Floating pill-shaped button displaying "Back to top ↑" that fades in after scrolling past the hero.

---

## 3. Detailed Design Specifications (For AI Designers)

### A. Spatial Layout & Viewport Anchoring
- **Positioning**: Fixed viewport anchoring: `fixed bottom-6 end-6 z-40`.
- **Bidirectional Placement**: Uses logical property `end-6` (right side in LTR, left side in RTL) to avoid colliding with start-aligned navigation elements or reading anchors.
- **Clearance**: Minimum $24\text{px}$ offset from bottom and end edges on desktop; $16\text{px}$ offset (`bottom-4 end-4`) on mobile.
- **Touch Target**: Outer container is $\ge 44\text{px} \times 44\text{px}$ (conforming to WCAG 2.5.5 touch target size). Standard desktop size: $48\text{px} \times 48\text{px}$.

### B. Visual Anatomy & Layering
The button consists of 3 concentric visual layers:
1. **Outer SVG Progress Ring (`svg`)**:
   - Size: $44\text{px} \times 44\text{px}$ (or $48\text{px} \times 48\text{px}$).
   - Orientation: Rotated $-90^\circ$ (`-rotate-90`) so stroke origin starts at 12 o'clock (top center) and fills clockwise.
   - **Background Track Circle (`<circle>`)**:
     - Radius $r = 18\text{px}$, center $(22, 22)$.
     - Stroke width: $2\text{px}$ to $2.5\text{px}$.
     - Color: Subtle muted border token (`border-border/40` or `stroke-muted/30`).
     - Fill: `transparent` (or inherits surface glass fill).
   - **Active Progress Circle (`<circle>`)**:
     - Radius $r = 18\text{px}$, center $(22, 22)$.
     - Circumference: $C = 2 \pi r \approx 113.1\text{px}$.
     - Stroke width: $2\text{px}$ to $2.5\text{px}$.
     - Cap style: `stroke-linecap="round"` for smooth progressive tip.
     - Color: Primary brand accent token (`stroke-primary`).
     - Dynamic Offset: `stroke-dasharray = 113.1`, `stroke-dashoffset = 113.1 * (1 - scrollProgress)`.
2. **Inner Button Surface (`button`)**:
   - Diameter: $36\text{px} \times 36\text{px}$ centered inside the $44\text{px}$ SVG ring (leaving a $4\text{px}$ breathing channel).
   - Shape: Full circle (`rounded-full`).
   - Material: Glassmorphic surface token (`bg-background/80` or `bg-card/90` with `backdrop-blur-md`).
   - Shadow: Subtle floating elevation (`shadow-md` in light mode, `shadow-black/40` in dark mode).
3. **Centered Icon**:
   - Iconography: Crisp upward arrow/chevron (`ArrowUp`, $16\text{px} \times 16\text{px}$).
   - Color: High-contrast foreground token (`text-foreground` or `text-primary`).

### C. Interaction Dynamics & State Machine
1. **Visibility & Entrance / Exit**:
   - **Threshold**: Inert and completely hidden when `scrollY < 300px` (or top $10\%$ of viewport).
   - **Exit State** (`scrollY <= 300px`): `opacity-0 scale-75 pointer-events-none translate-y-2`.
   - **Entrance State** (`scrollY > 300px`): `opacity-100 scale-100 pointer-events-auto translate-y-0`.
   - **Transition Duration**: $200\text{ms}$ ease-out.
2. **Scroll Progress Dynamics**:
   - Stroke extends smoothly in direct linear proportion to page scroll depth:
     $$P = \frac{\text{scrollY}}{\text{scrollHeight} - \text{clientHeight}}$$
   - At $P = 0$, progress ring is empty ($0^\circ$).
   - At $P = 1$ (page bottom), progress ring is completely closed ($360^\circ$).
3. **Hover State**:
   - Container lifts slightly (`scale-105` or `-translate-y-0.5`).
   - Progress ring stroke increases luminance or acquires subtle ambient glow (`drop-shadow(0 0 6px hsl(var(--primary) / 0.5))`).
   - Arrow icon micro-nudges upward by $2\text{px}$ (`-translate-y-0.5 transition-transform duration-150`).
4. **Active / Pressed State**:
   - Depress response (`scale-95`).
   - Instant trigger of smooth scroll: `window.scrollTo({ top: 0, behavior: 'smooth' })`.
5. **Focus State**:
   - High-contrast keyboard focus ring (`focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2`).

### D. Semantic Design Tokens Mapping
| Element | Light Mode Token | Dark Mode Token |
| :--- | :--- | :--- |
| **Progress Stroke** | `primary` (`hsl(var(--primary))`) | `primary` (`hsl(var(--primary))`) |
| **Track Stroke** | `muted/20` or `border/40` | `muted/30` or `border/50` |
| **Button Background** | `bg-background/80` (blur-md) | `bg-card/85` (blur-md) |
| **Border / Ring** | `border-border/50` | `border-border/60` |
| **Icon Color** | `text-foreground` | `text-foreground` |
| **Elevation Shadow** | `shadow-md` | `shadow-lg shadow-black/50` |

### E. Accessibility & Ergonomics
- **ARIA & Role**: Standard `<button type="button">`, with `aria-label="Back to top"` (localized via translation dictionaries).
- **Inert State**: When scrolled to top, element must be hidden from screen readers and tab order (`tabIndex = -1`, `aria-hidden = "true"`).
- **Reduced Motion**: Under `@media (prefers-reduced-motion: reduce)`, click immediately snaps to top without smooth scrolling, and hover transitions are instantaneous.
