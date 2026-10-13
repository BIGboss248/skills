# Component Testing Architecture & Verification Guide (Jest + RTL & Playwright)

This reference outlines the dual-layer testing division of labor for Next.js App Router components: fast synchronous unit testing with Jest + React Testing Library (RTL) and browser-level validation with Playwright (including Instant Navigation assertions via `@next/playwright`).

---

## 1. Dual-Layer Testing Division of Labor

```
                                 Component Testing Strategy
                                             │
                  ┌──────────────────────────┴──────────────────────────┐
                  ▼                                                     ▼
      Jest + RTL Unit Tests                                Playwright E2E & Instant Tests
   ([ComponentName].test.tsx)                                 ([ComponentName].spec.ts)
   ─────────────────────────                                  ─────────────────────────
   • jsdom execution environment                              • Real Chromium, WebKit & Firefox
   • Prop matrix & conditional states                         • Zero SSR hydration mismatch detection
   • Accessible role queries (getByRole)                      • Visual snapshots (Light, Dark, BiDi RTL)
   • userEvent interactions                                   • Slow network & Suspense skeleton geometry
   • Mocked next/navigation & router                          • Instant shell assertions (@next/playwright)
   • NextIntlClientProvider wrapping                          • Multi-step user journey verification
```

---

## 2. Jest + RTL Unit Testing Standards (`[ComponentName].test.tsx`)

### Core Rules:
1. **Co-Location**: Keep `[ComponentName].test.tsx` co-located directly beside `[ComponentName].tsx`.
2. **User Event**: Always use `@testing-library/user-event` (e.g. `const user = userEvent.setup()`) instead of `fireEvent`.
3. **Semantic Role Queries**: Prioritize accessible queries (`screen.getByRole("button", { name: ... })`, `screen.getByRole("heading", { level: 2 })`) over arbitrary test IDs.
4. **`next-intl` Provider Wrapping**: Wrap components requiring translations in `NextIntlClientProvider` supplying the dictionary `messages` and active `locale`.
5. **Mocking Next.js Routing**:
   ```tsx
   jest.mock("next/navigation", () => ({
     useRouter: () => ({
       push: jest.fn(),
       replace: jest.fn(),
       prefetch: jest.fn(),
       back: jest.fn(),
     }),
     usePathname: () => "/en",
     useSearchParams: () => new URLSearchParams(),
   }));
   ```

---

## 3. Playwright Integration & Hydration Verification (`[ComponentName].spec.ts`)

### A. Zero SSR Hydration Mismatches
Always listen for browser console events and fail if React SSR hydration errors occur:
```ts
test("zero SSR hydration warnings and console errors", async ({ page }) => {
  const hydrationErrors: string[] = [];

  page.on("console", (msg) => {
    const text = msg.text();
    if (
      msg.type() === "error" ||
      text.includes("Hydration failed") ||
      text.includes("did not match") ||
      text.includes("hydration-mismatch")
    ) {
      hydrationErrors.push(text);
    }
  });

  await page.goto("/en/sample-page");
  expect(hydrationErrors).toHaveLength(0);
});
```

### B. Visual & BiDi RTL Regression Snapshots
Capture theme tokens and RTL layout snapshots:
```ts
test("visual regression snapshot across light, dark, and RTL", async ({ page }) => {
  // 1. Light Mode
  await page.goto("/en/sample-page");
  const component = page.locator('[data-testid="component-name"]');
  await expect(component).toHaveScreenshot("component-light.png");

  // 2. Dark Mode
  await page.evaluate(() => document.documentElement.classList.add("dark"));
  await expect(component).toHaveScreenshot("component-dark.png");

  // 3. BiDi RTL Mode
  await page.goto("/fa/sample-page");
  await expect(component).toHaveScreenshot("component-rtl.png");
});
```

---

## 4. Playwright Instant Navigation Testing (`@next/playwright`)

Use `@next/playwright`'s `instant()` helper to verify that static and prefetched App Shells render immediately before server streaming completes:

```ts
import { test, expect } from "@playwright/test";
import { instant } from "@next/playwright";

test.describe("Instant Navigation Assertions", () => {
  // Direct Hard Visit
  test("direct visit renders static shell instantly", async ({ page, baseURL }) => {
    await instant(
      page,
      async () => {
        await page.goto("/en/store/hats");
        await expect(page.locator("h1")).toContainText("Baseball Cap");
        await expect(page.getByTestId("live-inventory")).toHaveCount(0);
      },
      { baseURL }
    );
    await expect(page.getByTestId("live-inventory")).toBeVisible();
  });

  // Client Soft Navigation
  test("client navigation renders prefetched App Shell instantly", async ({ page }) => {
    await page.goto("/en/store/shoes");
    await instant(page, async () => {
      await page.click('a[href="/en/store/hats"]');
      await page.waitForURL((url) => url.pathname.includes("/store/hats"));
      await expect(page.locator("h1")).toContainText("Baseball Cap");
      await expect(page.getByTestId("live-inventory")).toHaveCount(0);
    });
    await expect(page.getByTestId("live-inventory")).toBeVisible();
  });
});
```

---

## 5. Verification Commands

* **Windows (PowerShell):**
  ```pwsh
  pwsh .agents/skills/nextjs-component-dev/scripts/verify-dev.ps1 -ComponentPath <target_component_dir>
  ```
* **Linux / macOS (Bash):**
  ```bash
  bash .agents/skills/nextjs-component-dev/scripts/verify-dev.sh <target_component_dir>
  ```
* **Targeted Playwright Spec:**
  ```bash
  pnpm test:e2e [ComponentName]
  ```
