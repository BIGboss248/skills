import { test, expect } from "@playwright/test";
import { instant } from "@next/playwright";

// Location in a real project: tests/e2e/pages/about.spec.ts
test.describe("About page — page contract", () => {
  test("PAGE-1: renders the primary heading", async ({ page }) => {
    const response = await page.goto("/en/about");

    expect(response?.status()).toBe(200);
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  });

  test("PAGE-2..5: emits localized metadata and alternates", async ({ page }) => {
    await page.goto("/en/about");

    await expect(page).toHaveTitle(/About/i);
    await expect(page.locator('meta[name="description"]')).toHaveAttribute(
      "content",
      /.+/,
    );
    await expect(page.locator('link[rel="canonical"]')).toHaveAttribute(
      "href",
      /\/en\/about$/,
    );

    for (const locale of ["en", "fa"]) {
      await expect(
        page.locator(`link[rel="alternate"][hreflang="${locale}"]`),
      ).toHaveCount(1);
    }
  });

  test("PAGE-6..7: JSON-LD parses and escapes markup", async ({ page }) => {
    await page.goto("/en/about");

    const scripts = page.locator('script[type="application/ld+json"]');
    await expect(scripts).toHaveCount(1);

    const raw = await scripts.first().textContent();
    expect(raw).not.toContain("<");

    const graph = JSON.parse(raw as string);
    expect(graph["@context"]).toBe("https://schema.org");
    expect(Array.isArray(graph["@graph"])).toBe(true);
  });

  test("PAGE-8: renders every supported locale", async ({ page }) => {
    for (const locale of ["en", "fa"]) {
      const response = await page.goto(`/${locale}/about`);
      expect(response?.status()).toBe(200);
    }
  });

  test("PAGE-12: static shell renders before streamed sections", async ({
    page,
    baseURL,
  }) => {
    await instant(
      page,
      async () => {
        await page.goto("/en/about");
        await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
        await expect(page.locator("[data-testid='streamed-section']")).toHaveCount(0);
      },
      { baseURL },
    );

    await expect(page.locator("[data-testid='streamed-section']")).toBeVisible();
  });

  test("PAGE-13: RTL locale mirrors without horizontal scroll", async ({ page }) => {
    await page.goto("/fa/about");

    await expect(page.locator("html")).toHaveAttribute("dir", "rtl");
    const overflow = await page.evaluate(
      () =>
        document.documentElement.scrollWidth -
        document.documentElement.clientWidth,
    );
    expect(overflow).toBeLessThanOrEqual(1);
  });

  test("PBND-1..5: route boundaries fail safely", async ({ page }) => {
    const missing = await page.goto("/en/about/missing-child");
    expect([200, 404]).toContain(missing?.status());

    await page.goto("/xx/about");
    await expect(page).toHaveURL(/\/(en|fa)\//);
  });
});
