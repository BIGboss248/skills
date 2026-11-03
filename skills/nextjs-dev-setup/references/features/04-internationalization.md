# N4 — Internationalization (`next-intl`)

**Category:** Foundation · **Default:** on · **Depends on:** N1, N2

This is the same workflow as feature **F11** in `setup-repository`; the two
skills share the locale routing, `next/root-params`, and dictionary contract.

## Enable when

The app serves more than one locale, must support RTL, or will add locales later.
Skip for single-locale apps and record `[SKIPPED]`.

## Questions

1. **Locales and default locale** — confirm `supported_languages` from N1 (deduced
   from `docs/` first); never invent locales.
2. **Locale prefix** — `always` (`/en/...`, recommended) or `as-needed`.
3. **Dictionary location** — `messages/[locale].json` unless the project already
   uses another directory.
4. **Route migration** — move top-level routes into `app/[locale]/` now, or
   scaffold infrastructure only.
5. **RTL locales** — which locale codes render right-to-left.
6. **Interceptor** — Next.js 16+ uses `proxy.ts`; 15 and older use
   `middleware.ts`. Detected from `package.json`; ask only if ambiguous.

## Steps

1. Audit existing `i18n/`, `app/[locale]/`, and the interceptor. If
   `setup-repository` F11 already scaffolded this, verify instead of rewriting and
   report `[UNTOUCHED]`.
2. `<pkg_mgr> add next-intl`.
3. Deploy the templates under
   [resources/templates/i18n/](../../resources/templates/i18n/):
   [routing.ts.template](../../resources/templates/i18n/routing.ts.template),
   [request.ts.template](../../resources/templates/i18n/request.ts.template), and
   [navigation.ts.template](../../resources/templates/i18n/navigation.ts.template)
   to `i18n/` (or `src/i18n/`). Adjust locales, default, and prefix.
4. Wrap `next.config.*` with `createNextIntlPlugin()` without dropping existing
   keys.
5. Deploy [proxy.ts.template](../../resources/templates/proxy.ts.template)
   for Next.js 16+ or
   [middleware.ts.template](../../resources/templates/middleware.ts.template)
   for older versions. Keep exactly one interceptor.
6. Deploy starter dictionaries from
   [messages/](../../resources/templates/messages/) for every locale with
   identical key paths.
7. Deploy [locale-layout.tsx.template](../../resources/templates/locale-layout.tsx.template)
   to `app/[locale]/layout.tsx`: `generateStaticParams()`, dynamic `lang`/`dir`,
   and `NextIntlClientProvider`. Remove `<html>`/`<body>` from `app/layout.tsx`
   when routes move.
8. Deploy [global.d.ts.template](../../resources/templates/global.d.ts.template)
   with the `AppConfig.Messages` augmentation.
9. Replace internal `next/link` / `next/navigation` imports with
   `@/i18n/navigation`.
10. Record `dictionaries_dir` and `dictionary_file_pattern` in
    `docs/project.json` (N1 contract).
11. Deploy the navigation contract:
    - Every internal navigation import (`Link`, `redirect`, `usePathname`,
      `useRouter`) comes from `@/i18n/navigation`. Only hash anchors, external
      URLs, and the locale-less root `app/not-found.tsx` may use `next/link`.
    - Deploy [Link.tsx.template](../../resources/templates/Link.tsx.template) to
      the component layer when the project wants a single link primitive; it
      wraps the localized `Link` and exposes the `useLinkStatus` pending
      indicator.
    - Pending navigation feedback uses Next's built-in `useLinkStatus` from
      `next/link`. Do **not** install a global progress-bar library.

## Acceptance

- [ ] `next-intl` is declared; `i18n/routing.ts`, `request.ts`, and
      `navigation.ts` exist.
- [ ] `request.ts` uses `next/root-params` and contains no `requestLocale` or
      `setRequestLocale()`.
- [ ] Exactly one interceptor exists and `next.config.*` composes the plugin.
- [ ] `app/[locale]/layout.tsx` exports `generateStaticParams()` and renders
      `NextIntlClientProvider`.
- [ ] Every locale has a dictionary with identical key paths.
- [ ] No `next/link` import remains for internal navigation; grep for
      `from "next/link"` and confirm only allowed exceptions.
- [ ] No progress-bar package is declared; pending feedback uses
      `useLinkStatus`.
- [ ] `node_modules/next/dist/docs` was consulted for the current routing and
      provider APIs.

## Notes

- Deprecated `requestLocale` / `setRequestLocale()` are forbidden.
- Keep `i18n/navigation.ts` pure TypeScript; component wrappers belong in
  `src/components/` (or the component root recorded in `docs/project.json`).
- Storybook previews and component tests need `NextIntlClientProvider` too (N7).
  They do not need any progress-bar provider, because `useLinkStatus` reads from
  the surrounding `<Link>` only and renders nothing while idle.
- Storybook and Jest load `next-intl` as ESM. Allow `next-intl`, `use-intl`, and
  their `@formatjs` / `intl-messageformat` dependencies through the test
  transform (see `transformIgnorePatterns`), or imports fail with "Must use
  import to load ES Module".
- Dictionary maintenance after setup follows `nextjs-i18n-usage`.
