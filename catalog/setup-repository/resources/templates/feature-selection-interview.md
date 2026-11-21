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
Project scope:    <present | missing (gh auth refresh -s project)>
Docker:           <version | not installed>
Codebase Memory:  <MCP registered | binary installed | unavailable>
MCP servers:      <registered servers or "none">
Existing files:   <AGENTS.md, docs/project.json, .github/, Dockerfile, .husky/ …>
```

## 2. Feature menu

| ID | Feature | Default | Depends on |
| :--- | :--- | :--- | :--- |
| F1 | Project metadata (`docs/project.json`) | on | — |
| F2 | Agent contract (`AGENTS.md`, `.agents/autofix.json`, engineering standards, code-search instruction, output provenance footer) | on | — |
| F3 | MCP servers (ask + recommend) & Codebase Memory | on if installed | binary/MCP |
| F4 | Git hooks (Husky + Commitlint + guarded pre-push) | on | Node project |
| F5 | Production Docker (Dockerfile, compose, `.dockerignore`) | off | lockfile |
| F6 | GitHub repository provisioning (create/attach, metadata, topics, docs) | on | `gh` auth |
| F7 | GitHub Issues & triage infrastructure (enable issues, issue forms, PR template, labels) | on | F6, F2 for the logging contract |
| F8 | Release Please (config, manifest, workflow) | on | F6 for effect |
| F9 | Branch protection | off | existing CI check |
| F10 | Code review gate (`reviewer` subagent + report standard) | on | F2 |
| F11 | Next.js internationalization (`next-intl`, locale routing, dictionaries) | off | Next.js App Router project, F1 |
| F12 | Planning workflow (`to-spec` -> `to-tickets`) | on | — |
| F13 | Code scanning (CodeQL, **non-blocking** — notifies on failure, never gates) | on for public repositories (off on private without GitHub Code Security) | F6, public visibility or a Code Security licence, a CodeQL-supported language |
| F14 | GitHub Project board (auto-add issues/PRs, Status → Done on close) | on if the `project` scope is present | F6, `project` token scope |
| F15 | README badges (CI validation workflow status + latest release version) | on | F6, a committed CI workflow, F8 for the version |

## 3. Round 1 — Preset

> Which preset should I use?
> **Minimal** (F1, F2) · **Standard** (F1, F2, F4, F6, F7, F8, F10, F12, F14, F15, plus F3 when installed and F13 when the repository is public with a CodeQL-supported language) · **Full** (all except F9 unless a CI check exists, plus F11 for Next.js App Router projects and F13 when a supported language is present) · **Custom**

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
- F12 without F2 → the planning skills still work; the `AGENTS.md` planning section is skipped and the convention is recorded only in `.agents/setup-features.json`.
- F13 without F6 → no remote, so no workflow can run; deploy the files and record that the first scan waits for a push.
- F13 without F7 (or with Issues disabled) → the notifier posts to the step summary only; set `CODEQL_OPEN_ISSUE=false`.
- F13 on a private repo without GitHub Code Security → `[BLOCKED]`; report the
  licence requirement, deploy nothing, and disable any existing `CodeQL`
  workflow (`gh workflow disable <id>`) instead of leaving a permanent red check.
- F13 on a public repo → free to run; no licence needed.
- F13 on an unsupported language (Dart/Flutter, PHP, Elixir) → `[SKIPPED]` with the reason.
- F13 and F9 both enabled → F13 runs first and publishes the check name, but F9 still defers until that check has reported once.
- F14 without F6 → no remote to link; create the project and record that the link, the auto-add filter, and the Actions job all wait for the first push.
- F14 without F7 (or with Issues disabled) → the board still collects pull requests; record that only PRs arrive.
- F14 without the `project` token scope → `[BLOCKED]`; print `gh auth refresh -s project,read:project` and stop.
- F14 native mode → the auto-add workflow has no API; hand it off with the exact UI steps and report `[MANUAL]`.
- F14 headless mode without a PAT → `[BLOCKED]` at the workflow step; report that the `PROJECT_TOKEN` secret is the missing input.
- F15 without F6 → no remote, so both badge URLs point at nothing; write the block with placeholders only if the user will create the remote, else `[SKIPPED]`.
- F15 without F8 → CI badge only; report the release badge as deferred until the first tag exists.
- F15 without a CI workflow → the CI badge cannot resolve; either point it at the workflow that will run the gate or ship the release badge alone.
- F15 on a private repository → badges render `unknown` for anonymous readers; `[BLOCKED]` with the visibility as the reason, or defer until the repo is public.

## 5. Round 3 — Per-feature options (enabled only)

Ask only the questions for enabled features; each runbook lists them. Examples:

- **F2**: which stack-specific mandatory skills apply; deploy the engineering standards baseline? keep the codebase-memory MCP code-search instruction? install the output provenance footer (skills + MCP servers used) on every response?
- **F3**: which MCP servers does this repo need (present the recommendation from `references/mcp-server-catalog.md`); install codebase-memory if missing, or wire workspace-only?
- **F4**: pre-push gate — `test:all`, lint only, or no test gate?
- **F5**: app image only, compose too, and which port?
- **F6**: create a new repo or attach the existing one; visibility; confirm suggested topics; which documents to generate?
- **F7**: enable GitHub Issues on the remote? bug form only, or bug + feature + PR template? provision labels? contact links?
- **F8**: release type, initial version, package name, changelog path.
- **F9**: team or solo; which CI check name; require reviews?
- **F10**: install `/review`? which base branch do reviews compare against? archive reports under `docs/reviews/`?
- **F11**: which locales and default locale; locale prefix `always` or `as-needed`; migrate existing routes into `app/[locale]/` now or later; which locales render right-to-left?
- **F12**: spec location (tracker or `.scratch/<slug>/issues/`); commit specs? stop after every ticket or only at the end?
- **F13**: confirm repository visibility (public = free; private needs GitHub Code Security) and the detected languages; failure notification (tracking issue / step summary only / both); build mode for compiled languages; query suite (`security-extended` or `security-and-quality`); triggers (push + weekly schedule, plus release-time scan, plus manual)? install the `codeql` skill alongside the workflow?
- **F14**: project owner (repository owner or another org) and title; native auto-add (UI step, no secret) or headless (Actions workflow + PAT); which Status option means checked off (default `Done`); probe issue allowed?; backfill existing open issues and PRs?
- **F15**: which workflow file is the CI gate (and should its `name:` be shortened to `CI` for the badge label); both badges or extra ones (license, runtime version); placement under the H1 or in a Status section; is a shields.io image acceptable, or native GitHub only?

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
| F13 Code scanning (CodeQL) | DISABLED (no supported language) |
| F14 GitHub Project board | ENABLED (native auto-add) |
| F15 README badges | ENABLED (CI + release) |

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
| F12 Planning workflow | `AGENTS.md` | … | spec location: … |
| F13 Code scanning (CodeQL) | `.github/workflows/codeql.yml`, `skills/codeql/`, labels/`CODEQL_OPEN_ISSUE`, `AGENTS.md` | … | visibility: public (free) / private + Code Security · languages: … · gating: none (by design) |
| F14 GitHub Project board | project #`<n>`, repo link, `Item closed` workflow, auto-add filter (native) or `.github/workflows/project-sync.yml` + `PROJECT_TOKEN` (headless) | … | mode: native/headless · done option: `Done` · probe: issue #`<n>` closed |
| F15 README badges | `README.md` (badge block under the H1) | … | workflow: `…` · branch: `…` · release badge: version / `no releases` / `[BLOCKED]` (private) |

Preset: <preset>
Verification: <commands and result per enabled feature>
```

Then output `git add` and `git commit` commands limited to the selected files,
and leave committing to the user.
