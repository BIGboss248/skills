---
name: nextjs-dev-setup
description: >-
  Feature-driven bootstrap, configuration, and verification of a Next.js App Router
  development environment: framework core, internationalization (next-intl),
  theming (light/dark mode with next-themes), testing suites (Jest, Playwright,
  Storybook), design-system linting, agent roster, MCP servers, Docker + reverse
  proxy, and CI/CD. Triggers on "/nextjs-dev-setup", "setup nextjs dev
  environment", "start a nextjs project", "add dark mode to nextjs", or
  "containerize nextjs app".
metadata:
  author: BIGBOSS248
  version: "2.0"
---

# Next.js Development Setup (Feature-Driven)

Turns Next.js onboarding into a **menu of independently selectable features**,
grouped by category. Interview first, deploy only what the user enables, and
verify only what was deployed.

## Contract

- **No writes before selection.** Phase 1 ends with explicit confirmation.
- **Selected only.** Disabled features are reported `[SKIPPED]` and left untouched.
- **Categories first, IDs always allowed.** Users may keep whole categories or
  name specific features (`N1`–`N13`).
- **Format-agnostic output.** Generated code follows the project's existing
  structure and conventions. Never impose a fixed CSS architecture, token
  vocabulary, selector scheme, or component-library choice; detect first, append
  only, and never overwrite or rename what the project already owns.
- **Dependencies are explicit.** Missing prerequisites produce `[BLOCKED]` or a
  documented degraded result — never a silent partial install.
- **Idempotent.** Re-running merges and updates; never overwrite existing
  configuration or machine-owned blocks.
- **No dummy tests, stories, or pages.** Scaffold infrastructure only (Rule 3).
- **Outdated Next.js context.** Before using any Next.js API, directive, or
  caching primitive, consult `node_modules/next/dist/docs` through
  `codebase-memory`. Training data is not authoritative here.

## Phase 1 — Feature Selection Interview (mandatory)

### 1.1 Detect first (no questions yet)

Scan `package.json`, lockfiles, `app/` vs `src/app/`, `docs/` and `docs/adr/*`,
`AGENTS.md`, `.opencode/agents/`, `mcp.json`, `.husky/`, `.github/`, `Dockerfile`,
`.storybook/`, and `docs/project.json`. Also read `.agents/nextjs-setup-features.json`
and `.agents/setup-features.json` from previous runs. Only ask about what cannot
be detected.

### 1.2 Present categories and the feature catalog

| Category | Feature | Default | Depends on |
| :--- | :--- | :--- | :--- |
| **A — Foundation** | N1 Project metadata (`docs/project.json`) | on | — |
| | N2 Framework core & app shell | on | N1 |
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

Use [feature-selection-interview.md](./resources/templates/feature-selection-interview.md)
for the menu, presets, dependency-resolution rules, and report template.

### 1.3 Ask in adaptive rounds

1. **Preset** — Minimal (`N1, N2`), Standard (`N1`–`N6`, `N8`–`N10`, `N12`,
   `N13`), Full (all applicable), or Custom.
2. **Categories and adjustments** — keep or drop categories, then accept explicit
   feature IDs to add or remove. Record every change.
3. **Per-feature options** — only for enabled features. Question sets:
   [setup-interview-rounds.md](./references/setup-interview-rounds.md) and each
   runbook under [references/features/](./references/features/).

### 1.4 Resolve and record

- Resolve dependencies; confirm each degraded mode explicitly.
- Write `.agents/nextjs-setup-features.json` using
  [nextjs-setup-features.schema.json](./resources/templates/nextjs-setup-features.schema.json).
- When N1 is enabled, merge `nextjs_setup_features` into `docs/project.json`.
- Present the confirmation block and wait for approval before Phase 2.

## Phase 2 — Execute Enabled Features

Run in dependency order:
**N1 → N2 → N3 → N4 → N9 → N5 → N6 → N7 → N8 → N13 → N10 → N11 → N12**.

For each enabled feature:

- [ ] Generate the `implementation_plan.md` artifact (files, packages, config
      deltas) once, before the first write.
- [ ] Open its runbook and follow it exactly.
- [ ] Run its acceptance check.
- [ ] Record `[IMPLEMENTED]`, `[UNTOUCHED]`, `[SKIPPED]`, or `[BLOCKED]` with a
      reason.

| Feature | Runbook |
| :--- | :--- |
| N1 Project metadata | [01-project-metadata.md](./references/features/01-project-metadata.md) |
| N2 Framework core & app shell | [02-framework-core.md](./references/features/02-framework-core.md) |
| N3 App icons & PWA | [03-app-icons-pwa.md](./references/features/03-app-icons-pwa.md) |
| N4 Internationalization | [04-internationalization.md](./references/features/04-internationalization.md) |
| N5 Jest | [05-jest-unit-testing.md](./references/features/05-jest-unit-testing.md) |
| N6 Playwright | [06-playwright-e2e.md](./references/features/06-playwright-e2e.md) |
| N7 Storybook | [07-storybook.md](./references/features/07-storybook.md) |
| N8 Design-system lint | [08-design-system-lint.md](./references/features/08-design-system-lint.md) |
| N13 Theming & dark mode | [13-theming.md](./references/features/13-theming.md) |
| N9 Agent roster | [09-agent-roster.md](./references/features/09-agent-roster.md) |
| N10 MCP servers | [10-mcp-servers.md](./references/features/10-mcp-servers.md) |
| N11 Docker & proxy | [11-docker-reverse-proxy.md](./references/features/11-docker-reverse-proxy.md) |
| N12 Git hooks & CI/CD | [12-git-hooks-cicd.md](./references/features/12-git-hooks-cicd.md) |

