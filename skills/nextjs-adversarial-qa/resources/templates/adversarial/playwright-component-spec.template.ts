import { test, expect } from "@playwright/test";
import { instant } from "@next/playwright";

// Location: tests/e2e/components/<page>/[ComponentName].spec.ts
test.describe("[ComponentName] — browser contract", () => {
  test("HYD-1: zero SSR hydration warnings and console errors", async ({ page }) => {
    const errors: string[] = [];

    page.on("console", (msg) => {
      const text = msg.text();
      if (
        msg.type() === "error" ||
        text.includes("Hydration failed") ||
        text.includes("did not match") ||
        text.includes("hydration-mismatch")
      ) {
        errors.push(text);
      }
    });

    await page.goto("/en/[target-route]");
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();

    expect(errors).toHaveLength(0);
  });

  test("instant shell renders before streamed content on hard load", async ({
    page,
    baseURL,
  }) => {
    await instant(
      page,
      async () => {
        await page.goto("/en/[target-route]");
        await expect(page.locator("[data-testid='component-name']")).toBeVisible();
        await expect(page.locator("[data-testid='dynamic-stream-slot']")).toHaveCount(0);
      },
      { baseURL },
    );

    await expect(page.locator("[data-testid='dynamic-stream-slot']")).toBeVisible();
  });

  test("instant shell renders on client navigation", async ({ page }) => {
    await page.goto("/en/[source-route]");

    await instant(page, async () => {
      await page.click("a[href='/en/[target-route]']");
      await page.waitForURL((url) => url.pathname.includes("/[target-route]"));
      await expect(page.locator("[data-testid='component-name']")).toBeVisible();
    });

    await expect(page.locator("[data-testid='dynamic-stream-slot']")).toBeVisible();
  });

  test("NET-4: renders the error boundary on a 500 response", async ({ page }) => {
    await page.route("**/api/[resource]", (route) =>
      route.fulfill({ status: 500, body: "boom" }),
    );

    await page.goto("/en/[target-route]");

    await expect(page.getByRole("alert")).toBeVisible();
  });

  test("NET-3: keeps skeleton geometry on a slow response", async ({ page }) => {
    await page.route("**/api/[resource]", async (route) => {
      await new Promise((resolve) => setTimeout(resolve, 1500));
      await route.continue();
    });

    await page.goto("/en/[target-route]");
    const skeleton = page.locator("[data-testid='component-skeleton']");
    const before = await skeleton.boundingBox();

    await expect(page.locator("[data-testid='component-name']")).toBeVisible();
    const after = await page
      .locator("[data-testid='component-name']")
      .boundingBox();

    expect(Math.abs((before?.height ?? 0) - (after?.height ?? 0))).toBeLessThan(8);
  });

  test("VIS-1: light, dark, and RTL snapshots are stable", async ({ page }) => {
    const component = page.locator("[data-testid='component-name']");

    await page.goto("/en/[target-route]");
    await expect(component).toHaveScreenshot("component-light.png", {
      mask: [page.locator("[data-dynamic]")],
    });

    await page.evaluate(() => document.documentElement.classList.add("dark"));
    await expect(component).toHaveScreenshot("component-dark.png", {
      mask: [page.locator("[data-dynamic]")],
    });

    await page.goto("/fa/[target-route]");
    await expect(component).toHaveScreenshot("component-rtl.png", {
      mask: [page.locator("[data-dynamic]")],
    });
  });
});
