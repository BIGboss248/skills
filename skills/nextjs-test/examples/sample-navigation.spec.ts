import { test, expect } from "@playwright/test";
import { instant } from "@next/playwright";

/**
 * Sample Instant Navigation & E2E Test Suite.
 *
 * Demonstrates:
 * 1. Initial page load (hard navigation) testing static shell + dynamic stream resolution.
 * 2. Client navigation (soft navigation) testing prefetched App Shell + dynamic stream resolution.
 */
test.describe("Navigation & Instant Shell Suite", () => {
  test("initial page load renders static shell instantly", async ({ page, baseURL }) => {
    // Scope assertions strictly to the UI available immediately upon initial load
    await instant(
      page,
      async () => {
        await page.goto("/en/store/hats");

        // Assert static shell & cached content are immediately visible
        await expect(page.locator("h1")).toBeVisible();
        await expect(page.getByTestId("static-nav-bar")).toBeVisible();

        // Assert dynamic streamed slots are not yet present inside the instant shell scope
        await expect(page.getByTestId("live-inventory-status")).toHaveCount(0);
      },
      { baseURL } // Pass baseURL so the instant helper resolves origin on direct page.goto()
    );

    // After instant() callback releases, dynamic server stream resolves:
    await expect(page.getByTestId("live-inventory-status")).toBeVisible();
  });

  test("client navigation renders prefetched App Shell instantly", async ({ page }) => {
    // Start at source page
    await page.goto("/en/store/shoes");

    // Scope assertions to UI rendered instantly upon clicking the prefetch Link
    await instant(page, async () => {
      await page.click('a[href="/en/store/hats"]');

      // Crucial: Wait for target URL pathname before asserting on destination UI
      await page.waitForURL((url) => url.pathname.includes("/store/hats"));

      // Assert destination prefetched shell & cached title render immediately
      await expect(page.locator("h1")).toBeVisible();
      await expect(page.getByTestId("live-inventory-status")).toHaveCount(0);
    });

    // Verify dynamic streamed content arrives after instant transition finishes
    await expect(page.getByTestId("live-inventory-status")).toBeVisible();
  });
});