Do not touch files owned only by disabled features — not even to "prepare" them.

### Interop with `setup-repository`

`setup-repository` owns repository-level features (`F1`–`F11`); this skill owns
app-level features. When a repository-level feature already ran, verify instead
of re-scaffolding and report `[UNTOUCHED]`:

| This skill | Repository skill | Overlap |
| :--- | :--- | :--- |
| N1 | F1 Project metadata | same `docs/project.json` |
| N4 | F11 Next.js i18n | identical next-intl contract |
| N10 | F3 MCP servers | same `mcp.json` / `.cbmignore` |
| N11 | F5 Production Docker | same Dockerfile / compose |
| N12 | F4/F7/F8 Git hooks, triage, release | same `.husky/`, `.github/` |

## Phase 3 — Verify

- [ ] Run the selection-aware verifier:
  - **Windows (PowerShell)**:
    `powershell -ExecutionPolicy Bypass -File .agents/skills/nextjs-dev-setup/scripts/verify-project-config.ps1`
  - **Linux / macOS (Bash)**:
    `bash .agents/skills/nextjs-dev-setup/scripts/verify-project-config.sh`
  - It reads `.agents/nextjs-setup-features.json` (fallback
    `docs/project.json → nextjs_setup_features`) and reports unchecked features
    as `SKIPPED`. Pass `-AllFeatures` / `--all` to audit the whole repository.
- [ ] Re-run each enabled feature's runbook acceptance list; the script cannot
      certify the build, the browser, or the agent permissions.
- [ ] Fix reported errors and re-verify until the enabled set is clean.
- [ ] Confirm disabled features were left untouched.

## Phase 4 — Report and Handoff

Produce the report from
[feature-selection-interview.md](./resources/templates/feature-selection-interview.md#7-execution-report-template):

- one row per feature (enabled and disabled) with status and reason;
- the exact commands run and their results;
- `git add` commands limited to selected features; leave committing to the user;
- next development steps (dev server, first page/component command, pending
  features).

## Edge Cases & Known AI Pitfalls

- **Outdated Next.js context** — never assume API shapes, directives, or caching
  behavior from memory; query the local docs first.
- **Latest version enforcement** — always install `next@latest react@latest
  react-dom@latest`; never pin an older major/minor.
- **Chained commands** — never chain with `&&` or `;` in a single terminal call.
- **N2 overwrites** — compose `next.config.*` and provider files instead of
  replacing them; N4/N6/N11 each add keys to the same config.
- **N4 double scaffolding** — when `setup-repository` F11 already ran, verify and
  report `[UNTOUCHED]`; rewriting loses route migrations.
- **N9 placeholders** — a deployed agent file containing `{{MODEL_LINE}}`,
  `{{PM}}`, or `{{PM_RUN}}` is invalid; substitute before writing.
- **N9 discovery timing** — new `.opencode/agents/*.md` files register on the next
  session; do not claim the roster is active inside the creating session.
- **N10 selection** — never enable every MCP server silently; each one adds tool
  definitions to every request. Register only the accepted set.
- **N11 image names** — Docker OCI names must be lowercase.
- **N12 test gate** — never point `pre-push` at a script that does not exist;
  degrade to lint only and record it.
- **Storybook intl context** — wrap stories with `NextIntlClientProvider` (when
  N4 is enabled). No progress-bar provider is needed: pending feedback is
  per-link `useLinkStatus` and renders nothing while idle.
- **Storybook theme parity** — the preview decorator must use the same strategy
  as the app (`withThemeByClassName` for class, `withThemeByDataAttribute` for
  `data-theme`), or stories lie about both themes.
- **Link contract** — internal navigation uses `Link` from `@/i18n/navigation`.
  `next/link` remains valid only for hash anchors and the locale-less root
  `not-found.tsx`.
- **Navigation pending** — per-link `useLinkStatus` from `next/link` (Next
  ≥15.3, App Router only; Pages Router always returns `pending: false`). No
  progress-bar package, provider, or router-event listener. The indicator must
  always render, reserve fixed space, toggle opacity after ~100ms, and respect
  `prefers-reduced-motion`, or it causes layout shift and flicker. Contract:
  [navigation-pending-guide.md](./references/navigation-pending-guide.md).
- **Theme strategy** — `next-themes`' `attribute` must match the selector the
  token stylesheet actually uses (`class`, `data-theme`, `data-mode`). The
  stylesheet wins over any default.
- **Theme structure** — never impose a CSS file layout, token names, color space,
  or selector scheme. Detect, append the dark layer only, and never re-declare or
  rename existing token values. Acceptance is behavioral (toggle flips real
  tokens, persists, no first-paint flash), not textual. Reference:
  [theming-guide.md](./references/theming-guide.md).
- **Theme hydration** — `theme`/`resolvedTheme` are `undefined` on the server and
  the first render; guard icons on mount and add `suppressHydrationWarning` to
  `<html>` only when the provider writes the attribute client-side.
- **Theme dependencies** — `next-themes` must be installed whenever the provider
  wrapper is deployed (N13); a provider importing an uninstalled package fails the
  N2 acceptance check.
- **Navigation purity** — `i18n/navigation.ts` stays pure TypeScript; component
  wrappers belong in `app/components/`.
- **No placeholders** — placeholder tests, stories, or pages are a contract
  violation, not a convenience.
