---
name: codeql
description: >-
  Set up and troubleshoot CodeQL code scanning. Use when adding a scan workflow,
  running the CodeQL CLI, interpreting SARIF, or fixing a failing analysis.
---

# CodeQL Code Scanning

How scanning is configured and read. This skill owns the scan configuration only.

## Choose the setup

| Setup | Use when | Trade-off |
| :--- | :--- | :--- |
| Default setup | First scan, standard languages | No control over triggers, queries, or matrix |
| Advanced setup (`codeql.yml`) | Monorepo, compiled languages, custom queries, category control | You own the workflow |

Switching to advanced requires disabling default setup first.

## Supported languages

`c-cpp`, `csharp`, `go`, `java-kotlin`, `javascript-typescript`, `python`,
`ruby`, `rust`, `swift`, `actions`.

- Alternatives are equivalent: `javascript` also analyzes TypeScript.
- Dart/Flutter, PHP, and Elixir are not supported; do not scaffold a workflow
  that scans nothing.

## Workflow essentials

- **Triggers:** `push` to protected branches, `schedule` on the default branch,
  `merge_group` when merge queues exist. A `pull_request` trigger makes the check
  block merges; omit it when the scan is advisory.
- **Permissions:** `security-events: write`, `contents: read`, `actions: read`.
- **Build mode:** `none` for interpreted and some compiled languages,
  `autobuild`, or `manual` for custom build commands.
- **Queries:** `security-extended` by default; `security-and-quality` when the
  repo wants quality findings too.
- **Category:** one per language or component so a monorepo can tell SARIF
  results apart.
- **Caching:** enable dependency caching to cut run time.
- Full workflow reference:
  [workflow configuration](./references/workflow-configuration.md).

## CLI essentials

The CLI path exists for local analysis and for `github upload-results` when
Actions is unavailable.

- Create, analyze, and upload are three separate commands.
- A database is language-specific; a monorepo needs one per language.
- SARIF is only useful when the rule id and the code location resolve.
- Command reference: [CLI commands](./references/cli-commands.md).
- Output shape: [SARIF](./references/sarif-output.md).

## Alerts

- Triage by severity and reachability, not by count.
- A dismissed alert needs a reason: false positive, used in tests, or accepted
  risk.
- Fix the class of defect, not the single finding, when the same rule repeats.
- Re-run after a fix; an alert closed without a run is an assumption.

## Definition of Done

- [ ] The language matrix matches the repository and its build.
- [ ] Permissions are least-privilege and the upload step can write.
- [ ] Triggers match the intent: advisory scan or merge gate.
- [ ] A run completed and SARIF uploaded, or the reason it could not run is
      stated.
- [ ] Alerts are triaged with reasons, not bulk-dismissed.
- [ ] No workflow added as a required check unless blocking is intended.

## Edge Cases & Pitfalls

- **Compiled language without a build** — analysis silently finds nothing.
- **Monorepo category collision** — results overwrite each other without
  distinct `category` values.
- **Required check on a partial repo** — protection that requires a context that
  never runs blocks every push.
- **Schedule on a non-default branch** — cron only fires from the default branch.
- **`paths-ignore` confusion** — it skips the whole run, not the analyzed files.
- **Private repository without Code Security** — scanning is not free; report it
  instead of scaffolding a workflow that can only fail.
- **Job-level `continue-on-error`** — flattens the result so downstream
  notification never fires.

## References

- [Workflow configuration](./references/workflow-configuration.md)
- [Compiled languages](./references/compiled-languages.md)
- [CLI commands](./references/cli-commands.md)
- [SARIF output](./references/sarif-output.md)
- [Troubleshooting](./references/troubleshooting.md)
