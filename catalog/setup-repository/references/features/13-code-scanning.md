# F13 — Code scanning (CodeQL, non-blocking)

## Enable when

The repository is **publicly visible** (free) or has **GitHub Code Security**
licensed, has a **CodeQL-supported language**, and the user wants a security
signal without a merge gate. All of these must hold:

- **public visibility, or a GitHub Code Security licence.** GitHub only processes
  code scanning on private repositories when that licence is present — the
  advanced-setup prerequisite is literally "it is publicly visible, or GitHub
  Code Security is enabled";
- a supported language is present — see the identifier table in
  [`codeql/SKILL.md`](../../../codeql/SKILL.md);
- the workflow can run on GitHub-hosted runners (or a self-hosted runner with
  ≥8 GB RAM for small codebases).

**Skip** for Dart/Flutter, PHP, Elixir, and any other language outside the
CodeQL list. `pubspec.yaml` alone is not a reason to enable this feature.

**Skip and disable** on a private repository without GitHub Code Security: a
workflow there can only fail at the SARIF upload. If
`.github/workflows/codeql.yml` already exists, disable it
(`gh workflow disable <id>`) and record why — a permanently red check is worse
than no check.

Default: **on for public repositories and for licensed private ones**, off
otherwise. Code scanning is still opt-in per feature selection, and a
non-blocking scan is only worth its Actions minutes when the user asked for it.

## Questions

1. **Languages.** Confirm the auto-detected set (lockfiles → language id). Only
   ask about the compiled languages, where the build mode is a real choice.
2. **Notification channel on failure.** Tracking issue (default), step summary
   only, or both? Issue-only needs Issues enabled (F7); step summary always
   works.
3. **Compiled languages only** — `none`, `autobuild`, or `manual`? Default
   `autobuild`; `none` where the language supports it.
4. **Query suite** — `security-extended` (default) or `security-and-quality`
   (adds code-quality queries, slower).
5. **Triggers** — push to default branch + weekly schedule (default), plus
   release-time scan, plus manual dispatch? `pull_request` is never offered.
6. **Install the `codeql` skill** next to the workflow (default: yes)? It makes
   the next session able to explain the SARIF, fix extraction failures, and run
   the CLI without re-deriving this configuration.

## Steps

1. **Confirm visibility first, then the licence.** Code scanning is free on
   public repositories and licensed on private ones:

   ```bash
   gh repo view <owner>/<repo> --json visibility --jq '.visibility'
   gh api repos/<owner>/<repo> --jq '.security_and_analysis'
   ```

   - `PUBLIC` → free; continue.
   - `PRIVATE` and `security_and_analysis` is not `null` (code scanning
     configured) → licensed; continue.
   - `PRIVATE` and `security_and_analysis: null` → report `[BLOCKED]`, name the
     GitHub Code Security licence requirement, and stop. Do not scaffold a
     workflow that can only fail. If a `CodeQL` workflow already exists —
     because the repository used to be public, or a licence lapsed — disable it
     (`gh workflow disable <id>`) and record `[DISABLED]` with the reason.

2. **Detect and confirm languages.** Map lockfiles to identifiers:
   `package.json` → `javascript-typescript`, `pyproject.toml`/`requirements.txt`
   → `python`, `go.mod` → `go`, `Cargo.toml` → `rust`, `*.csproj` → `csharp`,
   `pom.xml`/`build.gradle` → `java-kotlin`, `Package.swift` → `swift`,
   `CMakeLists.txt`/`Makefile` → `c-cpp`, `.github/workflows/` only → `actions`.
   Record unsupported languages as `[SKIPPED]` with the reason.
3. **Check for default setup** and disable it before committing an advanced
   workflow. Two enabled setups split results and double-scan:

   ```bash
   gh api repos/<owner>/<repo>/code-scanning/default-setup --jq '.state'
   ```

   - `not-configured` → continue.
   - `configured` → ask the user: keep default setup (deploy nothing, report
     `[UNTOUCHED]`) or switch to advanced
     (`gh api -X PATCH repos/<owner>/<repo>/code-scanning/default-setup -f state=not-configured`).
     Only the second path deploys the template.
4. **Deploy the workflow** from
   [codeql.yml.template](../../resources/templates/codeql.yml.template) to
   `.github/workflows/codeql.yml`. Replace the matrix `include` list with the
   confirmed languages and build modes. Change nothing in the trigger block —
   the missing `pull_request` trigger is the feature.
5. **Wire the notifier.**
   - Issue channel → create the labels it uses when F7 provisioned labels:
     `gh label create security --color D73A4A`, `gh label create codeql --color 0E8A16`.
     The workflow already falls back to filing without labels when they are
     missing.
   - Step-summary only, or Issues disabled → set the repository variable so the
     notifier skips the issue step:
     `gh variable set CODEQL_OPEN_ISSUE --body false`.
