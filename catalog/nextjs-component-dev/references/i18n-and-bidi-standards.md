# Internationalization (i18n), BiDi Styling & TSDoc Standards

This reference details the rules and conventions for multilingual dictionaries, bidirectional logical styling, and TypeScript documentation.

---

## 1. Zero Hardcoded Strings & Translation Dictionaries

1. **Root Dictionaries**: Dictionaries are stored under `messages/[locale].json` (e.g. `messages/en.json`, `messages/fa.json`) matching `supported_languages` in `docs/project.json`.
2. **Zero In-File Placeholders**: Never write hardcoded fallback dictionaries (`const DEFAULT_CONTENT = ...`) in `.tsx` files.
3. **Consumption Strategy**:
   - **RSC (Server Components)**: Call `await getTranslations("<namespace>")`.
   - **Client Components**: Call `useTranslations("<namespace>")`.
4. **Dictionary Population Step**: Populate all target dictionary files (`messages/en.json`, `messages/fa.json`, etc.) with authentic translations **before** writing component JSX.

---

## 2. Bidirectional (BiDi) & Logical Property Styling

1. **Exclusively Logical Tailwind Classes**:
   - Spacing: `ps-` (padding-start), `pe-` (padding-end), `ms-` (margin-start), `me-` (margin-end).
   - Positioning: `start-`, `end-`.
   - Text alignment: `text-start`, `text-end`.
   - Borders: `border-s-`, `border-e-`, `rounded-s-`, `rounded-e-`.
2. **Strictly Forbidden Physical Classes**:
   - `pl-`, `pr-`, `ml-`, `mr-`, `left-`, `right-`, `text-left`, `text-right` are strictly prohibited.
3. **Directional Elements**:
   - Flip navigation chevrons and directional arrows in RTL: `rtl:rotate-180` or `rtl:scale-x-[-1]`.
   - Unmirrored elements: Monospace code blocks, numeric counters, time digits, and telephone numbers retain LTR directionality (`dir="ltr"`).

---

## 3. Semantic Theme Tokens (OKLCH)

- Exclusively use semantic CSS variables configured in `app/globals.css`:
  - `bg-background`, `text-foreground`, `border-border`, `text-muted-foreground`, `bg-card`, `text-card-foreground`, `bg-primary`, `text-primary-foreground`.
- **FORBIDDEN**: Arbitrary hex colors (`#ffffff`, `#0f172a`) or raw Tailwind color scales (`bg-blue-500`, `text-zinc-900`) in component files.

---

## 4. Strict English TSDoc Annotations

Document all exported interfaces, components, props, generics, and return types in standard English TSDoc:

```tsx
/**
 * Props for the {@link FeatureCard} component.
 */
export interface FeatureCardProps {
  /**
   * Primary title displayed at the top of the feature card.
   * @defaultValue ""
   */
  title: string;

  /**
   * Supporting descriptive copy explaining the feature capability.
   */
  description: string;

  /**
   * Optional click handler invoked when the card action button is triggered.
   */
  onAction?: () => void;
}
```
