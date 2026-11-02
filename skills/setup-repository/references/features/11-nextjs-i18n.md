# F11 — Next.js Internationalization (`next-intl`)

Merges the former `nextjs-i18n-setup` workflow into repository onboarding: locale
routing, `next/root-params` request config, localized navigation, the locale
segment layout, starter dictionaries, and verification.

## Enable when

- The repository is a **Next.js App Router** project that serves more than one
  locale, or must support RTL, or will add locales later.
- Skip for single-locale apps, the Pages Router, or non-Next.js stacks; record
  `[SKIPPED]` with the reason.

## Questions

1. **Locales and default locale.** Read `supported_languages` from
   `docs/project.json` when F1 already ran and confirm it. Ask for additions or
   removals; never invent locales.
2. **Locale prefix.** `always` (`/en/...`, recommended for SEO and caching) or
   `as-needed` (the default locale is unprefixed)?
3. **Dictionary location.** Confirm `messages/[locale].json` or override
   `dictionaries_dir` / `dictionary_file_pattern`.
4. **Route migration.** Move the existing top-level routes into `app/[locale]/`
   now, or scaffold the infrastructure only and migrate one route per change?
   Default: migrate now when the route tree is small.
5. **RTL locales.** Which of the supported locales render right-to-left
   (`ar`, `fa`, `he`, `ur`, …)?
6. **Interceptor.** Detect the installed Next.js major from `package.json`:
   16+ uses `proxy.ts`, 15 and older use `middleware.ts`. Ask only when the
   version cannot be detected or the project pins a range that spans both.

## Steps

