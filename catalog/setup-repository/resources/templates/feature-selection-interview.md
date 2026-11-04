# Feature Selection Interview

Present this structure verbatim, adapted with detected values. Ask in rounds and
stop after each round; do not dump every question at once.

---

## 1. Detected context (no questions)

```text
Stack:            <detected framework / runtime>
Package manager:  <lockfile → pnpm|npm|yarn|bun>
Git remote:       <origin URL or "none">
GitHub CLI:       <authenticated as … | not authenticated | not installed>
Docker:           <version | not installed>
Codebase Memory:  <MCP registered | binary installed | unavailable>
MCP servers:      <registered servers or "none">
Existing files:   <AGENTS.md, docs/project.json, .github/, Dockerfile, .husky/ …>
```

## 2. Feature menu

| ID | Feature | Default | Depends on |
| :--- | :--- | :--- | :--- |
| F1 | Project metadata (`docs/project.json`) | on | — |
| F2 | Agent contract (`AGENTS.md`, `.agents/autofix.json`, engineering standards) | on | — |
| F3 | MCP servers (ask + recommend) & Codebase Memory | on if installed | binary/MCP |
| F4 | Git hooks (Husky + Commitlint + guarded pre-push) | on | Node project |
| F5 | Production Docker (Dockerfile, compose, `.dockerignore`) | off | lockfile |
| F6 | GitHub repository provisioning (create/attach, metadata, topics, docs) | on | `gh` auth |
| F7 | GitHub Issues & triage infrastructure (enable issues, issue forms, PR template, labels) | on | F6, F2 for the logging contract |
| F8 | Release Please (config, manifest, workflow) | on | F6 for effect |
| F9 | Branch protection | off | existing CI check |
| F10 | Code review gate (`reviewer` subagent + report standard) | on | F2 |
| F11 | Next.js internationalization (`next-intl`, locale routing, dictionaries) | off | Next.js App Router project, F1 |
| F12 | Planning workflow (`plan` skill + `/plan` command) | on | — |

## 3. Round 1 — Preset

> Which preset should I use?
> **Minimal** (F1, F2) · **Standard** (F1, F2, F4, F6, F7, F8, F10, F12, plus F3 when installed) · **Full** (all except F9 unless a CI check exists, plus F11 for Next.js App Router projects) · **Custom**

## 4. Round 2 — Adjustments

> Here is the Standard selection. Which features should I add or remove?
> <re-list the enabled set with one-line descriptions>

Resolve every removal of a dependency:

- F7 without F6 → templates only; labels skipped.
- F8 without F6 → files created, no release PR until a remote exists.
- F9 without a CI check → recommend deferring and record the reason.
- F10 without F2 → the reviewer still runs, but it cannot cite the engineering standards; record the degraded mode.
- F11 without F1 → scaffold the infrastructure and record the locale/dictionary intent in `.agents/setup-features.json`; the `docs/project.json` keys are added when F1 is enabled.
- F11 on a non-Next.js or Pages Router project → out of scope; report `[SKIPPED]`.
- F11 after `nextjs-dev-setup` already scaffolded `next-intl` → verify only and report `[UNTOUCHED]`.
- F12 without F2 → the skill and `/plan` command still work; the `AGENTS.md` planning section is skipped and the convention is recorded only in `.agents/setup-features.json`.

## 5. Round 3 — Per-feature options (enabled only)

Ask only the questions for enabled features; each runbook lists them. Examples:

- **F3**: which MCP servers does this repo need (present the recommendation from `references/mcp-server-catalog.md`); install codebase-memory if missing, or wire workspace-only?
- **F4**: pre-push gate — `test:all`, lint only, or no test gate?
- **F5**: app image only, compose too, and which port?
- **F6**: create a new repo or attach the existing one; visibility; confirm suggested topics; which documents to generate?
- **F7**: enable GitHub Issues on the remote? bug form only, or bug + feature + PR template? provision labels? contact links?
- **F8**: release type, initial version, package name, changelog path.
- **F9**: team or solo; which CI check name; require reviews?
- **F10**: install `/review`? which base branch do reviews compare against? archive reports under `docs/reviews/`?
- **F11**: which locales and default locale; locale prefix `always` or `as-needed`; migrate existing routes into `app/[locale]/` now or later; which locales render right-to-left?
- **F12**: plan location (`docs/plan/<slug>.md` or a single `PLAN.md`); commit plans? install `/plan`? stop after every phase or only at the end?

## 6. Confirmation

```markdown
### Setup Selection

| Feature | Status |
| :--- | :--- |
| F1 Project metadata | ENABLED |
| F2 Agent contract | ENABLED |
| F3 MCP servers & Codebase Memory | ENABLED |
| F4 Git hooks | ENABLED |
| F5 Production Docker | DISABLED |
| F6 GitHub repository | ENABLED |
| F7 Triage infrastructure | ENABLED |
| F8 Release Please | ENABLED |
| F9 Branch protection | DISABLED (no CI check yet) |
| F10 Code review gate | ENABLED |
| F11 Next.js i18n | DISABLED (single locale) |
| F12 Planning workflow | ENABLED |

Preset: Standard
Degraded: none
Proceed with these features? (yes / adjust)
```

## 7. Execution report template

```markdown
## 🛠️ Repository Setup Execution Report

| Feature | Target files / resources | Status | Notes |
| :--- | :--- | :--- | :--- |
| F1 Project metadata | `docs/project.json` | `[IMPLEMENTED]` / `[SKIPPED]` / `[BLOCKED]` | … |
| F2 Agent contract | `AGENTS.md`, `.agents/autofix.json`, `.agents/rules/engineering-standards.md` | … | … |
| F3 MCP servers & Codebase Memory | `mcp.json`, `.cbmignore`, AGY configs, `docs/project.json` | … | accepted servers: … |
| F4 Git hooks | `.husky/*`, `commitlint.config.mjs` | … | … |
| F5 Docker | `Dockerfile`, `docker-compose*.yml`, `.dockerignore` | … | … |
| F6 GitHub repository | remote, topics, `README.md`, docs | … | … |
| F7 GitHub Issues & triage | `.github/ISSUE_TEMPLATE/*`, `PULL_REQUEST_TEMPLATE.md`, labels, issue-logging contract | … | … |
| F8 Release Please | `release-please-config.json`, manifest, workflow | … | … |
| F9 Branch protection | branch rules / recorded deferral | … | … |
| F10 Code review gate | `.opencode/agents/reviewer.md`, `.agents/rules/code-review-report.md`, `.opencode/commands/review.md`, `AGENTS.md` | … | base branch: … |
| F11 Next.js i18n | `i18n/routing.ts`, `i18n/request.ts`, `i18n/navigation.ts`, `proxy.ts`/`middleware.ts`, `app/[locale]/layout.tsx`, `messages/<locale>.json`, `global.d.ts`, `docs/project.json` | … | locales: … |
| F12 Planning workflow | `skills/plan/`, `.opencode/commands/plan.md`, `AGENTS.md` | … | plan location: … |

Preset: <preset>
Verification: <commands and result per enabled feature>
```

Then output `git add` and `git commit` commands limited to the selected files,
and leave committing to the user.
