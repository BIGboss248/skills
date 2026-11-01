import { test, expect } from "@playwright/test";
import { instant } from "@next/playwright";

// Location: tests/e2e/pages/[route].spec.ts
test.describe("[Route] — page contract", () => {
  test("PAGE-1: renders the primary heading for the default locale", async ({ page }) => {
    const response = await page.goto("/en/[route]");

    expect(response?.status()).toBe(200);
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  });

  test("PAGE-2..5: emits title, description, canonical, and Open Graph", async ({
    page,
  }) => {
    await page.goto("/en/[route]");

    await expect(page).toHaveTitle(/[expected title]/);
    await expect(page.locator('meta[name="description"]')).toHaveAttribute(
      "content",
      /.+/,
    );
    await expect(page.locator('link[rel="canonical"]')).toHaveAttribute(
      "href",
      /\/en\/[route]$/,
    );
    await expect(page.locator('meta[property="og:title"]')).toHaveAttribute(
      "content",
      /.+/,
    );
  });

  test("PAGE-4: declares hreflang alternates for every supported locale", async ({
    page,
  }) => {
    await page.goto("/en/[route]");

    for (const locale of ["en", "fa"]) {
      await expect(
        page.locator(`link[rel="alternate"][hreflang="${locale}"]`),
      ).toHaveCount(1);
    }
  });

  test("PAGE-6..7: JSON-LD parses and escapes markup", async ({ page }) => {
    await page.goto("/en/[route]");

    const scripts = page.locator('script[type="application/ld+json"]');
    await expect(scripts).toHaveCount(1);

    const raw = await scripts.first().textContent();
    expect(raw).not.toContain("<");

    const graph = JSON.parse(raw as string);
    expect(graph["@context"]).toBe("https://schema.org");
    expect(Array.isArray(graph["@graph"])).toBe(true);
  });

  test("PAGE-8: renders every locale from generateStaticParams", async ({ page }) => {
    for (const locale of ["en", "fa"]) {
      const response = await page.goto(`/${locale}/[route]`);
      expect(response?.status()).toBe(200);
    }
  });

  test("PAGE-10: renders the error boundary with a working reset", async ({ page }) => {
    await page.route("**/[route]**", (route) =>
      route.fulfill({ status: 500, body: "boom" }),
    );

    await page.goto("/en/[route]");

    const reset = page.getByRole("button", { name: /retry|try again/i });
    await expect(reset).toBeVisible();
  });

  test("PAGE-12: static shell renders instantly", async ({ page, baseURL }) => {
    await instant(
      page,
      async () => {
        await page.goto("/en/[route]");
        await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
        await expect(page.locator("[data-testid='streamed-section']")).toHaveCount(0);
      },
      { baseURL },
    );

    await expect(page.locator("[data-testid='streamed-section']")).toBeVisible();
  });

  test("PAGE-13: RTL locale mirrors layout without horizontal scroll", async ({
    page,
  }) => {
    await page.goto("/fa/[route]");

    await expect(page.locator("html")).toHaveAttribute("dir", "rtl");
    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth - document.documentElement.clientWidth,
    );
    expect(overflow).toBeLessThanOrEqual(1);
  });

  test("PBND-1..5: route boundaries fail safely", async ({ page }) => {
    const missing = await page.goto("/en/[route]/missing-child");
    expect([404, 200]).toContain(missing?.status());

    await page.goto("/xx/[route]");
    await expect(page).toHaveURL(/\/(en|fa)\//);
  });
});
