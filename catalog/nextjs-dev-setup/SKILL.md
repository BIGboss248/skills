---
name: nextjs-dev-setup
description: >-
  Bootstrap a Next.js development environment. Use when initializing a project,
  or adding i18n, theming, testing, Storybook, Docker, or CI/CD.
---

# Next.js Environment Setup

Turns repository onboarding into a **menu of independently selectable features**.
Setup is procedural, so the sequence below is the job.

## Contract

- **No writes before selection.** Phase 1 ends with explicit confirmation.
- **Selected only.** Disabled features are reported `[SKIPPED]` and left
  untouched.
- **Dependencies are explicit.** If a feature needs a disabled one, ask or record
  the degraded result.
- **Idempotent.** Re-running merges and updates; never overwrite existing
  documents or machine-owned blocks.
- **No dummy tests.** Never scaffold placeholder or sample test files.
- **History is the user's.** Never commit or push. Stage the selected features,
  show the diff, and stop.

## Phase 1 — Feature selection interview

### 1.1 Detect first

Scan manifests and lockfiles, `app/` vs `src/app/`, `.git` and remotes, `gh auth
status`, `docker --version`, MCP config, and `.github/`. Ask only about what
cannot be detected.

### 1.2 Present the menu

| Id | Feature | Default | Depends on |
| :--- | :--- | :--- | :--- |
| N1 | Project metadata (`docs/project.json`) | on | — |
| N2 | Framework core and app shell | on | — |
| N3 | App icons and PWA manifest | on | N2 |
| N4 | Internationalization (`next-intl`) | on | N2 |
| N5 | Jest unit testing | on | N2 |
| N6 | Playwright E2E | on | N2 |
| N7 | Storybook | off | N2 |
| N8 | Design-system lint | on | N2 |
| N13 | Theming and dark mode | on | N2 |
| N11 | Production Docker and reverse proxy | off | N2 |
| N12 | Git hooks and CI/CD | on | N2, N5/N6 for the gate |

Menu, presets, and dependency resolution:
[feature selection interview](./resources/templates/feature-selection-interview.md).

### 1.3 Ask in adaptive rounds

1. **Preset** — Minimal (`N1`, `N2`), Standard, Full, or Custom.
2. **Adjustments** — keep or drop categories, then add or remove explicit ids.
   Record every change.
3. **Per-feature options** — only for enabled features. Question sets live in
   [setup interview rounds](./references/setup-interview-rounds.md) and each
   runbook under [features](./references/features/).

### 1.4 Record the selection

- Resolve dependencies; confirm each degraded mode explicitly.
- Write `.agents/nextjs-setup-features.json` from
  [the schema](./resources/templates/nextjs-setup-features.schema.json).
- When N1 is enabled, merge `nextjs_setup_features` into `docs/project.json`.
- Present the confirmation block and wait.

## Phase 2 — Execute enabled features

Order: **N1 → N2 → N3 → N4 → N5 → N6 → N7 → N8 → N13 → N11 → N12**.

For each enabled feature: generate one `implementation_plan.md` before the first
write, open its runbook, follow it, run its acceptance check, and record
`[IMPLEMENTED]`, `[UNTOUCHED]`, `[SKIPPED]`, or `[BLOCKED]` with a reason.

| Feature | Runbook |
| :--- | :--- |
| N1 Project metadata | [01-project-metadata](./references/features/01-project-metadata.md) |
| N2 Framework core | [02-framework-core](./references/features/02-framework-core.md) |
| N3 Icons and PWA | [03-app-icons-pwa](./references/features/03-app-icons-pwa.md) |
| N4 Internationalization | [04-internationalization](./references/features/04-internationalization.md) |
| N5 Jest | [05-jest-unit-testing](./references/features/05-jest-unit-testing.md) |
| N6 Playwright | [06-playwright-e2e](./references/features/06-playwright-e2e.md) |
| N7 Storybook | [07-storybook](./references/features/07-storybook.md) |
| N8 Design-system lint | [08-design-system-lint](./references/features/08-design-system-lint.md) |
| N13 Theming | [13-theming](./references/features/13-theming.md) |
| N11 Docker and proxy | [11-docker-reverse-proxy](./references/features/11-docker-reverse-proxy.md) |
| N12 Git hooks and CI/CD | [12-git-hooks-cicd](./references/features/12-git-hooks-cicd.md) |

Do not touch files owned only by disabled features — not even to "prepare" them.
MCP server configuration is owned by `ag-customizer`, not this skill.

## Phase 3 — Verify

- Run the selection-aware verifier, or walk each enabled runbook's acceptance
  list when the script is unavailable:
  `pwsh ./scripts/verify-project-config.ps1` /
  `bash ./scripts/verify-project-config.sh`.
- It reads `.agents/nextjs-setup-features.json` (falling back to
  `docs/project.json → nextjs_setup_features`) and reports unchecked features as
  `SKIPPED`. `--all` audits the whole repository.
- Fix reported errors and re-verify until the enabled set is clean.
- Confirm disabled features were left untouched.

A setup gate proves configuration exists, not that the app builds or runs; those
checks belong to `tdd`, `code-review`, and the repository's own hooks.

## Phase 4 — Report

- One row per feature, enabled and disabled, with status and reason.
- The exact commands run and their results.
- `git add` commands limited to selected features; committing is the user's.
- Next steps: dev server, first page, pending features.

## Definition of Done

- [ ] Selection recorded and confirmed before any write.
- [ ] Every enabled feature implemented and its acceptance check run.
- [ ] Disabled features untouched and reported `[SKIPPED]`.
- [ ] No dummy test, no secret, no commit.
- [ ] The report names deferred or degraded items.

## Edge Cases & Pitfalls

- **Outdated Next.js context** — query the installed docs, never memory.
- **Version pinning** — install `next@latest react@latest react-dom@latest`
  unless the project pins deliberately.
- **Chained commands** — run them separately.
- **Overwrites** — compose `next.config.*` and provider files; N4, N6, and N11
  all add keys to the same config.
- **Double scaffolding** — if i18n already exists, verify and report
  `[UNTOUCHED]`; rewriting loses route migrations.
- **Docker names** — OCI image names must be lowercase.
- **Test gate** — never point pre-push at a script that does not exist; degrade
  to lint and record it.
- **Release gate** — keep `release` and image jobs in one workflow and publish
  only when `needs.release.outputs.released == 'true'`.
- **Component mismatch** — with `include-component-in-tag: false`, keep
  `package-name: ""` in the release config.
- **Expensive tier** — pre-push is the only local execution point for Playwright
  and the full Jest project.
- **Storybook i18n** — wrap stories with the intl provider; no global progress
  bar, use `useLinkStatus`.
- **Theme parity** — the Storybook decorator must use the same strategy as the
  app (class vs data attribute), or stories lie.

## References

- [Setup interview rounds](./references/setup-interview-rounds.md)
- [Project JSON schema](./references/project-json-schema.md)
- Agent worktree policy — owned by the `git-worktree-isolation` skill
- [Feature runbooks](./references/features/)
- [Templates](./resources/templates/)
