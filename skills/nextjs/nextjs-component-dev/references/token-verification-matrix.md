# Design Token Verification Matrix & Schema

Canonical design tokens stored in [`docs/project.json`](file:///docs/project.json) under `"design_system"` serve as the single source of truth for all component designs.

---

## 1. Token Prerequisite Checklist

Before drafting any component design, verify whether `docs/project.json` contains a complete `"design_system"` object:

| Category                | Token Keys                                                                                                                                                                             | Requirement                                          |
| :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------- |
| **Brand Personality**   | `brand_story`, `emotional_tone`, `aesthetic_keywords`                                                                                                                                  | High-level visual character and design ethos.        |
| **Light Palette**       | `canvas_bg`, `canvas_fg`, `surface_card`, `surface_elevated`, `border_subtle`, `primary_accent`, `secondary_accent`, `status_success`, `status_warning`, `status_error`, `status_info` | Complete light-mode semantic color scale.            |
| **Dark Palette**        | Counterparts for all light tokens (`canvas_bg`, `canvas_fg`, `surface_card`, `surface_elevated`, `border_subtle`, `primary_accent`, `secondary_accent`, `status_*`)                    | Complete dark-mode semantic color scale.             |
| **Typography System**   | Per-locale object keyed by each supported language (e.g. `"en"`, `"fa"`), containing `heading_font`, `body_font`, `code_font`                                                          | Locale-aware font pairings matching project locales. |
| **Border Radii**        | `radius_base`, `radius_card`, `radius_button`, `radius_badge`, `radius_modal`                                                                                                          | Geometric curvature scale.                           |
| **Elevation / Shadows** | `shadow_sm`, `shadow_card`, `shadow_elevated`, `shadow_modal`                                                                                                                          | Spatial depth and elevation levels.                  |

---

## 2. Dynamic Grilling for Missing Tokens

If any token category is missing from `docs/project.json`, grill the user to define it before designing components.

> [!IMPORTANT]
> **Zero Hardcoded Repository Assumptions:**
> Do NOT use pre-baked or hardcoded token choices from other projects. Dynamically synthesize **3 relevant choices** derived from the active project's scanned `docs/**`, `CONTEXT.md`, business goals, and supported languages.
>
> - Formulate 3 distinct, high-quality choices matching the project's domain.
> - Prefix the single strongest option with `(Recommended)`.
> - Do not include filler or artificial options.

### Grilling Topics for Missing Tokens:

1. **Brand Story & Aesthetic Philosophy**: Formulate 3 distinct aesthetic philosophies based on project goals.
2. **Color Palette Strategy (Light & Dark)**: Formulate 3 cohesive color pairings (canvas, surfaces, accents, status).
3. **Typography System (Per Locale)**: Formulate 3 font pairings (heading, body, mono) for every language in `supported_languages`.
4. **Border Radii & Geometry**: Formulate 3 curvature scales (e.g. sharp/tech, soft/modern, rounded/friendly).

---

## 3. Canonical Schema Reference (`docs/project.json`)

```json
{
  "design_system": {
    "brand_story": "Visual identity narrative and tone",
    "light_palette": {
      "canvas_bg": "#ffffff",
      "canvas_fg": "#0f172a",
      "surface_card": "#f8fafc",
      "surface_elevated": "#ffffff",
      "border_subtle": "#e2e8f0",
      "primary_accent": "#2563eb",
      "secondary_accent": "#4f46e5",
      "status_success": "#16a34a",
      "status_warning": "#d97706",
      "status_error": "#dc2626",
      "status_info": "#0284c7"
    },
    "dark_palette": {
      "canvas_bg": "#0f172a",
      "canvas_fg": "#f8fafc",
      "surface_card": "#1e293b",
      "surface_elevated": "#334155",
      "border_subtle": "#334155",
      "primary_accent": "#3b82f6",
      "secondary_accent": "#6366f1",
      "status_success": "#22c55e",
      "status_warning": "#f59e0b",
      "status_error": "#ef4444",
      "status_info": "#38bdf8"
    },
    "typography": {
      "en": {
        "heading_font": "Inter, sans-serif",
        "body_font": "Inter, sans-serif",
        "code_font": "JetBrains Mono, monospace"
      }
    },
    "border_radii": {
      "radius_base": "0.375rem",
      "radius_card": "0.75rem",
      "radius_button": "0.5rem",
      "radius_badge": "9999px",
      "radius_modal": "1rem"
    },
    "elevation_shadows": {
      "shadow_sm": "0 1px 2px 0 rgb(0 0 0 / 0.05)",
      "shadow_card": "0 4px 6px -1px rgb(0 0 0 / 0.1)",
      "shadow_elevated": "0 10px 15px -3px rgb(0 0 0 / 0.1)",
      "shadow_modal": "0 20px 25px -5px rgb(0 0 0 / 0.1)"
    }
  }
}
```
