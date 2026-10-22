# Next.js Internationalization Setup Guide (`next-intl`)

A comprehensive reference for bootstrapping, configuring, and verifying **`next-intl`** in Next.js App Router projects during development setup.

---

## 1. Architectural Rules & Requirements

1. **Metadata Contract (`docs/project.json`):**
   ```json
   "dictionaries_dir": "messages",
   "dictionary_file_pattern": "[locale].json"
   ```
2. **Next.js Version Interceptor:**
   - **Next.js 16+**: Use `proxy.ts` (or `src/proxy.ts`). Migrate and remove any legacy `middleware.ts`.
   - **Next.js <=15**: Use `middleware.ts` (or `src/middleware.ts`).
   - Route matcher: `matcher: ["/((?!api|trpc|_next|_vercel|.*\\..*).*)"]`.
3. **Modern Root Params (`next/root-params`):**
   - In `i18n/request.ts`, retrieve route locale using `await rootParams.locale()`.
   - Deprecated `requestLocale` and `setRequestLocale()` are strictly forbidden.
4. **Pure TypeScript Navigation:**
   - Export `Link`, `redirect`, `usePathname`, `useRouter`, `getPathname` from `i18n/navigation.ts` (pure TypeScript, zero JSX per Rule 11).
   - Composite UI wrappers (e.g. `Link` with progress bar) live in `app/components/Link.tsx`.
5. **Static Generation:**
   - Root layout `app/[locale]/layout.tsx` MUST export `generateStaticParams()` returning `{ locale }` for all supported locales in `routing.locales` (Rule 24).
6. **Starter Translation Dictionaries:**
   - Dictionaries reside in `messages/` at project root (e.g. `messages/en.json`, `messages/fa.json` per Rule 5).
7. **Type Augmentation:**
   - Augment `AppConfig.Messages` in `global.d.ts` for end-to-end auto-completion of translation keys.

---

## 2. Drop-in Templates Map

| Component / Target File | Template File | Notes |
| :--- | :--- | :--- |
| `i18n/routing.ts` | [`routing.ts.template`](../resources/templates/i18n/routing.ts.template) | Defines `locales`, `defaultLocale`, `localePrefix: "always"` |
| `i18n/request.ts` | [`request.ts.template`](../resources/templates/i18n/request.ts.template) | Server request handler with `next/root-params` |
| `i18n/navigation.ts` | [`navigation.ts.template`](../resources/templates/i18n/navigation.ts.template) | Pure TS navigation helpers (`createNavigation`) |
| `proxy.ts` (Next 16+) | [`proxy.ts.template`](../resources/templates/proxy.ts.template) | App Router interceptor for Next.js 16+ |
| `middleware.ts` (Next <=15) | [`middleware.ts.template`](../resources/templates/middleware.ts.template) | App Router middleware for Next.js <=15 |
| `app/[locale]/layout.tsx` | [`locale-layout.tsx.template`](../resources/templates/locale-layout.tsx.template) | Static params, dynamic `lang`/`dir`, and `NextIntlClientProvider` |
| `global.d.ts` | [`global.d.ts.template`](../resources/templates/global.d.ts.template) | Augments `AppConfig.Messages` |
| `messages/en.json` | [`en.json.template`](../resources/templates/messages/en.json.template) | Starter baseline English dictionary |
| `messages/fa.json` | [`fa.json.template`](../resources/templates/messages/fa.json.template) | Starter baseline Persian dictionary |
| `next.config.ts` | [`next.config.ts.template`](../resources/templates/next.config.ts.template) | Wraps config with `createNextIntlPlugin()` |
| `app/components/Link.tsx` | [`Link.tsx.template`](../resources/templates/Link.tsx.template) | Composite Link with progress bar integration |
| `.storybook/preview.tsx` | [`storybook-preview.tsx.template`](../resources/templates/storybook-preview.tsx.template) | Storybook decorator with `NextIntlClientProvider` |

---

## 3. Storybook & Test Harness Integration

- **Storybook Context (Rule 25):** Always wrap Storybook stories rendering `Link` or `useTranslations` with `NextIntlClientProvider` (supplying `messages` from `messages/en.json`) and `ProgressBarProvider` in `.storybook/preview.tsx`.
- **Zero-Hardcoding Contract (Rule 27):** Never include hardcoded user-facing strings or in-file mock dictionaries in component code. All strings must be extracted into `messages/[locale].json` across all supported languages.