6. **Deploy the `codeql` skill** when question 6 is accepted. Copy from the
   skills vault, not from the network:
   - Source of truth: `skills/codeql/` (7 files: `SKILL.md` plus
     `references/{workflow-configuration,cli-commands,sarif-output,compiled-languages,troubleshooting,alert-management}.md`).
   - Target: `skills/codeql/` in the destination repository.
   - **Merge, never overwrite.** Keep local edits, add only missing files, and
     record the divergence in `.agents/setup-features.json` under `notes`.
   - If the vault copy is missing, refresh it with
     `gh skills install github/awesome-copilot codeql`, then verify
     `skills/codeql/SKILL.md` declares `name: codeql` before copying. Report
     `[BLOCKED]` rather than deploying a half-skill.
7. **Add the code-scanning section to `AGENTS.md`** (F2) from the "Code scanning
   (`codeql` skill)" section of
   [AGENTS.md.template](../../resources/templates/AGENTS.md.template). It states
   the contract:
   - the CodeQL workflow is a signal, never a gate — do not add it to required
     checks, rulesets, or a release gate;
   - alert findings are **not** GitHub issues: they live in the Security tab and
     do not enter the `github-triage` dedupe loop;
   - dismissal requires a documented reason in the alert, and the `security` /
     `codeql` labels belong to analysis-failure issues only;
   - the `codeql` skill is the mandatory skill for CodeQL workflow edits, SARIF
     interpretation, and extraction failures.
8. **Do not touch F9 automatically.** Record the produced check name(s)
   (`Analyze (<language>)`) under `notes.F9` so a later run can require them —
   but see the deferral rule in [09-branch-protection.md](./09-branch-protection.md).

## Acceptance

- [ ] `.github/workflows/codeql.yml` parses as YAML and its matrix matches the
      confirmed languages.
- [ ] The workflow has **no** `pull_request` trigger.
- [ ] `gh api repos/<owner>/<repo>/branches/<default>/protection` does not list
      a CodeQL context (when F9 is configured).
- [ ] **Visibility gate honoured:** a public repository deploys the workflow; a
      private repository without GitHub Code Security reports `[BLOCKED]`, and
      `gh workflow list --all` shows either no `CodeQL` workflow or one in
      `disabled_manually` state.
- [ ] Labels `security` and `codeql` exist, or `CODEQL_OPEN_ISSUE=false` is set.
- [ ] `skills/codeql/SKILL.md` exists with `name: codeql` and every reference
      link resolves (when question 6 was accepted).
- [ ] `AGENTS.md` contains the code-scanning contract from step 7.
- [ ] After the first run: `gh api repos/<owner>/<repo>/code-scanning/alerts --jq 'length'`
      returns a number for every analyzed language — an empty set with no
      analysis is a silent misconfiguration, not a clean result.
- [ ] Failure-path smoke test on a scratch branch: temporarily set the matrix
      `language` to `bogus`, push, and confirm the `notify` job runs, the step
      summary renders, and one issue appears with the `codeql` label. Revert,
      then confirm a second simulated failure **comments** on that issue instead
      of opening a duplicate.

## Notes

- **"Non-blocking" is three concrete properties**, not a label: no
  `pull_request` trigger, no required-check entry, no release/deployment gate.
  Dropping any one of them re-blocks the repository. The run going red is
  intended — a failing scan that nobody hears about is a scan that does not
  exist.
- **Alerts never fail the action.** `github/codeql-action/analyze` exits non-zero
  on extraction, build, or upload errors — not on findings. How findings are
  treated is set by PR checks and rulesets, which is exactly what F13 declines to
  configure.
- **`continue-on-error` is the wrong tool** at job level: it flattens
  `needs.analyze.result` to `success` and the notifier silently stops firing.
  Let the analyze job fail and let `notify` react.
- **Notification spam.** The notifier dedupes on the fixed title
  `CodeQL analysis failed` and comments on the open issue instead of opening a
  second one. Renaming that title breaks dedupe.
- **`paths-ignore` is not scoping.** It only decides whether the workflow runs on
  a docs-only push; it does not exclude files from analysis. Directory scoping
  needs `.github/codeql/codeql-config.yml` with `paths:` / `paths-ignore:` and
  `config-file:` on the `init` step.
- **Private repositories** are the whole gate: code scanning needs **GitHub Code
  Security** there (public repositories are free), the analyze job needs
  `actions: read`, and every scheduled run bills Actions minutes. If a repository
  moves from public to private and the licence is missing, the SARIF upload
  returns HTTP 403 — disable the workflow (`gh workflow disable <id>`) and record
  `[DISABLED]` rather than shipping a check that can only fail.
- **Never chain F13 into the quality gate.** It is a standalone workflow; keep it
  out of another workflow's `needs:` and out of the Release Please dependency
  chain. A scanner outage must not block a merge or a release.
- **Release-time scans** are additive. `release: published` adds a scan of the
  released commit; it does not make the release wait for the scan, and it must
  never be wired into the Release Please job.
- **Monorepos** need one `category` per component
  (`/language:<lang>/component:<name>`) or the SARIF results overwrite each
  other and the alert list lies.
- **Default setup is the cheaper path** when the user wants zero maintenance and
  accepts no code in the repository. It also scans on pull requests by default,
  so it is *not* equivalent to this feature — say that out loud when offering it.
