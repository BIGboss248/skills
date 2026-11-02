# N12 — Git Hooks, Triage & CI/CD

**Category:** Delivery & Operations · **Default:** on · **Depends on:** N2; N5/N6 for the test gate

## Enable when

The repository uses Git and GitHub automation. Skip for throwaway prototypes or
remotes without GitHub Actions.

## Questions

1. **Hooks** — enable `commit-msg` (Commitlint) and `pre-push`? What should the
   pre-push gate run: `test:all`, lint only, or nothing?
2. **Release automation** — Release Please for SemVer release PRs and changelogs?
3. **Container publishing** — multi-arch (AMD64 + ARM64) image publishing to
   GHCR? Requires N11.
4. **Triage** — issue forms (bug only, or bug + feature), PR template, and remote
   labels (`bug`, `agent-triage`, `self-repair`, `verified`)?

## Steps

1. `<pkg_mgr> add -D husky @commitlint/cli @commitlint/config-conventional`, then
   `pnpm exec husky init`.
2. Deploy [commitlint.config.mjs.template](../../resources/templates/commitlint.config.mjs.template)
   to `commitlint.config.mjs`; wire `.husky/commit-msg` to
   `pnpm exec commitlint --edit "$1"`.
3. Wire `.husky/pre-push` to the gate from question 1. When N5/N6 are disabled,
   degrade to lint only and record the degradation in the report.
4. Run [init_triage_infra.ps1](../../scripts/init_triage_infra.ps1) to scaffold
   [bug_report.yml](../../resources/templates/bug_report.yml.template),
   [issue_config.yml](../../resources/templates/issue_config.yml.template), the PR
   template, and the remote labels when `gh` is authenticated.
5. Deploy [release-please.yml.template](../../resources/templates/release-please.yml.template)
   to `.github/workflows/release-please.yml`; enable `.next/cache` build caching
   and the multi-arch matrix only when selected.
6. Record `ci_cd_provider` and `release_automation` in `docs/project.json`.

## Acceptance

- [ ] `.husky/commit-msg` and `.husky/pre-push` exist and are executable.
- [ ] A non-conventional commit message is rejected locally.
- [ ] `.github/ISSUE_TEMPLATE/bug_report.yml` and `config.yml` exist; labels exist
      when `gh` is authenticated and a remote is present.
- [ ] The Release Please workflow exists and caches `.next/cache`.
- [ ] The pre-push gate references only scripts that exist.
- [ ] `github-triage` is named in `AGENTS.md` when the logging contract was
      installed.

## Notes

- Without `bootstrap-sha`, Release Please scans history from before the tooling
  existed.
- `gh repo edit --enable-issues` is required before the forms appear on GitHub.
- Details: [cicd-and-release-automation-guide.md](../cicd-and-release-automation-guide.md).
