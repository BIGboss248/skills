# N5 — Jest Unit Testing

**Category:** Testing & Quality · **Default:** on · **Depends on:** N2

## Enable when

Components, hooks, or pure functions need unit coverage. Skip for prototypes with
no test gate.

## Questions

1. **Test environment** — `jsdom` (default for components) or `node`?
2. **Coverage thresholds** — enforce a threshold now, or collect coverage only?
3. **Script names** — `test`, `test:unit`, and `test:all` conventions? Confirm
   the commands recorded in `docs/project.json`.

## Steps

1. `<pkg_mgr> add -D jest jest-environment-jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event @types/jest`.
2. Deploy [jest.config.ts.template](../../resources/templates/jest.config.ts.template)
   to `jest.config.ts` and
   [jest.setup.ts.template](../../resources/templates/jest.setup.ts.template) to
   `jest.setup.ts`; point the transformer at the project's Next.js version and the
   setup file at `@testing-library/jest-dom`.
3. Add the scripts: `test`, `test:unit`, and `test:all` (the latter runs every
   enabled suite; wire it after N6/N12 selection is known).
4. Do **not** create sample or placeholder test files (Rule 3). Patterns live in
   [sample-component.test.tsx](../../examples/sample-component.test.tsx) for
   reference only.

## Acceptance

- [ ] `jest.config.ts` and `jest.setup.ts` exist.
- [ ] `<PM_RUN> test` executes and reports zero tests found (not a config error)
      on a workspace without tests.
- [ ] `test:all` exists and matches the enabled suites.
- [ ] No dummy test file was created.

## Notes

- Unit tests never replace the E2E suite; keep both when the project ships UI.
- The design-system lint gate (N8) and Jest are independent; both run in CI.
