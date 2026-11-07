# CI/CD, Release Automation, GitHub Triage Setup & Multi-Arch GHCR Packaging Guide

This guide covers credit-optimized GitHub Actions CI/CD workflows, Release Please semantic release automation, GitHub Triage infrastructure scaffolding, Husky git hooks, and multi-architecture Docker container deployment to GitHub Container Registry (GHCR).

---

## 1. Credit-Saving CI/CD Design Patterns

To minimize GitHub Actions minutes and eliminate unnecessary billing overhead:

- **`concurrency.cancel-in-progress: false`**: Ensures active release and workflow runs on main are never cancelled in-flight when new commits are pushed (Rule 9).
- **Fail-Fast Testing Hierarchy**: Runs fast, in-memory **Jest unit tests first**. If unit tests fail, the job terminates immediately before spending time installing browsers or running Playwright.
- **Playwright Binary Caching**: Caches `~/.cache/ms-playwright` using `actions/cache` keyed against lockfile hashes, eliminating repeated browser downloads.
- **Next.js CI Build Caching (`.next/cache`)**: Persists `.next/cache` between CI runs using `actions/cache@v4`. Eliminates full rebuilds from scratch, cuts CI execution times, and eliminates the Next.js `No Cache Detected` diagnostic error ([Next.js: No Cache Detected](https://nextjs.org/docs/messages/no-cache)).
- **Native Two-Stage Multi-Arch Matrix**: Builds `linux/amd64` and `linux/arm64` images concurrently across separate dedicated runner machines (`ubuntu-latest` and `ubuntu-24.04-arm`) without QEMU emulation (Rule 8). A downstream `merge-manifest` job stitches digests into a unified multi-arch release tag.
- **Lowercase Repository Names**: Forces lowercase repository names in image tags (`IMAGE_NAME=$(echo "ghcr.io/${{ github.repository }}" | tr '[:upper:]' '[:lower:]')`) to comply with strict Docker OCI naming specs (Rule 10).

---

## 2. 4-Layer Credit-Saving Caching Hierarchy

| Layer                                    | Target Resource                                      | Caching Mechanism                                     | Purpose                                                                          |
| :--------------------------------------- | :--------------------------------------------------- | :---------------------------------------------------- | :------------------------------------------------------------------------------- |
| **Layer 1: Package Manager Store**       | Global store (`~/.local/share/pnpm/store`, `~/.npm`) | `actions/setup-node@v4` (`cache: "[pm]"`)             | Avoids re-downloading dependency tarballs over the network.                      |
| **Layer 2: Next.js CI Build Cache**      | `${{ github.workspace }}/.next/cache`                | `actions/cache@v4` with composite lockfile+source key | Accelerates SWC compilation & prerendering; eliminates "No Cache Detected".      |
| **Layer 3: Playwright Browser Binaries** | `~/.cache/ms-playwright`                             | `actions/cache@v4` keyed by lockfile                  | Eliminates multi-hundred-megabyte browser downloads (Chromium, WebKit, Firefox). |
| **Layer 4: Docker Container Layers**     | OCI build stages & layers                            | `docker/build-push-action@v6` with `type=gha`         | Caches container stages across runs for native multi-arch builds.                |

---

## 3. Git Hooks with Husky & Commitlint

1. **Commitlint Config**: [`commitlint.config.mjs.template`](../resources/templates/commitlint.config.mjs.template)
2. **Husky Init**: Run `pnpm exec husky init`
3. **`commit-msg` Hook**:
   ```bash
   echo "pnpm exec commitlint --edit \$1" > .husky/commit-msg
   ```
4. **`pre-push` Hook (Expensive Tier - Rule 4)**:
   ```bash
   echo "pnpm run test:prepush" > .husky/pre-push
   ```
   This is the **only** local execution point for the expensive test tier
   (full Jest + Playwright). Development runs targeted Jest only; see
   [testing-guide.md](./testing-guide.md#6-test-execution-tiers-fast-during-dev-expensive-pre-push).

---

## 4. GitHub Triage Infrastructure Setup

Initialize the repository's GitHub Issues templates and standard triage labels during project setup so the `github-triage` skill can track issues and link `autofix.json` rules immediately:

1. **Templates**:
   - `.github/ISSUE_TEMPLATE/bug_report.yml` from [`bug_report.yml.template`](../resources/templates/bug_report.yml.template)
   - `.github/ISSUE_TEMPLATE/config.yml` from [`issue_config.yml.template`](../resources/templates/issue_config.yml.template)
2. **Automated Initialization & Label Sync (`init_triage_infra.ps1`)**:
   Execute [`scripts/init_triage_infra.ps1`](../scripts/init_triage_infra.ps1) to scaffold `.github/ISSUE_TEMPLATE/` and ensure standard triage labels exist in the remote repository via `gh label create --force`:
   - `bug` (`#d73a4a`): Something isn't working
   - `agent-triage` (`#0e8a16`): Triaged and managed by AI agent
   - `self-repair` (`#1d76db`): Linked to an `autofix.json` imperative rule
   - `verified` (`#5319e7`): Fix verified through automated test suites
   ```powershell
   powershell -ExecutionPolicy Bypass -File .agents/skills/nextjs-dev-setup/scripts/init_triage_infra.ps1
   ```

---

## 5. Release Please Workflow Specification

Full GitHub Actions release workflow template: [`release-please.yml.template`](../resources/templates/release-please.yml.template)

### Required GitHub Repository Permissions:

1. Go to repository **Settings** → **Actions** → **General**.
2. Under **Workflow permissions**:
   - Select **"Read and write permissions"**.
   - Check **"Allow GitHub Actions to create and approve pull requests"**.
3. Click **Save**.

### 5.1 The release gate contract

The only supported pipeline is:

```text
push to main
  -> quality gate (lint, typecheck, Jest, Playwright, build)   [quality]
  -> Release Please runs                                        [release]
       |-- no merged release PR: opens/updates the release PR
       |                         -> NO image is built or pushed
       `-- a release PR was merged by the user:
             creates the GitHub release + tag
             -> build linux/amd64                                 [publish]
             -> build linux/arm64                                 [publish]
             -> stitch digests into one manifest list             [merge]
             -> push GHCR tags for the Release Please version
```

Hard rules:

- **The user merging the release PR is the gate.** Publish only runs when
  `needs.release.outputs.released == 'true'`, i.e. Release Please created a
  release in this run. A push that merely opens or updates the release PR must
  produce no image and must not move `latest`.
- **Keep `release` and the image jobs in the same workflow run.** Release
  Please uses `GITHUB_TOKEN`, and GitHub never starts a follow-up run for tags,
  releases, or PRs created with that token. A separate `on: release` workflow
  would not fire; the image jobs must consume the `release` job outputs in the
  same run.
- **Build from the release tag, not the triggering SHA.** `next.config.ts` reads
  `package.json` for `NEXT_PUBLIC_APP_VERSION` (and the commit for
  `deploymentId`), so checking out `needs.release.outputs.tag` keeps the baked
  version equal to the image tag even if Release Please tags an earlier commit.
- **A red gate must never publish.** `publish` transitively `needs` `quality`
  through `release`; never add `if: always()` to either image job.

### 5.2 Release Please manifest configuration

Ship both `release-please-config.json` and `.release-please-manifest.json` at the
repository root and point the action at them:
[`release-please-config.json.template`](../resources/templates/release-please-config.json.template)
and
[`release-please-manifest.json.template`](../resources/templates/release-please-manifest.json.template).

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "separate-pull-requests": false,
  "packages": {
    ".": {
      "release-type": "node",
      "package-name": "",
      "changelog-path": "CHANGELOG.md",
      "include-component-in-tag": false,
      "initial-version": "0.1.0",
      "bump-minor-pre-major": true
    }
  }
}
```

**Single root package pitfall.** With `include-component-in-tag: false` the
release tag is `v<version>`, but `package-name` still feeds the *branch*
component. A non-empty name (for example `"package-name": "my-app"`) makes the
strategy expect a `release-please--branches--my-app--main` branch while the open
release PR lives on `release-please--branches--main`. Release Please then skips
tagging the merged PR:

```text
PR component: undefined does not match configured component: my-app
There are untagged, merged release PRs outstanding - aborting
```

The symptom is a merged release PR stuck on `autorelease: pending`, no GitHub
release, an empty `releases_created`, and therefore no image. Keep
`package-name: ""` for a component-less root tag. Drop the `include-component-in-tag`
override only when you actually want component-prefixed tags, and then keep the
package name aligned with the branch name.

`.release-please-manifest.json` starts at the current released version (or
`"0.0.0"` for a brand-new package) and is bumped by the release PR itself:

```json
{
  ".": "0.0.0"
}
```

### 5.3 Image metadata contract

Every published image must be traceable to a released version and commit:

| Tag | Example | Purpose |
| :--- | :--- | :--- |
| `<version>` | `0.3.0` | Release Please version; matches `package.json` inside the image |
| `<version>-sha-<short>` | `0.3.0-sha-a2b211f` | Reproducible rollback pin |
| `sha-<short>` | `sha-a2b211f` | Commit-only pin |
| `latest` | `latest` | Most recent **release**; never moves on a normal push |

Also set the OCI labels `org.opencontainers.image.source`,
`org.opencontainers.image.revision` (full release SHA) and
`org.opencontainers.image.version` (the Release Please version) on every build.

### 5.4 Multi-arch build mechanics

- Build `linux/amd64` on `ubuntu-latest` and `linux/arm64` on
  `ubuntu-24.04-arm`; both are native hosted runners, so no QEMU is required.
  Fall back to QEMU (`docker/setup-qemu-action`) only when the arm64 runner is
  unavailable on the plan.
- Each matrix leg pushes by digest
  (`outputs: type=image,name=…,push-by-digest=true,name-canonical=true,push=true`),
  exports `steps.build.outputs.digest` to `/tmp/digests`, and uploads it as
  `digests-<arch>`.
- A single `merge` job downloads the artifacts (`pattern: digests-*`,
  `merge-multiple: true`) and runs `docker buildx imagetools create` once, so the
  two legs never race on the same tag. Then inspect
  `image:<version>` and confirm both `linux/amd64` and `linux/arm64` appear.

### 5.5 Permissions

Keep the workflow default at `contents: read` and grant per job:

| Job | Permissions |
| :--- | :--- |
| `quality` | `contents: read` |
| `release` | `contents: write`, `pull-requests: write` (add `issues: write` to silence label warnings) |
| `publish` / `merge` | `contents: read`, `packages: write` |

Never grant `packages: write` to the test job or `contents: write` to the image
jobs.

### 5.6 Gate hygiene for Next.js browser tests

A JavaScript-disabled DOM assertion for a server-rendered shell (title, `h1`,
`aria-current`) cannot pass against `next dev`: an async route streams behind
`loading.tsx` into a hidden segment that only client scripts reveal, so a
correctly prerendered page looks like a skeleton. Do one of:

- run the browser suite against the production build (`next build` then
  `next start`, reusing the CI build), or
- assert the raw HTTP response (`page.request.get`) when the suite must stay on
  the dev server.

Never weaken the assertion to "the markup exists somewhere in the response" and
call it a no-JS contract.

### 5.7 Acceptance checks

- [ ] A push that only opens/updates the release PR leaves `publish` and `merge`
      skipped and does not move `latest`.
- [ ] Merging the release PR creates the tag/release in the same run and then
      builds both architectures.
- [ ] `docker buildx imagetools inspect image:<version>` lists `linux/amd64` and
      `linux/arm64`.
- [ ] Image tags are `<version>`, `<version>-sha-<short>`, `sha-<short>`, and
      `latest`; `org.opencontainers.image.version` matches `<version>`.
- [ ] `release-please-config.json` uses `package-name: ""` when
      `include-component-in-tag` is `false`.
- [ ] A failing `quality` job produces no release and no image.
