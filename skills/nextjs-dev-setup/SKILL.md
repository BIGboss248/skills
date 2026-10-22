---
name: nextjs-dev-setup
description: >-
  Bootstrap, configure, and verify the complete Next.js App Router development environment, developer tooling, internationalization (next-intl), testing suites, MCP servers, Docker containerization, and CI/CD. Triggers on "/nextjs-dev-setup", "setup nextjs dev environment", "start a nextjs project", or "containerize nextjs app".
---

# Next.js Development Setup (`nextjs-dev-setup`)

A structured, end-to-end orchestration runbook for discovering, configuring, and verifying the Next.js App Router development environment, internationalization (`next-intl`), reverse proxy routing (Traefik / Nginx), and single source of truth at `docs/project.json`.

---

## Pre-Conditions & Discovery

- [ ] **Zero-Interruption Scan**: Scan existing repository files (`package.json`, lockfiles, stylesheets, `docs/adr/*.md`, `docs/plan.md`, `CONTEXT.md`) before asking questions.
- [ ] Consult [project-json-schema.md](./references/project-json-schema.md) for metadata structure and automated deduction rules.

---

## Phase 0: Multi-Round Setup Interview (Grilling) & Plan Generation

Conduct the interactive interview in **progressive, adaptive rounds** (waiting for user response after each round) to tailor the setup:

1. **Round 1 (Scope & Tooling)**: Probe target testing suites (Jest, Playwright, Storybook), i18n locales (`en`, `fa`, etc. auto-deduced per zero-interruption scan), MCP servers, and `@shadcn/lint` enforcement.
2. **Round 2 (Reverse Proxy & Production Hosting)**: Probe domain name, port, and reverse proxy strategy:
   - **Traefik via Docker Compose**: Automated container discovery using Compose labels reading from environment variables (`${DOMAIN_NAME}`, `${TRAEFIK_ENTRYPOINT}`, `${TRAEFIK_CERTRESOLVER}`) with anti-buffering.
   - **Nginx via Host System**: Standalone configuration in `/etc/nginx/sites-available/<domain>` using Certbot SSL certificates.
3. **Round 3 (CI/CD, Git Hooks & Registry)**: Probe Husky pre-push test suites, Commitlint, and GitHub Actions Release Please / GHCR workflows.
4. Consult [setup-interview-rounds.md](./references/setup-interview-rounds.md) for complete question sets and branching logic.
5. **Plan & Execution**: Generate and present an `implementation_plan.md` artifact detailing all planned file creations, configurations, and packages before applying changes, and proceed directly with execution without waiting for manual confirmation.

---

## Step-by-Step Execution Flow

### Stage 1: Project Metadata & Internationalization (`next-intl`)

1. **Project Metadata**: Initialize `docs/project.json` using [project.template.json](./resources/templates/project.template.json) based on user interview choices and discovered locales.
2. **Install Internationalization Runtime**: Run `<pkg_mgr> add next-intl` (`pnpm add next-intl`).
3. **Scaffold `next-intl` Architectural Core**:
   - `i18n/routing.ts`: Configure `defineRouting` with supported locales and default locale using [routing.ts.template](./resources/templates/i18n/routing.ts.template).
   - `i18n/request.ts`: Configure server request handler using modern `next/root-params` (`await rootParams.locale()`) using [request.ts.template](./resources/templates/i18n/request.ts.template).
   - `i18n/navigation.ts`: Export pure TypeScript navigation utilities (`Link`, `redirect`, `usePathname`, `useRouter`, `getPathname`) using [navigation.ts.template](./resources/templates/i18n/navigation.ts.template).
   - **Request Interceptor**: Deploy [proxy.ts.template](./resources/templates/proxy.ts.template) for Next.js 16+ (`proxy.ts`), or [middleware.ts.template](./resources/templates/middleware.ts.template) for Next.js <=15 (`middleware.ts`).
   - **Starter Dictionaries**: Deploy baseline catalogs to `messages/en.json` and `messages/fa.json` (or configured locales) using [en.json.template](./resources/templates/messages/en.json.template) and [fa.json.template](./resources/templates/messages/fa.json.template).
   - **Root Locale Layout**: Scaffold `app/[locale]/layout.tsx` using [locale-layout.tsx.template](./resources/templates/locale-layout.tsx.template) with `generateStaticParams()`, dynamic `lang`/`dir`, and `<NextIntlClientProvider>`.
   - **Global Types**: Declare `AppConfig.Messages` in `global.d.ts` using [global.d.ts.template](./resources/templates/global.d.ts.template).
   - Consult [i18n-setup-guide.md](./references/i18n-setup-guide.md) for in-depth rules and architecture.
