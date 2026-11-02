# N7 — Storybook Workshop

**Category:** Testing & Quality · **Default:** off · **Depends on:** N2

## Enable when

Designers and agents need to inspect components in isolation, or the team wants
visual and accessibility regression coverage.

## Questions

1. **Framework preset** — `@storybook/nextjs-vite` (recommended) or another
   builder?
2. **Accessibility addon** — enable `@storybook/addon-a11y`? Default yes.
3. **Story location** — co-located `*.stories.tsx` next to the component?
   Default yes.
4. **MCP integration** — register the Storybook MCP server (N10)?

## Steps

1. `<pkg_mgr> add -D storybook @storybook/nextjs-vite @storybook/addon-a11y`.
2. Deploy [storybook-main.ts.template](../../resources/templates/storybook-main.ts.template)
   to `.storybook/main.ts` and
   [storybook-preview.tsx.template](../../resources/templates/storybook-preview.tsx.template)
   to `.storybook/preview.tsx`.
3. Preview must wrap stories with `NextIntlClientProvider` when N4 is enabled and
   with `ProgressBarProvider` always — components that render `Link` or call
   `useTranslations` fail without them.
4. Add the `storybook` and `build-storybook` scripts.
5. Add `.storybook/` artifacts (`storybook-static/`, `*storybook.log`) to
   `.gitignore`.
6. Do **not** create placeholder stories (Rule 3); the pattern in
   [sample-component.stories.tsx](../../examples/sample-component.stories.tsx) is
   for reference only.

## Acceptance

- [ ] `.storybook/main.ts` and `.storybook/preview.tsx` exist.
- [ ] `<PM_RUN> storybook` starts without a missing-provider error.
- [ ] Preview decorators include `NextIntlClientProvider` when N4 is enabled.
- [ ] No placeholder story exists.

## Notes

- Storybook is a workshop, not a test replacement; keep Jest and Playwright.
- Details: [storybook-guide.md](../storybook-guide.md).
