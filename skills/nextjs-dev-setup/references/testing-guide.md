# Next.js Testing Architecture Guide (Jest, Playwright & Instant Navigation)

This guide covers the setup, architecture, and verification of Jest unit testing, Playwright E2E testing, and Playwright Instant Navigation testing in Next.js App Router projects.

---

## 1. Zero Dummy Files Constraint (Rule 3)

> [!IMPORTANT]
> **NO DUMMY / SAMPLE TEST GENERATION IN WORKSPACE:**
> Do NOT create placeholder or dummy test files in the user workspace during setup. Only configure framework configuration files (`jest.config.ts`, `jest.setup.ts`, `playwright.config.ts`, and `package.json` scripts).
> Sample patterns are provided strictly for documentation:
>
> - Jest Unit Test Example: [`sample-component.test.tsx`](../examples/sample-component.test.tsx)
> - Playwright E2E & Instant Test Example: [`sample-navigation.spec.ts`](../examples/sample-navigation.spec.ts)

---

## 2. Jest Unit & Snapshot Testing (`next/jest`)

Next.js provides built-in integration with Jest via the `next/jest` transformer, which automatically configures SWC transforms, mocks CSS modules/fonts, and loads `.env` variables.

- **Config Files**:
  - `jest.config.ts`: see [`jest.config.ts.template`](../resources/templates/jest.config.ts.template)
  - `jest.setup.ts`: see [`jest.setup.ts.template`](../resources/templates/jest.setup.ts.template)
- **Scope**: Synchronous Server/Client Components, custom hooks, utilities, and snapshots in `jsdom`.
- **Async Server Components Note**: Because `async` React Server Components run in Node server environments, Jest (running in `jsdom`) does not execute `async` RSCs directly. Rely on Playwright E2E tests for `async` Server Components.

---

## 3. Playwright End-to-End Testing

Playwright tests the complete running Next.js application across real browser engines (**Chromium**, **Firefox**, **WebKit**), verifying routing, auth flows, and `async` Server Components.

- **Config File**: `playwright.config.ts`: see [`playwright.config.ts.template`](../resources/templates/playwright.config.ts.template)
- **Required Packages**:
  ```bash
  pnpm add -D @playwright/test @next/playwright
  ```
- **Browser Installation**:
  ```bash
  pnpm exec playwright install --with-deps chromium firefox webkit
  ```
- **Web Server Lifecycle**: Playwright's `webServer` configuration automatically detects `CI=true`, runs `pnpm build && pnpm start`, waits for `http://localhost:3000` to become healthy, runs the browser test suite, and cleanly terminates the server upon test completion.

---

## 4. Playwright Instant Navigation Testing (`@next/playwright`)

Next.js provides the `@next/playwright` package with an `instant()` helper that scopes assertions strictly to the UI that is **immediately available on navigation** (static shell, warm cache, and fallback skeletons) before dynamic server content streams in.

### A. Next.js Configuration (`next.config.ts`)
To enable instant validation in dev and expose the testing API for CI production builds (`next start`):
```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  cacheComponents: true,
  partialPrefetching: true,
  experimental: {
    instantInsights: {
      validationLevel: "warning", // 'warning' (default) or 'manual-warning'
    },
    exposeTestingApiInProductionBuild: true, // Exposes instant testing API in 'next start'
  },
};

export default nextConfig;
```

### B. Instant Testing Patterns
```ts
import { test, expect } from "@playwright/test";
import { instant } from "@next/playwright";

test.describe("Instant Navigation Suite", () => {
  // 1. Initial Page Load (Hard Navigation / Direct Visit)
  test("initial page load renders static shell instantly", async ({ page, baseURL }) => {
    await instant(
      page,
      async () => {
        await page.goto("/store/hats");
        // Assert static shell & cached content are immediately visible
        await expect(page.locator("h1")).toContainText("Baseball Cap");
        // Assert dynamic streaming slot is not yet rendered during instant scope
        await expect(page.getByText("In stock")).toHaveCount(0);
      },
      { baseURL } // Mandatory on initial page.goto() so helper knows the origin
    );
    // After instant() callback completes, dynamic stream finishes:
    await expect(page.getByText("In stock")).toBeVisible();
  });

  // 2. Client Navigation (Soft Navigation via Link)
  test("client navigation renders prefetched App Shell instantly", async ({ page }) => {
    await page.goto("/store/shoes");
    await instant(page, async () => {
      await page.click('a[href="/store/hats"]');
      // Crucial: Wait for URL transition before asserting on destination UI
      await page.waitForURL((url) => url.pathname === "/store/hats");
      await expect(page.locator("h1")).toContainText("Baseball Cap");
      await expect(page.getByText("In stock")).toHaveCount(0);
    });
    await expect(page.getByText("In stock")).toBeVisible();
  });
});
```

### C. Critical Rules for `instant()` Tests
1. **Always pass `{ baseURL }`** on the first `page.goto()` navigation within `instant()`.
2. **Always `await page.waitForURL(...)`** inside client navigation callbacks before asserting on target UI to prevent selector matching on the source page.
3. **Assert Shell vs Streamed Content**: Inside the `instant()` callback, assert that static/cached UI exists and dynamic streaming UI is absent (`toHaveCount(0)`). Outside `instant()`, assert that streamed content arrives.

---

## 5. Unified `package.json` Test Scripts

Configure test scripts with exit-code-safe flags so empty project suites do not break CI:

```json
{
  "scripts": {
    "test": "jest --passWithNoTests",
    "test:watch": "jest --watch --passWithNoTests",
    "test:coverage": "jest --coverage --passWithNoTests",
    "test:e2e": "playwright test --pass-with-no-tests",
    "test:e2e:ui": "playwright test --ui",
    "test:all": "jest --passWithNoTests && playwright test --pass-with-no-tests"
  }
}
```