4. **Developer Tooling & Providers**:
   - Configure `.vscode/launch.json` using [vscode-launch.json.template](./resources/templates/vscode-launch.json.template).
   - Scaffold `app/providers.tsx` with `<ProgressBarProvider>` using [providers.tsx.template](./resources/templates/providers.tsx.template).
   - Scaffold composite `<Link>` in `app/components/Link.tsx` using [Link.tsx.template](./resources/templates/Link.tsx.template) combining `@/i18n/navigation` with progress bar triggers.
   - Scaffold `.env.example` using [env.example.template](./resources/templates/env.example.template) for production and `.env.development` using [env.local.template](./resources/templates/env.local.template) for local development (Rule 39).
   - **App Icons, Apple Icon & PWA Manifest**: Deploy [manifest.ts.template](./resources/templates/manifest.ts.template) to `app/manifest.ts`. Configure root `app/favicon.ico`, `app/icon.png`, and `app/apple-icon.png` per [app-icons-and-pwa-guide.md](./references/app-icons-and-pwa-guide.md).

### Stage 2: Testing Suites (Jest, Playwright & Instant Navigation)

> [!IMPORTANT]
> **No Dummy Test Files (Rule 3):** Do not create placeholder/sample test files in the workspace. Configure framework files and scripts only. Sample patterns are available in [sample-component.test.tsx](./examples/sample-component.test.tsx), [sample-navigation.spec.ts](./examples/sample-navigation.spec.ts), and [sample-component.stories.tsx](./examples/sample-component.stories.tsx).

1. **Jest Unit Testing**: Configure [jest.config.ts.template](./resources/templates/jest.config.ts.template) and [jest.setup.ts.template](./resources/templates/jest.setup.ts.template).
2. **Playwright E2E & Instant Navigation**: Install `@playwright/test` and `@next/playwright` (`pnpm add -D @playwright/test @next/playwright`), configure [playwright.config.ts.template](./resources/templates/playwright.config.ts.template), and install browsers.
3. **Next.js Instant Config**: Configure `cacheComponents: true`, `partialPrefetching: true`, and instant insights in `next.config.ts`.
4. **Storybook Workshop**: Configure [.storybook/main.ts](./resources/templates/storybook-main.ts.template) and [.storybook/preview.tsx](./resources/templates/storybook-preview.tsx.template) (wrapping stories with `NextIntlClientProvider` and `ProgressBarProvider` per Rule 25).
5. Review architectures in [testing-guide.md](./references/testing-guide.md) and [storybook-guide.md](./references/storybook-guide.md).

### Stage 3: Dual MCP Server Configuration

> [!IMPORTANT]
> **Antigravity Global MCP Loading Rule:** AG only loads MCP servers configured globally on the host system (`~/.gemini/antigravity/mcp_config.json` and `~/.gemini/config/mcp_config.json`). Workspace `mcp.json` is maintained for portability. Both must be configured.

1. Configure `next-devtools`, `playwright`, `storybook`, and `codebase-memory-mcp`.
2. **Stutter Prevention**: Set `auto_watch = false` via `codebase-memory-mcp config set auto_watch false` and deploy root [.cbmignore](./resources/templates/cbmignore.template).
3. Review full specs in [mcp-configuration-guide.md](./references/mcp-configuration-guide.md).

### Stage 4: Agent-First Design System Linting (`@shadcn/lint`)

1. Install `@shadcn/lint` and configure ESLint flat config using [eslint.config.mjs.template](./resources/templates/eslint.config.mjs.template).
2. Review mechanics in [styling-and-linting-guide.md](./references/styling-and-linting-guide.md).

### Stage 5: Standalone Production Docker & Reverse Proxy (Traefik / Nginx)

