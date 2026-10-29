# F4 — Git Hooks (Husky + Commitlint)

## Enable when

The project uses Node and Conventional Commits. Skip for repositories that defer
commit hygiene to CI.

## Questions

1. Pre-push gate: `test:all`, lint only, or no test gate?
2. Should the pre-push hook fail closed when the script does not exist yet, or
   skip until it does?

## Steps

1. Install dev dependencies:
   `pnpm add -D husky @commitlint/cli @commitlint/config-conventional`.
2. Create `commitlint.config.mjs` extending `@commitlint/config-conventional`.
3. Initialize Husky (`pnpm exec husky init`).
4. Configure `.husky/commit-msg` to run `pnpm exec commitlint --edit $1`.
5. Configure `.husky/pre-push`:
   - `test:all` → run the full suite.
   - lint only → run the configured lint command.
   - no gate → omit the hook.
6. When `test:all` does not exist yet, add a guard that skips with a clear
   message instead of blocking every push.

## Acceptance

- [ ] A malformed commit message is rejected.
- [ ] A Conventional Commit message is accepted.
- [ ] `pre-push` behavior matches the chosen gate, including the missing-script case.

## Notes

- Do not create dummy test files to satisfy the hook. Guard it instead.
- `.husky/*` must be pinned to LF in `.gitattributes` on Windows.
