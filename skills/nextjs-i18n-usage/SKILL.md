---
name: nextjs-i18n-usage
description: >-
  Consume next-intl dictionaries and providers in Next.js. Use when adding
  translation keys, fixing missing translations, wiring providers in Storybook
  or tests, or auditing RTL and BiDi styling.
---

# next-intl Standards

How translations are consumed. This skill owns dictionary and provider rules; it
does not create components or pages.

## 1. Zero hardcoding

- No user-facing string in JSX, metadata, or JSON-LD literals.
- No in-file fallback dictionaries (`const DEFAULT_CONTENT = {...}` is forbidden).
- When copy changes, update every locale file in the same change.
- Dictionaries live at the project's configured `messages/` directory — the root
  `messages/`, not `app/dictionaries`.

## 2. API matrix

| Context | API |
| :--- | :--- |
| Async Server Component | `await getTranslations('namespace')` |
| Server formatter | `await getFormatter()` |
| `generateMetadata` | `await getTranslations('namespace')` |
| Client Component | `useTranslations('namespace')` |
| Client formatter | `useFormatter()` |
| Rich text with React nodes | `t.rich('key', { link: (chunks) => <Link ...>{chunks}</Link> })` |
| Internal navigation | the localized `Link`, `useRouter`, `usePathname` from `@/i18n/navigation` |
| Storybook | `<NextIntlClientProvider locale messages>` in the preview decorator |
| Jest/RTL | a `renderWithIntl` wrapper using real messages |

## 3. RTL and BiDi

- Logical utilities only: `ms-`, `me-`, `ps-`, `pe-`, `start`, `end`,
  `text-start`, `text-end`.
- Forbidden: `ml-`, `mr-`, `pl-`, `pr-`, `left-`, `right-`, `text-left`,
  `text-right`.
- Direction is set on `<html>` from the active locale (`rtl` for `fa`/`ar`).
- Icons that imply direction (arrows, chevrons) flip with the locale.

## 4. Parity

- Every key exists in every locale file; missing keys fail the check, extra keys
  are reported.
- Placeholders and plural forms must match across locales.
- Run the repo's parity check, or compare key sets directly when none exists.

## Definition of Done

- [ ] No literal user-facing string in the change.
- [ ] Keys added to every supported locale.
- [ ] The correct hook is used for the render context (server vs client).
- [ ] Providers present wherever the component renders outside the app tree.
- [ ] No physical-direction utility in the change.
- [ ] Parity check passes or its absence is reported.

## Edge Cases & Pitfalls

| Mistake | Cause | Fix |
| :--- | :--- | :--- |
| `useTranslations` in an async RSC | Hooks cannot run there | `await getTranslations` |
| `getTranslations` in a client file | Server-only | `useTranslations` |
| "No intl context found" | Missing provider in Storybook/test | Wrap with `NextIntlClientProvider` |
| `t('key') \|\| 'Fallback'` | Hidden missing key | Add the key to every locale |
| Raw `next/link` | Drops the locale prefix | Use the localized `Link` |
| Global progress bar | Wrong feedback model | `useLinkStatus` inside the localized link |
| `text-left` in an RTL locale | Physical direction | `text-start` |

## References

- [Implementation examples](./references/examples.md)
- [Parity script](./scripts/verify-dictionaries.ps1)