1. In `next.config.ts`: wrap config with `withNextIntl = createNextIntlPlugin()` using [next.config.ts.template](./resources/templates/next.config.ts.template), resolve Git commit hash and package version, inject `NEXT_PUBLIC_APP_VERSION` and `NEXT_PUBLIC_GIT_COMMIT_HASH` under `env`, enable `output: "standalone"`, set `deploymentId` (`${pkg.version}-${gitHash}`), configure `headers` with `X-Accel-Buffering: no`, and set `experimental.serverActions.allowedOrigins`.
2. Document `NEXT_SERVER_ACTIONS_ENCRYPTION_KEY` in `.env.example` and pass it to runtime environments.
3. Deploy [Dockerfile.template](./resources/templates/Dockerfile.template) (with `STOPSIGNAL SIGTERM`) and [docker-compose.yml.template](./resources/templates/docker-compose.yml.template) (with `stop_grace_period: 30s`).
4. **Reverse Proxy Configuration**:
   - **Traefik**: Deploy [docker-compose.prod.yml.template](./resources/templates/docker-compose.prod.yml.template) with dynamic environment variable labels (`${DOMAIN_NAME}`, `${TRAEFIK_ENTRYPOINT}`, `${TRAEFIK_CERTRESOLVER}`) and anti-buffering middleware.
   - **Nginx**: Deploy or output [nginx-site.conf.template](./resources/templates/nginx-site.conf.template) for `/etc/nginx/sites-available/<domain>` with Certbot SSL certificates.
5. Review architecture and multi-container cache drift callout in [docker-containerization-guide.md](./references/docker-containerization-guide.md).

### Stage 6: Git Hooks & Credit-Optimized CI/CD

1. Install `husky`, `@commitlint/cli`, `@commitlint/config-conventional`.
2. Configure [commitlint.config.mjs.template](./resources/templates/commitlint.config.mjs.template), `.husky/commit-msg`, and `.husky/pre-push` (`pnpm run test:all`).
3. Deploy [.github/workflows/release-please.yml](./resources/templates/release-please.yml.template) with `.next/cache` build caching and multi-arch matrix publishing.
4. Review caching in [cicd-and-release-automation-guide.md](./references/cicd-and-release-automation-guide.md).

### Stage 7: Final Execution Report & Verification

1. Execute the configuration verification script and ensure all checks pass.
2. Stage all created/modified files in git (`git add .`) per Rule 36.
3. **Mandatory Final Output**: Render the complete, structured **Next.js Dev Setup Execution Report** markdown table summarizing all implemented files, verification check results, and next development steps.

---

## Verification & Sanity Check

- [ ] Execute configuration verification script:
  - **Windows (PowerShell)**: `powershell -ExecutionPolicy Bypass -File .agents/skills/nextjs-dev-setup/scripts/verify-project-config.ps1`
  - **Linux / macOS (Bash)**: `bash .agents/skills/nextjs-dev-setup/scripts/verify-project-config.sh`
- [ ] Fix any reported errors and re-verify until all checks pass.

---

## Edge Cases & Known AI Pitfalls

- **Chained Commands**: Never chain commands with `&&` or `;` on a single line in terminal execution.
- **MCP Disabling**: In AG global configs, `agy.exe` ignores `"disabled": true` inside `mcpServers`. Move disabled servers outside `mcpServers`.
- **Docker Image Names**: Docker OCI naming strictly requires lowercase repository names (`IMAGE_NAME=$(echo ... | tr '[:upper:]' '[:lower:]')`).
- **Storybook Intl Context**: Always wrap Storybook stories rendering `Link` or `useTranslations` with `NextIntlClientProvider` and `ProgressBarProvider` (Rule 25).
- **Navigation Purity**: `i18n/navigation.ts` must remain pure TypeScript without JSX. Component wrappers like `Link` belong in `app/components/Link.tsx` (Rule 11).

---

## Mandatory Final Output: Execution Report Template

Always output this report upon completing the skill workflow:

