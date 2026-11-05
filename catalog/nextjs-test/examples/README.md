# Examples

Canonical worked examples for `nextjs-test`. They pair with the component sources in `skills/nextjs-component-dev/examples/`; copy the pattern, not the literals.

## Component baseline

| File | Demonstrates |
| :--- | :--- |
| [`component-baseline/FeatureCard.test.tsx`](./component-baseline/FeatureCard.test.tsx) | Awaiting a synchronous RSC, real `NextIntlClientProvider`, localized link assertion, skeleton geometry |
| [`component-baseline/ProductCard.test.tsx`](./component-baseline/ProductCard.test.tsx) | Seeded `QueryClient`, `useSuspenseQuery` inside `<Suspense>`, skeleton fallback |

Both import from `./FeatureCard` / `./ProductCard`. To run them, copy beside the corresponding component from `nextjs-component-dev/examples/`.

## Page suite

| File | Demonstrates |
| :--- | :--- |
| [`page-suite/about.spec.ts`](./page-suite/about.spec.ts) | Metadata, canonical, hreflang, JSON-LD graph, locale coverage, instant shell, RTL overflow, route boundaries |

Place page specs at `tests/e2e/pages/<route>.spec.ts` in the target project.

## Related

- Templates: [`../resources/templates/`](../resources/templates/)
- Edge taxonomy: [`../references/adversarial/adversarial-test-matrix.md`](../references/adversarial/adversarial-test-matrix.md)
