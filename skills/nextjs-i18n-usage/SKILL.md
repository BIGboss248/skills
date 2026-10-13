---
name: nextjs-i18n-usage
description: Read/write translation dictionaries (messages/[locale].json), next-intl hooks (getTranslations/useTranslations), providers (Storybook/tests/subtrees), and BiDi styling. Triggers on "/nextjs-i18n-usage", "i18n dictionary", "use translations", "read dictionary", "i18n provider", "next-intl hooks", "storybook i18n", "test i18n", "add translation keys", "localize component", "create a component", "update a component".
metadata:
  author: BIGboss248
  version: "1.1"
---

# Next.js i18n Dictionaries & Providers (`nextjs-i18n-usage`)

Engineering standards, hooks, and provider patterns for consuming **`next-intl`** translations across React Server Components, Client Components, Storybook stories, and test harnesses.

> [!TIP]
> **Implementation Patterns:** Consult [`references/examples.md`](./references/examples.md) for complete code examples (RSC, Client forms, language switchers, Storybook decorators, and test wrappers).
> **Fast Execution:** Delegate dictionary validation or key sync to a lightweight subagent (`Model: 'flash'`).

---

## 1. Zero-Hardcoding Contract

- **Zero Hardcoded Text:** Never write user-facing labels, placeholders, or fallback strings in JSX.
- **No Mock Objects:** In-file mock dictionaries (e.g. `const DEFAULT_CONTENT = {...}`) are FORBIDDEN.
- **Synchronous Sync:** When adding/updating UI copy, insert authentic translations across **ALL** locale files in `messages/[locale].json` (e.g., `messages/en.json` and `messages/fa.json`) before writing JSX.

---

## 2. API & Hooks Quick Reference

| Environment / Target       | Hook / API               | Example Syntax                                                                           |
| :------------------------- | :----------------------- | :--------------------------------------------------------------------------------------- |
| **Server Component (RSC)** | `getTranslations`        | `const t = await getTranslations('namespace');`                                          |
| **Server Formatter**       | `getFormatter`           | `const format = await getFormatter(); format.dateTime(...)`                              |
| **Dynamic Metadata**       | `getTranslations`        | `export async function generateMetadata({ params }) { ... }`                             |
| **Client Component**       | `useTranslations`        | `const t = useTranslations('namespace');`                                                |
| **Client Formatter**       | `useFormatter`           | `const format = useFormatter(); format.number(...)`                                      |
| **Rich Text (Client)**     | `t.rich`                 | `t.rich('terms', { link: (c) => <Link href="/t">{c}</Link> })`                           |
| **Navigation**             | `@/i18n/navigation`      | `import { Link, useRouter, usePathname } from '@/i18n/navigation';`                      |
| **Storybook Preview**      | `NextIntlClientProvider` | Wrap preview decorator with `<NextIntlClientProvider locale="en" messages={enMessages}>` |
| **Unit Testing (Jest)**    | `renderWithIntl`         | Wrap render with `<NextIntlClientProvider locale="en" messages={messages}>`              |

---

## 3. BiDi (LTR / RTL) & Styling Standards

1. **Tailwind Logical Properties Only:**
   - **Forbidden:** `ml-*`, `mr-*`, `pl-*`, `pr-*`, `left-*`, `right-*`, `text-left`, `text-right`
   - **Required:** `ms-*`, `me-*`, `ps-*`, `pe-*`, `start-*`, `end-*`, `text-start`, `text-end`
2. **Dynamic Direction:** Dynamic `<html dir="rtl">` for `fa`/`ar` and `dir="ltr"` for `en`.

---

## 4. Anti-Patterns & Pitfalls

| Mistake                         | Root Cause                                  | Solution                                           |
| :------------------------------ | :------------------------------------------ | :------------------------------------------------- |
| **`useTranslations` in RSC**    | Hooks cannot run in async Server Components | Use `await getTranslations('ns')`                  |
| **`getTranslations` in Client** | Server-only async function                  | Use `useTranslations('ns')` with `"use client"`    |
| **"No intl context found"**     | Missing provider in Storybook/test          | Wrap story/test in `<NextIntlClientProvider>`      |
| **Hardcoded Fallbacks**         | e.g. `t('btn') \|\| 'Submit'`               | Add key to `messages/en.json` & `messages/fa.json` |
| **Raw `next/link`**             | Drops locale prefix on route change         | Use `Link` from `@/i18n/navigation`                |

---

## 5. Parity Verification

Execute dictionary parity check:

```pwsh
pwsh .agents/skills/nextjs-i18n-usage/scripts/verify-dictionaries.ps1
```
