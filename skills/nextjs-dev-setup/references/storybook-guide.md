# Storybook Component Workshop Setup Guide

This guide covers the setup, architecture, and verification of Storybook in Next.js App Router projects.

---

## 1. Zero Dummy Stories Constraint (Rule 3)

> [!IMPORTANT]
> **NO DUMMY / SAMPLE STORY GENERATION IN WORKSPACE:**
> Do NOT create placeholder or dummy story files in the user workspace during setup. Only configure Storybook configuration files (`.storybook/main.ts`, `.storybook/preview.tsx`, and `package.json` scripts).
> Sample patterns are provided strictly for documentation:
>
> - Storybook CSF3 Example: [`sample-component.stories.tsx`](../examples/sample-component.stories.tsx)

---

## 2. Storybook Workshop Architecture

Storybook provides an isolated UI component development workshop, visual regression testing, interactive sandbox testing, and living styleguide documentation.

- **Configuration Files**:
  - `.storybook/main.ts`: see [`storybook-main.ts.template`](../resources/templates/storybook-main.ts.template)
  - `.storybook/preview.tsx`: see [`storybook-preview.tsx.template`](../resources/templates/storybook-preview.tsx.template)
- **Co-Located Story Architecture**:
  Story files MUST be co-located directly beside their respective UI component files across `components/` and `app/`:
  - UI Component: `components/ui/button.tsx` -> Story: `components/ui/button.stories.tsx`
  - Feature Component: `app/components/header/Header.tsx` -> Story: `app/components/header/Header.stories.tsx`

---

## 3. Mandatory `CssCheck` Story

Storybook suites must include a `CssCheck` story that asserts a resolved `getComputedStyle(element)` value (e.g., background color or font) to prove that Tailwind CSS and stylesheets successfully load in the preview iframe.

---

## 4. Theme Tokens & i18n Decorators

All Storybook preview wrappers and story decorators MUST strictly use semantic theme tokens from `globals.css` (`bg-background`, `text-foreground`, `border-border`) with scoped `.light` and `.dark` classes. If components use `next-intl` navigation (`Link`, `useRouter`), wrap stories with `NextIntlClientProvider` and `ProgressBarProvider`.

---

## 5. Unified `package.json` Storybook Scripts

```json
{
  "scripts": {
    "storybook": "storybook dev -p 6006",
    "build-storybook": "storybook build",
    "storybook:smoke": "storybook dev --smoke-test"
  }
}
```
