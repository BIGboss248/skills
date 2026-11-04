# Docker Containerization, GitHub Triage Setup & Credit-Optimized CI/CD Guide

This reference details the production Docker containerization, GitHub Triage infrastructure scaffolding, and Release Please multi-arch CI/CD pipeline for `setup-repository`.

---

## 1. Multi-Stage Production Docker Containerization

Configure containerization strictly for standalone production builds and deployments:

1. **`.dockerignore`**:
   Exclude `node_modules/`, `.pnpm-store/`, `dist/`, `build/`, `coverage/`, `test-results/`, `.env*`, `*.log`, `.git/`, `Dockerfile*`, `docker-compose*.yml`, and `.codebase-memory/`.
2. **Multi-Stage `Dockerfile`**:
   Deploy [`Dockerfile.template`](../resources/templates/Dockerfile.template) (`dependencies` -> `builder` -> `runner` running as non-root `node` user).
3. **Docker Compose Stacks**:
   - Local production build test: [`docker-compose.yml.template`](../resources/templates/docker-compose.yml.template)
   - Production GHCR image stack: [`docker-compose.prod.yml.template`](../resources/templates/docker-compose.prod.yml.template)

---

## 2. GitHub Triage Infrastructure Setup

Initialize the repository's GitHub Issues templates and standard triage labels during repository setup so the `github-triage` skill can track bugs, log root cause diagnostics, and link `.agents/autofix.json` rules immediately:

1. **Issue Templates**:
   - `.github/ISSUE_TEMPLATE/bug_report.yml` from [`bug_report.yml.template`](../resources/templates/bug_report.yml.template)
   - `.github/ISSUE_TEMPLATE/config.yml` from [`issue_config.yml.template`](../resources/templates/issue_config.yml.template)
2. **Automated Initialization & Label Sync (`init_triage_infra.ps1`)**:
   Execute [`scripts/init_triage_infra.ps1`](../scripts/init_triage_infra.ps1) to scaffold `.github/ISSUE_TEMPLATE/` and ensure standard triage labels exist in the remote repository via `gh label create --force`:
   - `bug` (`#d73a4a`): Something isn't working
   - `agent-triage` (`#0e8a16`): Triaged and managed by AI agent
   - `self-repair` (`#1d76db`): Linked to an `autofix.json` imperative rule
   - `verified` (`#5319e7`): Fix verified through automated test suites
   ```powershell
   powershell -ExecutionPolicy Bypass -File .agents/skills/setup-repository/scripts/init_triage_infra.ps1
   ```

---

## 3. Credit-Optimized CI/CD & Release Please Automation

Deploy [`.github/workflows/release-please.yml`](../resources/templates/release-please.yml.template) following these core DevOps rules:

1. **Automated Test Gate**: Runs project tests on pull requests and commits to `main`.
2. **Release Please Automation**: Automates version bumps, changelogs, and release PRs.
3. **`concurrency.cancel-in-progress: false`**: Never cancel release workflows or main-branch deployments in-flight.
4. **Two-Stage Multi-Arch Matrix Builder**: Build AMD64 and ARM64 on native runner machines (`ubuntu-latest` and `ubuntu-24.04-arm`) without QEMU emulation. Push images by digest.
5. **Digest Manifest Merge**: A downstream `merge-manifest` job stitches AMD64 and ARM64 digests into a unified multi-arch tag.
6. **Lowercase Repository Name**: Always transform `github.repository` to lowercase via `tr '[:upper:]' '[:lower:]'` into `IMAGE_NAME` (Docker OCI strict requirement).
