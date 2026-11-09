---
name: setup-repository
description: >-
  Provision repository-level features. Use when initializing a repository, adding
  hooks, issues, releases, CodeQL, Docker, or branch protection.
---

# Repository Setup

A menu of independently selectable repository features. Setup is procedural, so
the phases below are the job.

## Contract

- **No writes before selection.** Phase 1 ends with explicit confirmation.
- **Selected only.** Disabled features are reported `[SKIPPED]` and untouched.
- **Dependencies are explicit.** If a feature needs a disabled one, ask or record
  the degraded result.
- **Idempotent.** Re-running merges; never overwrite existing files.
- **History is the user's.** Stage by path, show the diff, and stop.

## Phase 1 — Feature selection

### 1.1 Detect first

Scan manifests, lockfiles, `.git` and remotes, `gh auth status`,
`docker --version`, `.github/`, and `docs/project.json`. Ask only about what
cannot be detected.

### 1.2 Present the menu

| Id | Feature | Default | Depends on |
| :--- | :--- | :--- | :--- |
| F1 | Project metadata (`docs/project.json`) | on | — |
| F2 | Project contract (`AGENTS.md`, `autofix.json`, standards) | on | — |
| F3 | MCP servers and code intelligence | on if installed | binary/MCP |
| F4 | Git hooks (Husky, commitlint, pre-push) | on | Node project |
| F5 | Production Docker | off | lockfile |
| F6 | GitHub repository provisioning | on | `gh` auth |
| F7 | Issues and triage infrastructure | on | F6, F2 |
| F8 | Release Please | on | F6 |
| F9 | Branch protection | off | existing CI check |
| F11 | Next.js internationalization | off | Next.js App Router, F1 |
| F12 | Planning workflow | on | — |
| F13 | Code scanning (CodeQL, non-blocking) | on for public repos | F6, supported language |

MCP configuration is delegated to `ag-customizer`. Menu details, presets, and
dependency rules: [feature selection interview](./resources/templates/feature-selection-interview.md).

### 1.3 Ask in adaptive rounds

1. **Preset** — Minimal (`F1`, `F2`), Standard, Full, or Custom.
2. **Adjustments** — add or remove explicit ids; record every change.
3. **Per-feature options** — only for enabled features.

### 1.4 Record the selection

- Write `.agents/setup-features.json` from
  [the schema](./resources/templates/setup-features.schema.json).
- When F1 is enabled, merge `setup_features` into `docs/project.json`.
- Summarize and ask for confirmation before Phase 2.

## Phase 2 — Execute enabled features

Order: **F1 → F2 → F3 → F4 → F5 → F6 → F7 → F8 → F13 → F9 → F11 → F12**.

For each feature: open its runbook, follow it, run its acceptance check, and
record `[IMPLEMENTED]`, `[BLOCKED]`, or `[SKIPPED]` with a reason.

| Feature | Runbook |
| :--- | :--- |
| F1 Project metadata | [01-project-metadata](./references/features/01-project-metadata.md) |
| F2 Project contract | [02-agent-contract](./references/features/02-agent-contract.md) |
| F3 MCP servers | [03-mcp-servers](./references/features/03-mcp-servers.md) |
| F4 Git hooks | [04-git-hooks](./references/features/04-git-hooks.md) |
| F5 Production Docker | [05-docker](./references/features/05-docker.md) |
| F6 GitHub repository | [06-github-repository](./references/features/06-github-repository.md) |
| F7 Issues and triage | [07-triage-templates](./references/features/07-triage-templates.md) |
| F8 Release Please | [08-release-please](./references/features/08-release-please.md) |
| F9 Branch protection | [09-branch-protection](./references/features/09-branch-protection.md) |
| F11 Next.js i18n | [11-nextjs-i18n](./references/features/11-nextjs-i18n.md) |
| F12 Planning workflow | [12-planning-workflow](./references/features/12-planning-workflow.md) |
| F13 Code scanning | [13-code-scanning](./references/features/13-code-scanning.md) |

## Phase 3 — Verify

- Re-run each enabled feature's acceptance check.
- `git ls-files` contains no `.env*` values, database dump, or `acme.json`.
- Reconcile the selection against the working tree; nothing is half-applied.
- F13: the workflow has no `pull_request` trigger and no protection entry.
- Every disabled feature is untouched.

## Phase 4 — Report

- Preset, final enabled/disabled list, one row per feature with status and reason.
- The exact commands and results.
- **Stage only.** `git add` the selected paths (never `-A`), show
  `git diff --cached --stat` and the hunks, and propose the commit messages.
- Stop. Commit or push only after explicit approval in this session.

## Definition of Done

- [ ] Selection recorded and confirmed before any write.
- [ ] Every enabled feature implemented and its acceptance check run.
- [ ] Disabled features untouched.
- [ ] No secret committed; no commit made by the agent.
- [ ] The report names deferred or degraded items.

## Edge Cases & Pitfalls

- **F9 before CI** — protection requiring a non-existent check blocks every push.
- **F13 as a gate** — adding it to required checks turns a notification into a
  blocker. Ship it non-blocking, with a notify job.
- **F13 `continue-on-error` at job level** — flattens the result; the notifier
  never fires.
- **F13 on a private repo without Code Security** — report `[BLOCKED]`; disable a
  scaffolded workflow that can only fail.
- **F13 unsupported language** — Dart/Flutter, PHP, and Elixir scan nothing.
- **F6 scaffolding flags** — `--license` / `--gitignore` can overwrite files.
- **F7 labels** — templates work locally; remote labels need `gh` and a remote.
- **F8 baseline** — without `bootstrap-sha`, Release Please scans older history.
- **F2 merges** — never delete machine-owned blocks.
- **F3 selection** — ask with a recommendation; never enable every server.
- **F11 double scaffolding** — if `nextjs-dev-setup` already ran, verify and
  report `[UNTOUCHED]`.
- **F11 interceptor** — Next.js 16 uses `proxy.ts`, earlier versions
  `middleware.ts`; keeping both double-redirects.
- **F11 document shell** — `<html>` and `<body>` live only in the locale layout.
- **F11 dictionary drift** — a locale in routing without a matching dictionary
  fails the build.
- **F12 plan drift** — amend in place (`A1`, `P2.1a`); never renumber.
- **F12 planning is not authorization** — approval gates still apply.

## References

- [Feature selection interview](./resources/templates/feature-selection-interview.md)
- [MCP server catalog](./references/mcp-server-catalog.md)
- [Feature runbooks](./references/features/)
- [Templates](./resources/templates/)
