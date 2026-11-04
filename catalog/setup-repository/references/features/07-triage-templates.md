# F7 — GitHub Issues & Triage Infrastructure

## Enable when

The repository accepts issues or pull requests through GitHub. This feature sets
up the **infrastructure**; the `github-triage` skill owns the runtime triage
loop.

## Questions

1. Enable GitHub Issues on the remote? (If no, skip this feature.)
2. Which issue forms: bug only, feature only, or both?
3. Include `.github/PULL_REQUEST_TEMPLATE.md`?
4. Provision the remote labels (`bug`, `enhancement`, `agent-triage`,
   `self-repair`, `verified`)?
5. Contact links for `config.yml` (docs, discussions, security policy)?
6. Should the `github-triage` logging contract live in `AGENTS.md` (F2) or
   `CONTRIBUTING.md`? Default: `AGENTS.md`, with a pointer from `CONTRIBUTING.md`.

## Steps

1. Enable issues on the remote:
   `gh repo edit <owner>/<repo> --enable-issues`.
   Leave issues disabled if the answer to question 1 was no.
2. Run the helper from the repository root:
   `powershell -ExecutionPolicy Bypass -File <skill>/scripts/init_triage_infra.ps1`.
   It deploys the selected forms, `config.yml`, and the PR template, then syncs
   labels when `gh` is authenticated and a remote exists.
3. If the helper is unavailable, copy the templates from
   [resources/templates](../../resources/templates) manually.
4. Validate each issue form: unique ids, supported block types, options on every
   dropdown/checkbox, required flags where intended.
5. Install the logging contract from
   [AGENTS.md.template](../../resources/templates/AGENTS.md.template)
   ("Issue logging (`github-triage`)" section): dedupe → register →
   diagnose → fix/verify → capture rule → resolve → report. If F2 is disabled,
   place the same contract in `CONTRIBUTING.md` and link it from the README.
6. Push to `main` before expecting the forms to appear in the GitHub UI.

## Acceptance

- [ ] `gh repo view --json hasIssuesEnabled` reports `true` (when enabled).
- [ ] Selected forms exist and parse as YAML.
- [ ] `.github/ISSUE_TEMPLATE/config.yml` exists.
- [ ] PR template exists when selected.
- [ ] Labels exist on the remote when provisioning was selected and possible;
      otherwise the skip is recorded in the report.
- [ ] `AGENTS.md` (or `CONTRIBUTING.md`) names `github-triage` and states the
      dedupe / verify-before-close / autofix-bridge rules.

## Notes

- Triage *runtime* behavior (dedupe, root cause, test verification, rule linking)
  belongs to `github-triage`, not to this setup feature.
- `AGENTS.md` is the preferred home because it is loaded every session; a
  `CONTRIBUTING.md`-only contract is a degraded setup and must be reported as
  such.
