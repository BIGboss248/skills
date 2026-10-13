# CI/CD, Release Automation & Multi-Arch GHCR Packaging Guide

This guide covers credit-optimized GitHub Actions CI/CD workflows, Release Please semantic release automation, Husky git hooks, and multi-architecture Docker container deployment to GitHub Container Registry (GHCR).

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
4. **`pre-push` Hook (Dual-Suite Enforcement - Rule 4)**:
   ```bash
   echo "pnpm run test:all" > .husky/pre-push
   ```

---

## 4. Release Please Workflow Specification

Full GitHub Actions release workflow template: [`release-please.yml.template`](../resources/templates/release-please.yml.template)

### Required GitHub Repository Permissions:

1. Go to repository **Settings** → **Actions** → **General**.
2. Under **Workflow permissions**:
   - Select **"Read and write permissions"**.
   - Check **"Allow GitHub Actions to create and approve pull requests"**.
3. Click **Save**.
