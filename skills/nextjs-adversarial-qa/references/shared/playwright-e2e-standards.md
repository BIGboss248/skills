# Playwright E2E Standards (Components)

Browser-level verification for SSR, hydration, streaming, and visual behavior. Specs live under `tests/e2e/`, never co-located.

---

## 1. Location & Naming

```text
tests/e2e/
├── components/<page>/<ComponentName>.spec.ts
└── pages/<route>.spec.ts
```

- Co-located `.spec.tsx` collides with Jest's `testMatch` — forbidden.
- One spec per component or route. Use `test.describe` blocks for scenario families.
- Reuse fixtures from `tests/e2e/fixtures/` instead of duplicating setup.

---

## 2. Hydration Guard (Mandatory)

Every component and page spec starts with a hydration/console guard:

```ts
test("zero hydration warnings", async ({ page }) => {
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
  await page.goto("/en/target-route");
  expect(errors).toHaveLength(0);
});
```

- Filter out known third-party noise explicitly and document why.
- Never assert `toHaveLength(0)` before navigation settles.

---

## 3. Instant Navigation (`@next/playwright`)

```ts
import { instant } from "@next/playwright";

await instant(page, async () => {
  await page.goto("/en/store/hats");
  await expect(page.locator("h1")).toContainText("Baseball Cap");
  await expect(page.getByTestId("live-inventory")).toHaveCount(0);
}, { baseURL });

await expect(page.getByTestId("live-inventory")).toBeVisible();
```

- Assert the static shell **inside** the `instant` scope and streamed content **outside**.
- Requires `experimental.exposeTestingApiInProductionBuild: true` for `next start` runs.
- Test both hard navigation (`goto`) and soft navigation (click + `waitForURL`).

---

## 4. Visual Regression

```ts
await expect(component).toHaveScreenshot("component-light.png");
await page.evaluate(() => document.documentElement.classList.add("dark"));
await expect(component).toHaveScreenshot("component-dark.png");
await page.goto("/fa/target-route");
await expect(component).toHaveScreenshot("component-rtl.png");
```

- Always capture light, dark, and RTL variants.
- Mask dynamic regions (timestamps, counters, avatars) with `mask: [...]`.
- Set a deterministic viewport and `deviceScaleFactor` in `playwright.config.ts`.

---

## 5. Network & Suspense Geometry

```ts
await page.route("**/api/items", (route) =>
  route.fulfill({ status: 500, body: "boom" }),
);
await page.goto("/en/target-route");
await expect(page.getByRole("alert")).toBeVisible();
```

- Assert the skeleton's bounding box matches the resolved content box to prove zero CLS.
- Test slow responses with `route.fulfill({ delay })`, not `waitForTimeout`.
- Test 500 and malformed JSON separately.

---

## 6. Async RSC Verification

- Jest cannot execute async RSC; assert their streamed output here.
- Assert streamed content appears after the shell, using `expect(locator).toBeVisible()`.
- Assert the fallback disappears (`toHaveCount(0)`).

---

## 7. Flake Prevention

| Rule | Reason |
| :--- | :--- |
| `webServer` managed by Playwright config | No manual server lifecycle |
| No `waitForTimeout` | Use auto-waiting locators |
| Deterministic seeds/fixtures | Snapshot stability |
| `test.slow()` only for genuinely slow flows | Avoid masking races |
| `workers: 1` for visual suites | Snapshot consistency |
| No `test.only` committed | CI must run everything |

---

## 8. Anti-Patterns

| Anti-pattern | Fix |
| :--- | :--- |
| Asserting CSS class strings | Assert visible behavior and roles |
| Hardcoded absolute `http://localhost:3000` | Use `baseURL` from config |
| Screenshot of full page with dynamic ads | Mask or scope to component |
| One giant "happy path" test | Split per behavior |
| Ignoring console errors | Hydration guard fails the test |
