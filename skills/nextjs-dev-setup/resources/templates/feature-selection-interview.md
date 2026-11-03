# Next.js Setup — Feature Selection Interview

Present this structure verbatim, adapted with detected values. Ask in rounds and
stop after each round; never dump every question at once.

---

## 1. Detected context (no questions)

```text
Framework:        <Next.js version | not installed>
Router:           <App Router | Pages Router | empty>
Package manager:  <lockfile → pnpm|npm|yarn|bun>
Source layout:    <app/ | src/app/>
Existing files:   <AGENTS.md, docs/project.json, .opencode/agents, .husky/, Dockerfile, .storybook/ …>
MCP servers:      <registered servers | none>
GitHub CLI:       <authenticated as … | not authenticated | not installed>
Docker:           <version | not installed>
```

## 2. Categories and features

Ask at the **category** level first; drill into individual features only for the
categories the user keeps. Any feature can also be named explicitly by ID.

| Category | Feature | Default | Depends on |
| :--- | :--- | :--- | :--- |
| **A — Foundation** | N1 Project metadata (`docs/project.json`) | on | — |
| | N2 Framework core & app shell (`next@latest`, `AGENTS.md`, providers, env, boundaries) | on | N1 |
| | N3 App icons & PWA manifest | on | N2 |
| | N4 Internationalization (`next-intl`) | on | N1, N2 |
| | N13 Theming & light/dark mode (`next-themes`) | on | N2; N8 recommended |
| **B — Testing & Quality** | N5 Jest unit testing | on | N2 |
| | N6 Playwright E2E & instant navigation | on | N2 |
| | N7 Storybook workshop | off | N2 |
| | N8 Design-system lint (`@shadcn/lint`) | on | N2 |
| **C — Agents** | N9 Agent roster & permission boundaries | on | N2 |
| **D — Delivery & Operations** | N10 MCP servers & codebase memory | on if installed | N1 |
| | N11 Docker & reverse proxy | off | N2 |
| | N12 Git hooks, triage & CI/CD | on | N2, N5/N6 for the gate |

## 3. Round 1 — Preset

> Which preset should I use?
> **Minimal** (N1, N2) · **Standard** (N1–N6, N8–N10, N12–N13 — no N7 or N11) ·
> **Full** (all applicable) · **Custom** (choose categories and/or specific IDs)

## 4. Round 2 — Categories and adjustments

> Here is the Standard selection, grouped by category. Which **categories**
> should I add or remove, and do you want to name any **specific features**
> (N1–N13) to add or drop?

Resolve every dependency and record the degraded result:

- N2 without N1 → metadata stays empty; every runbook that reads project facts
  falls back to detection and the report records the degraded mode.
- N3/N4/N5/N6/N7/N8/N9/N11/N12/N13 without N2 → blocked; enable N2 or drop them.
- N13 without N8 → theming works, but raw palette classes and arbitrary color
  values are unenforced; record the degraded result.
- N13 without N7 → no Storybook theme decorator parity is checked.
- N13 on a project with no token layer → provider and toggle only; theme scope is
  partial and recorded as degraded for N8 to finish.
- N4 without N1 → scaffold i18n and record the locale intent in the selection;
  `docs/project.json` keys are added when N1 is enabled.
- N12 without N5 and N6 → pre-push gate degrades to lint only.
- N9 on a non-OpenCode harness → prompt-level roles plus the orchestrator's write
  audit (`DEGRADED: agent permissions unavailable`).
- N11 without Docker on the host → generate the files, skip the build probe, and
  record `[BLOCKED]` with the reason.
- N12 image publishing without N11 → workflow file only; no image job.

## 5. Round 3 — Per-feature options (enabled only)

Ask only the questions for enabled features; each runbook lists its own set.

- **N1**: confirm test/lint/build commands and source layout.
- **N2**: providers, env files, global boundaries, editor launch config.
- **N3**: favicon source, app identity, icon set.
- **N4**: locales and default, locale prefix, route migration, RTL locales.
- **N5**: test environment, coverage threshold, script names.
- **N6**: browsers, base URL, instant-navigation experiments.
- **N7**: builder preset, accessibility addon, story location.
- **N8**: token stylesheet, rule severity.
- **N13**: detected dark selector and strategy, default theme, palette scope,
  toggle placement/shape, motion on change, storage key.
