# N2 — Framework Core & App Shell

**Category:** Foundation · **Default:** on · **Depends on:** N1

This feature installs the framework and the files every other feature builds on:
agent guidance, providers, the composite `Link`, environment templates, and the
global error boundaries.

## Enable when

Always, for any Next.js App Router repository. Skip only when the project is not
Next.js (then the whole skill is the wrong tool).

## Questions

1. **Source layout** — `app/` or `src/app/`? Detected; confirm only if both or
   neither exists.
2. **Providers** — scaffold `app/providers.tsx` (query client, plus the
   `next-themes` wrapper when N13 is enabled), or compose into an existing
   provider file? There is no progress-bar provider: navigation feedback is per
   link via `useLinkStatus` (see
   [navigation-pending-guide.md](../navigation-pending-guide.md)).
3. **Environment files** — create `.env.example` and `.env.development`? Default
   yes; never overwrite existing values.
4. **Global boundaries** — scaffold `app/error.tsx`, `not-found.tsx`,
   `forbidden.tsx`, `unauthorized.tsx`, and `global-error.tsx`? Default yes when
   the files do not exist.
5. **Editor launch config** — create `.vscode/launch.json`? Default yes.

## Steps

1. Install the latest framework and peers:
   `<pkg_mgr> add next@latest react@latest react-dom@latest` (or
   `<pkg_mgr> create next-app@latest` when scaffolding from scratch). Never pin an
   older major or minor version. Add `next-themes` here **only** when N13 is
   enabled, because the deployed provider file imports it.
2. Scaffold or update root `AGENTS.md` from
   [AGENTS.md.template](../../resources/templates/AGENTS.md.template) and keep
   the mandatory notice: model knowledge of Next.js is outdated, so consult
   `node_modules/next/dist/docs` through `codebase-memory` before writing code.
   Preserve any machine-owned block (Next.js rewrites its own section).
3. Deploy [vscode-launch.json.template](../../resources/templates/vscode-launch.json.template)
   to `.vscode/launch.json` when requested.
4. Deploy [providers.tsx.template](../../resources/templates/providers.tsx.template)
   to `app/providers.tsx` (or merge into the existing provider file). Keep the
   `next-themes` wrapper only when N13 is enabled (installed in step 1);
   otherwise drop the wrapper and keep the query client. Add no other global
   provider for navigation state.
5. Deploy [Link.tsx.template](../../resources/templates/Link.tsx.template) to
   `app/components/Link.tsx`; it composes `@/i18n/navigation` with the inline
   `useLinkStatus` pending indicator (fixed size, opacity-toggled, 100ms delay,
   `motion-reduce` aware). When N4 is disabled, point the template at
   `next/link` instead. Contract:
   [navigation-pending-guide.md](../navigation-pending-guide.md).
6. Deploy [env.example.template](../../resources/templates/env.example.template)
   to `.env.example` and [env.local.template](../../resources/templates/env.local.template)
   to `.env.development`. Never write secrets, and never overwrite existing
   values.
7. Deploy the global boundaries from
   [global-boundaries/](../../resources/templates/global-boundaries/) as
   `app/global-error.tsx`, `app/error.tsx`, `app/not-found.tsx`,
   `app/forbidden.tsx`, and `app/unauthorized.tsx` when selected and missing.
8. Confirm `app/layout.tsx` exists; N4 moves the document shell to
   `app/[locale]/layout.tsx` when enabled.

## Acceptance

- [ ] `next`, `react`, and `react-dom` are declared in `package.json` at the
      latest release.
- [ ] `AGENTS.md` contains both the outdated-context notice and the
      `node_modules/next/dist/docs` lookup mandate.
- [ ] `app/providers.tsx` and `app/components/Link.tsx` exist and import without
      unresolved paths (including `next-themes` when N13 is enabled).
- [ ] No progress-bar package is declared; `app/components/Link.tsx` uses
      `useLinkStatus` from `next/link` and the indicator is always rendered,
      fixed-size, and opacity-toggled.
- [ ] No global navigation/progress provider exists in `providers.tsx` or
      `layout.tsx`.
- [ ] `.env.example` and `.env.development` exist when selected, and no secret
      value is committed.
- [ ] The selected global boundaries exist.
- [ ] No `{{TOKEN}}` placeholder remains in any deployed file.

## Notes

- The `AGENTS.md` machine-owned block is rewritten by `next dev`; commit it
  rather than deleting it.
- Do not add placeholder pages or tests — this feature scaffolds infrastructure
  only.
