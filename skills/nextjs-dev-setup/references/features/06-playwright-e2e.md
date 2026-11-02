# N6 — Playwright E2E & Instant Navigation

**Category:** Testing & Quality · **Default:** on · **Depends on:** N2

## Enable when

The app has user-visible routes that must be exercised in a real browser, or the
project wants Next.js instant-navigation insights.

## Questions

1. **Browsers** — Chromium only (fast) or the full matrix?
2. **Base URL and port** — default `http://localhost:3000`?
3. **Instant navigation** — enable `cacheComponents`, `partialPrefetching`, and
   instant insights in `next.config.ts`? Default yes.
4. **Test gate** — should `test:all` include Playwright (needed by N12)?
5. **Storybook or component E2E** — reserve `e2e/components/` for the QA auditor?

## Steps

1. `<pkg_mgr> add -D @playwright/test @next/playwright`.
2. Deploy [playwright.config.ts.template](../../resources/templates/playwright.config.ts.template)
   to `playwright.config.ts`; set `webServer`, base URL, and projects.
3. Install browsers: `pnpm exec playwright install --with-deps`.
4. In `next.config.ts`, enable the instant-navigation experiment chosen in
   question 3 without dropping keys owned by other features.
5. Add `test:e2e` and extend `test:all` when selected.
6. Do **not** create placeholder specs (Rule 3); the pattern in
   [sample-navigation.spec.ts](../../examples/sample-navigation.spec.ts) is for
   reference only.

## Acceptance

- [ ] `playwright.config.ts` exists and the browsers are installed.
- [ ] `test:e2e` runs against the configured base URL.
- [ ] `test:all` includes Playwright when the feature owns the gate.
- [ ] `next.config.ts` still contains every key written by N4/N11.
- [ ] No placeholder spec exists.

## Notes

- Playwright MCP (N10) is separate from the test runner; do not conflate them.
- Instant insights need the Next.js dev server running; document the command in
  `docs/project.json`.