- **N9**: roster confirmation, model overrides per role, command shortcuts.
- **N10**: accepted MCP servers, install codebase-memory, workspace vs global,
  first index mode.
- **N11**: image vs compose, Traefik/Nginx/none, domain and port, allowed
  origins, encryption-key source.
- **N12**: hook gate level, Release Please, GHCR publishing, triage forms and
  labels.

## 6. Confirmation

Write the canonical record to `.agents/nextjs-setup-features.json` using
[nextjs-setup-features.schema.json](./nextjs-setup-features.schema.json),
then present:

```markdown
### Next.js Setup Selection

| Category | Feature | Status |
| :--- | :--- | :--- |
| A Foundation | N1 Project metadata | ENABLED |
| A Foundation | N2 Framework core & app shell | ENABLED |
| A Foundation | N3 App icons & PWA | ENABLED |
| A Foundation | N4 Internationalization | ENABLED |
| A Foundation | N13 Theming & light/dark mode | ENABLED |
| B Testing & Quality | N5 Jest | ENABLED |
| B Testing & Quality | N6 Playwright | ENABLED |
| B Testing & Quality | N7 Storybook | DISABLED |
| B Testing & Quality | N8 Design-system lint | ENABLED |
| C Agents | N9 Agent roster | ENABLED |
| D Delivery & Operations | N10 MCP servers | ENABLED |
| D Delivery & Operations | N11 Docker & proxy | DISABLED |
| D Delivery & Operations | N12 Git hooks & CI/CD | ENABLED |

Preset: Standard
Degraded: none
Proceed with these features? (yes / adjust)
```

## 7. Execution report template

```markdown
## 🛠️ Next.js Dev Setup Execution Report

| Category | Feature | Target files / resources | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| Foundation | N1 Project metadata | `docs/project.json` | `[IMPLEMENTED]` / `[UNTOUCHED]` / `[SKIPPED]` / `[BLOCKED]` | … |
| Foundation | N2 Framework core & app shell | `package.json`, `AGENTS.md`, `app/providers.tsx`, `app/components/Link.tsx`, `.env*`, boundaries | … | … |
| Foundation | N3 App icons & PWA | `app/favicon.ico`, `app/icon.png`, `app/apple-icon.png`, `app/manifest.ts` | … | … |
| Foundation | N4 Internationalization | `i18n/*`, `proxy.ts`/`middleware.ts`, `app/[locale]/layout.tsx`, `messages/*.json`, `global.d.ts` | … | locales: … |
| Foundation | N13 Theming & dark mode | providers file, `<style_file_dir>`, toggle component, `docs/project.json` | … | strategy: … |
| Testing & Quality | N5 Jest | `jest.config.ts`, `jest.setup.ts` | … | … |
| Testing & Quality | N6 Playwright | `playwright.config.ts`, `next.config.ts` | … | … |
| Testing & Quality | N7 Storybook | `.storybook/main.ts`, `.storybook/preview.tsx` | … | … |
| Testing & Quality | N8 Design-system lint | `eslint.config.mjs`, `package.json` | … | … |
| Agents | N9 Agent roster | `.opencode/agents/*.md`, `.opencode/commands/*.md`, `.agents/rules/agent-boundaries.md` | … | … |
| Delivery & Operations | N10 MCP servers | `mcp.json`, `.cbmignore`, AGY configs, `docs/project.json` | … | accepted: … |
| Delivery & Operations | N11 Docker & proxy | `Dockerfile`, `docker-compose*.yml`, `nginx-site.conf`, `.dockerignore` | … | proxy: … |
| Delivery & Operations | N12 Git hooks & CI/CD | `.husky/*`, `commitlint.config.mjs`, `.github/**` | … | gate: … |

Preset: <preset>
Verification: <command and result per feature>
Next steps: <first component/page command, dev server, remaining setup>
```

Status definitions: `[IMPLEMENTED]` created or modified this run, `[UNTOUCHED]`
already correct before the run, `[SKIPPED]` disabled in the selection,
`[BLOCKED]` dependency or environment missing (reason required).
