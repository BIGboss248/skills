# N8 — Design-System Lint (`@shadcn/lint`)

**Category:** Testing & Quality · **Default:** on · **Depends on:** N2

## Enable when

Components must use the semantic design tokens and the agent-first styling
contract (no raw palette scales, arbitrary values, or inline styles).

## Questions

1. **Token source** — which stylesheet declares the semantic tokens
   (`app/globals.css` by default, recorded in `style_file_dir`)?
2. **Rule severity** — error (recommended, blocks the gate) or warning for the
   first migration?
3. **Lint command** — keep `pnpm lint` as the single gate?

## Steps

1. `<pkg_mgr> add -D @shadcn/lint` (or the project's registry alias).
2. Deploy [eslint.config.mjs.template](../../resources/templates/eslint.config.mjs.template)
   to `eslint.config.mjs` and merge with any existing flat config. Preserve
   Storybook and Next.js plugin entries.
3. Point the token rule at `style_file_dir` and set the severity from question 2.
4. Ensure `pnpm lint` runs ESLint over `app/`, `components/`, and `lib/`.
5. Document the token rule in `AGENTS.md` when N2 is enabled.

## Acceptance

- [ ] `@shadcn/lint` appears in `package.json`.
- [ ] The ESLint flat config registers the design-system rules.
- [ ] `<PM_RUN> lint` runs and reports only real violations.
- [ ] Raw palette classes (`bg-zinc-100`), arbitrary values (`p-[13px]`), and
      inline `style` props are rejected in a smoke test.

## Notes

- Fix violations instead of disabling rules.
- Details and rule rationale: [styling-and-linting-guide.md](../styling-and-linting-guide.md).