1. **Audit before writing.** Read `next.config.*`, `app/layout.tsx`,
   `app/[locale]/` if present, `i18n/`, any `proxy.ts` / `middleware.ts`, and
   `docs/project.json`. If `nextjs-dev-setup` already scaffolded `next-intl`,
   do **not** re-scaffold: run the [verification](#acceptance), fix only real
   drift, and report the feature `[UNTOUCHED]`.
2. **Install the runtime.** Install with the project's package manager
   (`pnpm add next-intl`, or the matching `npm` / `yarn` / `bun` command).
3. **Metadata contract.** Merge into `docs/project.json` (preserve every existing
   key):
   ```json
   "dictionaries_dir": "messages",
   "dictionary_file_pattern": "[locale].json"
   ```
   Keep `supported_languages` and the default locale in sync with question 1.
4. **Routing.** Deploy [routing.ts.template](../../resources/templates/i18n/routing.ts.template)
   to `i18n/routing.ts` (or `src/i18n/routing.ts`); replace the `locales`,
   `defaultLocale`, and `localePrefix` values with the confirmed answers.
5. **Request config.** Deploy [request.ts.template](../../resources/templates/i18n/request.ts.template)
   to `i18n/request.ts`. It reads the locale from `next/root-params`; adjust the
   `../messages/` import only when the dictionaries do not sit next to `i18n/`.
6. **Navigation helpers.** Deploy [navigation.ts.template](../../resources/templates/i18n/navigation.ts.template)
   to `i18n/navigation.ts`. Keep this file pure TypeScript: no JSX, no React
   imports.
7. **Next.js plugin.** Compose `createNextIntlPlugin()` into the existing
   `next.config.*` instead of overwriting it; preserve `output`, `headers`,
   `experimental`, and every other key already present.
8. **Interceptor.** Deploy [proxy.ts.template](../../resources/templates/i18n/proxy.ts.template)
   for Next.js 16+ or [middleware.ts.template](../../resources/templates/i18n/middleware.ts.template)
   for Next.js <=15. Delete the other file and merge any pre-existing custom
   logic into the single handler; keep `api`, `trpc`, `_next`, `_vercel`, and
   static assets out of the matcher.
9. **Starter dictionaries.** Deploy
   [en.json.template](../../resources/templates/i18n/messages/en.json.template)
   and the matching locale files (for example
   [fa.json.template](../../resources/templates/i18n/messages/fa.json.template))
   to `messages/`. Every locale must expose exactly the same key paths.
10. **Locale layout.** Deploy [locale-layout.tsx.template](../../resources/templates/i18n/locale-layout.tsx.template)
    to `app/[locale]/layout.tsx` (or `src/app/[locale]/layout.tsx`). It owns
    `<html>`/`<body>`, exports `generateStaticParams()`, resolves `lang` and
    `dir`, and renders `NextIntlClientProvider`. Wrap children with any existing
    app-level providers. Remove the document shell from `app/layout.tsx` when
    routes move under `[locale]`.
11. **Type augmentation.** Deploy [global.d.ts.template](../../resources/templates/i18n/global.d.ts.template)
    to `global.d.ts` (or the project's existing global type file) and keep the
    `@/messages/en.json` import aligned with the configured alias.
12. **Localized links.** Replace internal `next/link` and `next/navigation`
    imports in components with `Link`, `redirect`, `usePathname`, and `useRouter`
    from `@/i18n/navigation`. Component wrappers (for example a `Link` with a
    progress bar) belong in the component layer, not in `i18n/navigation.ts`.
13. **Agent contract.** When F2 is enabled, add to `AGENTS.md`: dictionaries live
    in `messages/<locale>.json`, the request config is `i18n/request.ts` driven by
    `next/root-params`, internal navigation imports from `@/i18n/navigation`, and
    day-to-day dictionary work follows the `nextjs-i18n-usage` skill.
14. **Verify.** Run the verifier, then the production build:
    ```pwsh
    powershell -ExecutionPolicy Bypass -File <skill>/scripts/verify-i18n-setup.ps1
    ```
    ```bash
    bash <skill>/scripts/verify-i18n-setup.sh
    ```
    Then run the build command recorded in `docs/project.json` (for example
    `pnpm run build`), and request each locale route once (`/en`, `/fa`, …) to
    confirm a 200 response and the expected `lang`/`dir`.

## Acceptance

- [ ] `verify-i18n-setup.ps1` / `.sh` exits 0 (`i18n-setup: PASS`).
- [ ] `next-intl` is declared in `package.json`.
- [ ] `i18n/routing.ts`, `i18n/request.ts`, and `i18n/navigation.ts` exist and
      `request.ts` uses `next/root-params` with no `requestLocale` /
      `setRequestLocale()`.
- [ ] Exactly one interceptor exists: `proxy.ts` on Next.js 16+, `middleware.ts`
      on Next.js <=15.
- [ ] `next.config.*` composes `createNextIntlPlugin()` without losing existing
      options.
- [ ] `app/[locale]/layout.tsx` exports `generateStaticParams()`, renders
      `NextIntlClientProvider`, and is the only file rendering `<html>`/`<body>`.
- [ ] `global.d.ts` augments `AppConfig.Messages`.
- [ ] Every configured locale has `messages/<locale>.json` with identical key
      paths.
- [ ] `docs/project.json` records `dictionaries_dir` and
      `dictionary_file_pattern`.
- [ ] When F2 is enabled, `AGENTS.md` names `@/i18n/navigation` and the
      dictionary location.
- [ ] The `build_command` from `docs/project.json` succeeds and each locale
      route responds with 200.

## Notes

- **Do not double scaffold.** `nextjs-dev-setup` feature N4 already scaffolds
  `next-intl`. When it ran first, verification plus `[UNTOUCHED]` is the correct
  outcome — rewriting these files risks losing route migrations or custom
  middleware logic.
- **One interceptor only.** Keeping `middleware.ts` beside `proxy.ts` (or the
  reverse) applies the locale redirect twice and breaks prefetching.
- **Deprecated APIs.** `requestLocale` and `setRequestLocale()` are forbidden in
  the request config; `next/root-params` is the supported path.
- **Provider placement.** `NextIntlClientProvider` must wrap every client
  component that calls `useTranslations`; Storybook previews and component tests
  need the same wrapper.
- **Route handlers and server actions** are not locale-prefixed; keep `api` out
  of the matcher instead of translating them.
- **Static generation.** `generateStaticParams()` is mandatory when the app is
  statically exported or ISR-rendered per locale.
- **Unknown locales** must end in `notFound()` through `hasLocale`, never in an
  unhandled import error.
- Vocabulary for day-to-day dictionary work lives in the `nextjs-i18n-usage`
  skill; this feature only scaffolds the infrastructure.
