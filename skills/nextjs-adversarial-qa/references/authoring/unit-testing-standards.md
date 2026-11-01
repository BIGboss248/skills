# Jest + React Testing Library Standards

Fast, deterministic, jsdom-level verification for Next.js App Router components.

---

## 1. Core Rules

1. **Co-location** — `[ComponentName].test.tsx` sits beside `[ComponentName].tsx`.
2. **userEvent only** — `const user = userEvent.setup()`; never `fireEvent`.
3. **Semantic queries** — `getByRole`, `getByLabelText`, `getByText` before `data-testid`.
4. **Real providers** — `NextIntlClientProvider` with `messages/[locale].json`, `QueryClientProvider` for TanStack.
5. **No snapshot-only tests** — snapshots may supplement behavior assertions, never replace them.
6. **Async discipline** — `await user.click(...)`, `await screen.findByRole(...)`, `waitFor` for eventual state.

---

## 2. Next.js Navigation Mocking

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

Mock `next/navigation` only. Do not mock `next-intl`; supply real dictionaries so missing keys fail loudly.

---

## 3. i18n Harness

```tsx
function renderWithIntl(ui: React.ReactElement, locale = "en") {
  return render(
    <NextIntlClientProvider locale={locale} messages={messages}>
      {ui}
    </NextIntlClientProvider>,
  );
}
```

- Assert the **translated** string, not the key.
- Assert `dir="rtl"` behavior for RTL locales.
- Assert `Intl`-formatted currency/date output for the active locale.

---

## 4. RSC Handling

| Component type | Approach |
| :--- | :--- |
| Synchronous RSC | `const jsx = await Component(props); render(<Provider>{jsx}</Provider>)` |
| `async` RSC with data | Test in Playwright; do not mock the data layer in Jest |
| Client leaf | Render directly with props |
| Suspense boundary | Render inside `<Suspense fallback={<Skeleton />}>` and assert fallback, then resolved state |

---

## 5. QueryClient Harness

```tsx
const testClient = new QueryClient({
  defaultOptions: { queries: { retry: false, gcTime: Infinity } },
});
testClient.setQueryData(cache.key(id), fixture);
```

- Seed cache instead of mocking `fetch` when the component uses `useSuspenseQuery`.
- Assert loading skeleton, success, and error states separately.

---

## 6. Accessibility Assertions

- `jest-axe`: `const { container } = render(...); expect(await axe(container)).toHaveNoViolations();`
- Assert `aria-expanded`, `aria-busy`, `aria-live`, `aria-invalid`, `role`, and accessible names.
- Assert visible focus is reachable by keyboard (`user.tab()`), not by CSS inspection.

---

## 7. Structure

```tsx
describe("[ComponentName]", () => {
  describe("rendering", () => { /* defaults, variants */ });
  describe("interactions", () => { /* callbacks, state */ });
  describe("states", () => { /* loading, empty, error */ });
});
```

- One `describe` per behavior family.
- Test names state the expected behavior: `"renders empty state when items is []"`.
- No shared mutable fixtures between tests.

---

## 8. Anti-Patterns

| Anti-pattern | Fix |
| :--- | :--- |
| `expect(container).toMatchSnapshot()` alone | Assert roles, text, ARIA state |
| Mocking `useTranslations` | Real `NextIntlClientProvider` |
| `await new Promise(r => setTimeout(r, 500))` | `findBy*` / `waitFor` / fake timers |
| Asserting Tailwind class strings as behavior | Assert computed intent (visible, disabled, expanded) |
| Testing the skeleton twice | Once in baseline, once in adversarial is enough |
| `jest.mock` of the component under test | Never mock the subject |