```markdown
## 🛠️ Next.js Dev Setup Execution Report

| Step / Component                     | Target File(s) / Resource                                                                              | Status                          | Notes / Details                                                                  |
| :----------------------------------- | :----------------------------------------------------------------------------------------------------- | :------------------------------ | :------------------------------------------------------------------------------- |
| **1. Project Metadata**              | `docs/project.json`                                                                                    | `[IMPLEMENTED]` / `[UNTOUCHED]` | Configured package manager, directories, animation & i18n metadata.              |
| **2. Internationalization (next-intl)** | `i18n/routing.ts`, `i18n/request.ts`, `i18n/navigation.ts`, `proxy.ts`/`middleware.ts`, `messages/`    | `[IMPLEMENTED]` / `[UNTOUCHED]` | Configured next-intl with root-params, proxy interceptor, pure TS navigation & starter dictionaries. |
| **3. App Icons & PWA Manifest**      | `app/manifest.ts`, `app/favicon.ico`, `app/apple-icon.png`, `app/icon.png`                             | `[IMPLEMENTED]` / `[UNTOUCHED]` | Configured root favicon, Apple touch icon, and Web App Manifest using user favicon. |
| **4. Core Dependencies**             | `package.json`, Lockfile                                                                               | `[IMPLEMENTED]` / `[UNTOUCHED]` | Verified React, Next.js, next-intl, styling, and motion libraries.                |
| **5. Next.js Dev Server MCP**        | `~/.gemini/antigravity/mcp_config.json`, `mcp.json`, `.agents/plugins/workspace-tools/mcp_config.json` | `[IMPLEMENTED]` / `[UNTOUCHED]` | Configured Next.js Dev Server (`next-devtools`) globally for AG & in workspace.  |
| **6. Playwright & Instant Testing** | `playwright.config.ts`, `@next/playwright`, `mcp.json`, `~/.gemini/antigravity/mcp_config.json` | `[IMPLEMENTED]` / `[UNTOUCHED]` | Verified runner, browsers, Playwright MCP & `@next/playwright` instant navigation helper. |
| **7. Codebase Memory & Stutter Fix** | `.cbmignore`, `mcp.json`, `~/.gemini/antigravity/mcp_config.json`, `auto_watch=false`                  | `[IMPLEMENTED]` / `[UNTOUCHED]` | Registered MCP, configured .cbmignore exclusions, and disabled session watcher.  |
| **8. Jest Unit Testing**             | `jest.config.ts`, `jest.setup.ts`                                                                      | `[IMPLEMENTED]` / `[UNTOUCHED]` | Configured Next.js Jest transformer, jsdom environment & test-dom.               |
| **9. Storybook & Storybook MCP**     | `.storybook/main.ts`, `.storybook/preview.tsx`, `mcp.json`, `~/.gemini/antigravity/mcp_config.json`    | `[IMPLEMENTED]` / `[UNTOUCHED]` | Configured Storybook Vite, a11y, NextIntl decorator & Storybook AI MCP.          |
| **10. Agent-First Tailwind Linter**  | `eslint.config.mjs`, `package.json`                                                                    | `[IMPLEMENTED]` / `[UNTOUCHED]` | Configured `@shadcn/lint` for agent verification of design tokens and contracts. |
| **11. Docker & Reverse Proxy**       | `Dockerfile`, `docker-compose.prod.yml`, `nginx-site.conf`, `.dockerignore`                            | `[IMPLEMENTED]` / `[UNTOUCHED]` | Standalone container, Traefik labels / Nginx HTTPS with Certbot SSL.             |
| **12. Husky Git Hooks**              | `.husky/commit-msg`, `.husky/pre-push`                                                                 | `[IMPLEMENTED]` / `[UNTOUCHED]` | Enforces dual pre-push test suite (Jest + Playwright) & commitlint.              |
| **13. Commitlint Config**            | `commitlint.config.mjs`                                                                                | `[IMPLEMENTED]` / `[UNTOUCHED]` | Configured `@commitlint/config-conventional`.                                    |
| **14. Release & CI Build Caching**   | `.github/workflows/release-please.yml`                                                                 | `[IMPLEMENTED]` / `[UNTOUCHED]` | Next.js build cache (.next/cache), SemVer release PRs & GHCR multi-arch pkg.     |
| **15. Environment Verification**     | `scripts/verify-project-config.ps1` / `.sh`                                                            | `[PASSED]`                      | Sanity check passed with zero errors.                                            |

#### Status Definitions:
- **`[IMPLEMENTED]`**: Freshly created, installed, or modified during this setup run.
- **`[UNTOUCHED]`**: Already properly configured prior to running the skill; preserved as-is.
- **`[SKIPPED]`**: Intentionally omitted based on user preference.
```
