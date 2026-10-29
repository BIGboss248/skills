---
name: setup-repository
description: >-
  Interviews the user for which repository setup features to enable, then applies
  only those with per-feature runbooks. Triggers on /setup-repository, setup
  repo, or initialize repository.
metadata:
  author: BIGboss248
  version: "2.5"
---

# Setup Repository (Feature-Driven)

Turns repository onboarding into a **menu of independently selectable features**.
Never run a fixed checklist: interview first, execute only what the user enables.

## Contract

- **No writes before selection.** Phase 1 must end with explicit confirmation.
- **Selected only.** Disabled features are reported as `[SKIPPED]` and left untouched.
- **Dependencies are explicit.** If an enabled feature needs a disabled one, ask the user to enable it or accept the documented degraded result.
- **Idempotent.** Re-running merges and updates; never overwrite existing documents or machine-owned blocks.
- **No dummy tests.** Never scaffold placeholder or sample test files in the workspace.

## Phase 1 — Feature Selection Interview (mandatory)

> [!IMPORTANT]
> Present the menu and wait for an answer. Do not infer consent from silence or from a generic "set it up".

### 1.1 Detect first (no questions yet)

Scan `package.json` / `pyproject.toml` / `go.mod`, lockfiles, `.git` and remotes, `gh auth status`, `docker --version`, MCP config, and `.github/`. Only ask about what cannot be detected.

### 1.2 Present the menu

Use [feature-selection-interview.md](./resources/templates/feature-selection-interview.md).

| ID | Feature | Default | Depends on |
| :--- | :--- | :--- | :--- |
| F1 | Project metadata (`docs/project.json`) | on | — |
| F2 | Agent contract (`AGENTS.md` + `.agents/autofix.json`) | on | — |
| F3 | Codebase Memory MCP | on if installed | binary/MCP |
| F4 | Git hooks (Husky + Commitlint + guarded pre-push) | on | Node project |
| F5 | Production Docker (Dockerfile, compose, `.dockerignore`) | off | lockfile |
| F6 | GitHub repository provisioning (create/attach, metadata, topics, docs) | on | `gh` auth |
| F7 | GitHub Issues & triage infrastructure (enable issues, issue forms, PR template, labels) | on | F6, F2 for the logging contract |
| F8 | Release Please (config, manifest, workflow) | on | F6 for effect |
| F9 | Branch protection | off | existing CI check |

### 1.3 Ask in adaptive rounds

1. **Preset** — Minimal (`F1, F2`), Standard (`F1, F2, F4, F6, F7, F8`, plus `F3` when installed), Full (all except `F9` unless a CI check exists), or Custom.
2. **Adjustments** — multi-select overrides; record every add/remove.
3. **Per-feature options** — only for enabled features; each runbook lists its own questions.

### 1.4 Resolve and record

- Check dependencies and confirm any degraded mode.
- Write the canonical selection to `.agents/setup-features.json` using the [schema](./resources/templates/setup-features.schema.json).
- If F1 is enabled, merge `setup_features` into `docs/project.json`.
- Summarize enabled/disabled features and ask for confirmation before Phase 2.

## Phase 2 — Execute Enabled Features

Run in dependency order: **F1 → F2 → F3 → F4 → F5 → F6 → F7 → F8 → F9**.

For each enabled feature:

- [ ] Open its runbook and follow it exactly.
- [ ] Run its acceptance check.
- [ ] Record `[IMPLEMENTED]`, `[BLOCKED]`, or `[SKIPPED]` with a reason.

| Feature | Runbook |
| :--- | :--- |
| F1 Project metadata | [01-project-metadata.md](./references/features/01-project-metadata.md) |
| F2 Agent contract | [02-agent-contract.md](./references/features/02-agent-contract.md) |
| F3 Codebase Memory | [03-codebase-memory.md](./references/features/03-codebase-memory.md) |
| F4 Git hooks | [04-git-hooks.md](./references/features/04-git-hooks.md) |
| F5 Production Docker | [05-docker.md](./references/features/05-docker.md) |
| F6 GitHub repository | [06-github-repository.md](./references/features/06-github-repository.md) |
| F7 GitHub Issues & triage | [07-triage-templates.md](./references/features/07-triage-templates.md) |
| F8 Release Please | [08-release-please.md](./references/features/08-release-please.md) |
| F9 Branch protection | [09-branch-protection.md](./references/features/09-branch-protection.md) |

Do not touch files owned only by disabled features — not even to "prepare" them.

## Phase 3 — Verify

- [ ] Re-run every enabled feature's acceptance check.
- [ ] `git ls-files` contains no `.env*` values, database dumps, or `acme.json`.
- [ ] Reconcile the selection record against the working tree; no feature is half-applied.
- [ ] Confirm each disabled feature was left untouched.

## Phase 4 — Report and Handoff

Produce the report defined at the end of the interview template. It must include:

- the selected preset and the final enabled/disabled list;
- one row per feature with status and reason;
- the exact commands run and their result;
- `git add` / `git commit` commands limited to selected features; leave committing to the user.

## Edge Cases & Common Mistakes

- **F9 before CI** — protection that requires a non-existent check blocks every push. Defer it.
- **F7 labels** — templates work locally; remote labels need an authenticated `gh` and a remote.
- **F6 scaffolding flags** — `gh repo create --license` / `--gitignore` can overwrite existing files.
- **F8 baseline** — without `bootstrap-sha`, Release Please scans history from before the tooling existed.
- **F2 merges** — never delete machine-owned blocks; Next.js rewrites its own `AGENTS.md` section.
- **F3 watchers** — `auto_watch=true` causes editor stutter; keep it off and index on demand.
- **Scope drift** — if the user adds or removes a feature mid-run, reopen Phase 1 and update the record.
