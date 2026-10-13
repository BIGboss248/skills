import { test, expect } from "@playwright/test";
import { instant } from "@next/playwright";

test.describe("ComponentName Integration & Visual Tests", () => {
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

    await page.goto("/en");
    expect(hydrationErrors).toHaveLength(0);
  });

  test("renders static shell instantly on direct page load", async ({ page, baseURL }) => {
    await instant(
      page,
      async () => {
        await page.goto("/en/sample-route");
        // Assert static shell & cached component content render immediately
        const component = page.locator('[data-testid="component-name"]');
        await expect(component).toBeVisible();

        // Dynamic streaming elements are absent inside instant scope
        await expect(page.locator('[data-testid="dynamic-stream-slot"]')).toHaveCount(0);
      },
      { baseURL }
    );

    // Dynamic streaming content completes after instant transition finishes
    await expect(page.locator('[data-testid="dynamic-stream-slot"]')).toBeVisible();
  });

  test("renders prefetched App Shell instantly on client navigation", async ({ page }) => {
    await page.goto("/en/source-route");

    await instant(page, async () => {
      await page.click('a[href="/en/sample-route"]');
      await page.waitForURL((url) => url.pathname.includes("/sample-route"));

      const component = page.locator('[data-testid="component-name"]');
      await expect(component).toBeVisible();
      await expect(page.locator('[data-testid="dynamic-stream-slot"]')).toHaveCount(0);
    });

    await expect(page.locator('[data-testid="dynamic-stream-slot"]')).toBeVisible();
  });

  test("visual regression snapshot across light and dark themes", async ({ page }) => {
    await page.goto("/en");
    const component = page.locator('[data-testid="component-name"]');

    // Light theme snapshot
    await expect(component).toHaveScreenshot("component-light.png");

    // Dark theme snapshot
    await page.evaluate(() => document.documentElement.classList.add("dark"));
    await expect(component).toHaveScreenshot("component-dark.png");
  });

  test("BiDi RTL layout visual snapshot", async ({ page }) => {
    await page.goto("/fa");
    const component = page.locator('[data-testid="component-name"]');
    await expect(component).toHaveScreenshot("component-rtl.png");
  });
});
