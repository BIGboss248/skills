# Test Plan: [TargetName]

- **Mode**: `baseline` | `page` | `adversarial` | `audit`
- **Target Kind**: `component` | `page`
- **Target Path**: `<new_component_dir>/<page_or_global>/[ComponentName]/` or `app/[locale]/<route>/`
- **Specification**: `docs/design/components/<page>/<component>/design-spec.md` or `docs/plan/05-pages-and-components.md`
- **Implementation Plan**: `<component_dir>/implementation_plan.md` (optional)
- **Package Manager**: `pnpm`
- **Locales**: `en`, `fa`
- **Dictionaries**: `messages/`

---

## 1. Scope

- **In scope**: [behaviors, states, and boundaries covered by this plan]
- **Out of scope**: [behaviors delegated to another layer, with reason]

---

## 2. Coverage Matrix

| ID | Spec Ref | Scenario | Layer | File | Input / State | Expected Assertion | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| BND-1 | §7 Empty State | Empty collection | Jest | `[ComponentName].test.tsx` | `items=[]` | Empty-state copy visible | PENDING |
| BND-2 | §7 Null Safety | Optional props omitted | Jest | `[ComponentName].test.tsx` | `title={undefined}` | Documented defaults applied | PENDING |
| PROP-1 | §7 Prop Matrix | Conflicting flags | Jest | `[ComponentName].test.tsx` | `isLoading + error` | Error wins deterministically | PENDING |
| A11Y-2 | §9 Accessibility | Keyboard activation | Jest | `[ComponentName].test.tsx` | `Enter`, `Space` | Callback fires twice | PENDING |
| I18N-1 | §8 RTL | Persian glyphs | Jest | `[ComponentName].edge.test.tsx` | `locale="fa"` | `dir="rtl"`, no clipping | PENDING |
| HYD-1 | §7 Hydration | SSR/CSR parity | Playwright | `tests/e2e/components/<page>/[ComponentName].spec.ts` | hard load | Zero console errors | PENDING |
| VIS-1 | §7 Viewport | Light/dark/RTL | Playwright | `tests/e2e/components/<page>/[ComponentName].spec.ts` | snapshots | Stable snapshots | PENDING |
| PAGE-2 | Plan §5 | Metadata | Playwright | `tests/e2e/pages/<route>.spec.ts` | `/en/<route>` | Title + description | PENDING |

---

## 3. Execution Commands

```bash
pnpm test -- <component_dir>/[ComponentName].test.tsx
pnpm test -- <component_dir>/[ComponentName].edge.test.tsx
pnpm test:e2e tests/e2e/components/<page>/[ComponentName].spec.ts
pnpm test:e2e tests/e2e/pages/<route>.spec.ts
```

---

## 4. Risks & Notes

- [Flaky areas, environment requirements, snapshot policy]
