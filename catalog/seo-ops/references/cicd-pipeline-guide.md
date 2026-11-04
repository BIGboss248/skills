# CI/CD & Pre-Push Pipeline Guide

This guide details setting up automated SEO quality gates in local git hooks and CI/CD pipelines (such as GitHub Actions).

---

## 1. Why Run SEO Checks in CI/CD?

Pre-deployment SEO audits catch critical technical blockers before code reaches production:
- Broken internal links (404 status codes) and redirect loops.
- Missing `<title>` tags, empty descriptions, and unconfigured OpenGraph tags.
- Broken JSON-LD structured data syntax and missing required schema entities.
- Broken canonical links or accidental `noindex` / `nofollow` robots meta tags on production routes.
- Dynamic route indexing errors in `sitemap.xml` / `app/sitemap.ts`.

---

## 2. Local Pre-Push Quality Gate (Husky)

Ensure git pushes validate tests and technical SEO health without manual dev server management.

### Dev Server Auto-Detection & Process Lifecycle
A Next.js technical audit requires an HTTP endpoint. The pre-push hook must:
1. **Probe**: Check if `http://127.0.0.1:3000` is already responsive (`curl -s -o /dev/null -w "%{http_code}"`).
2. **Reuse**: If a dev server is active, audit against it and **preserve** it (never terminate the developer's session).
3. **Fallback Spawn**: If no server is running, spawn `pnpm run dev` in the background and poll for readiness (up to 30s).
4. **Cleanup on Exit**: In a `finally` or `trap` handler, terminate only the process spawned by the script.
   - **Windows Pitfall**: `pnpm` is a `.cmd`/`.ps1` wrapper, not a native Win32 `.exe`. Calling `Start-Process -FilePath "pnpm"` fails with `%1 is not a valid Win32 application`. Always launch through `cmd.exe /c pnpm run dev`.
   - **Process Tree Cleanup**: Killing only `cmd.exe` leaves orphaned `node.exe` processes. Use `taskkill.exe /PID $proc.Id /T /F` on Windows to cleanly terminate the entire process tree.

### Step 1: Add Pre-Push Scripts
Deploy [`scripts/seo-pre-push.ps1`](../resources/templates/seo-pre-push.ps1.template) and [`scripts/seo-pre-push.sh`](../resources/templates/seo-pre-push.sh.template).

Register in `package.json`:
```json
{
  "scripts": {
    "test:all": "jest --passWithNoTests && playwright test --pass-with-no-tests",
    "seo:audit": "npx -y seo report --url http://127.0.0.1:3000 --actions-only --json",
    "seo:pre-push": "powershell -ExecutionPolicy Bypass -File ./scripts/seo-pre-push.ps1",
    "seo:pre-push:sh": "bash ./scripts/seo-pre-push.sh"
  }
}
```

### Step 2: Configure `.husky/pre-push`
```bash
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

pnpm run test:all
pnpm run seo:pre-push
```

---

## 3. GitHub Actions CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/seo-check.yml`) runs on pull requests and pushes to main/develop:

1. **Standalone Build**: Compiles Next.js with `pnpm build`.
2. **Background Server**: Launches `pnpm start &` on port 3000 and waits for HTTP 200 readiness via `wait-on`.
3. **Headless Technical Audit**: Executes `npx -y seo report --url http://127.0.0.1:3000 --actions-only --json > seo-report.json`.
4. **Artifact Retention**: Stores the resulting audit JSON as a GitHub Actions artifact for debugging and pull request reviews.
5. **Zero-API Dependency**: Relies purely on local crawler checks, meaning no Search Console tokens, secrets, or paid external APIs are required in CI runner environments.

---

## 4. Ingesting Search Console Performance Exports in CI

For staging or pre-release verification with real-world query demand:
```bash
npx -y seo report --url http://127.0.0.1:3000 --search-console-export ./downloads/gsc-export --actions-only --json
```
The report correlates crawled pages against real Search Console query volumes without requiring runtime Google authentication.
