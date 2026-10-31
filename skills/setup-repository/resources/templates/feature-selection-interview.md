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
| F2 | Agent contract (`AGENTS.md` + `.agents/autofix.json`) | on | — |
| F3 | MCP servers (ask + recommend) & Codebase Memory | on if installed | binary/MCP |
| F4 | Git hooks (Husky + Commitlint + guarded pre-push) | on | Node project |
| F5 | Production Docker (Dockerfile, compose, `.dockerignore`) | off | lockfile |
| F6 | GitHub repository provisioning (create/attach, metadata, topics, docs) | on | `gh` auth |
| F7 | GitHub Issues & triage infrastructure (enable issues, issue forms, PR template, labels) | on | F6, F2 for the logging contract |
| F8 | Release Please (config, manifest, workflow) | on | F6 for effect |
| F9 | Branch protection | off | existing CI check |

## 3. Round 1 — Preset

> Which preset should I use?
> **Minimal** (F1, F2) · **Standard** (F1, F2, F4, F6, F7, F8, plus F3 when installed) · **Full** (all except F9 unless a CI check exists) · **Custom**

## 4. Round 2 — Adjustments

> Here is the Standard selection. Which features should I add or remove?
> <re-list the enabled set with one-line descriptions>

Resolve every removal of a dependency:

- F7 without F6 → templates only; labels skipped.
- F8 without F6 → files created, no release PR until a remote exists.
- F9 without a CI check → recommend deferring and record the reason.

## 5. Round 3 — Per-feature options (enabled only)

Ask only the questions for enabled features; each runbook lists them. Examples:

- **F3**: which MCP servers does this repo need (present the recommendation from `references/mcp-server-catalog.md`); install codebase-memory if missing, or wire workspace-only?
- **F4**: pre-push gate — `test:all`, lint only, or no test gate?
- **F5**: app image only, compose too, and which port?
- **F6**: create a new repo or attach the existing one; visibility; confirm suggested topics; which documents to generate?
- **F7**: enable GitHub Issues on the remote? bug form only, or bug + feature + PR template? provision labels? contact links?
- **F8**: release type, initial version, package name, changelog path.
- **F9**: team or solo; which CI check name; require reviews?

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
| F2 Agent contract | `AGENTS.md`, `.agents/autofix.json` | … | … |
| F3 MCP servers & Codebase Memory | `mcp.json`, `.cbmignore`, AGY configs, `docs/project.json` | … | accepted servers: … |
| F4 Git hooks | `.husky/*`, `commitlint.config.mjs` | … | … |
| F5 Docker | `Dockerfile`, `docker-compose*.yml`, `.dockerignore` | … | … |
| F6 GitHub repository | remote, topics, `README.md`, docs | … | … |
| F7 GitHub Issues & triage | `.github/ISSUE_TEMPLATE/*`, `PULL_REQUEST_TEMPLATE.md`, labels, issue-logging contract | … | … |
| F8 Release Please | `release-please-config.json`, manifest, workflow | … | … |
| F9 Branch protection | branch rules / recorded deferral | … | … |

Preset: <preset>
Verification: <commands and result per enabled feature>
```

Then output `git add` and `git commit` commands limited to the selected files,
and leave committing to the user.
