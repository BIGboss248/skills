# Test Plan: [TargetName]

- **Mode**: `baseline` | `page` | `adversarial` | `audit`
- **Target Kind**: `component` | `page`
- **Target Path**: `<new_component_dir>/<surface>/<component_name>.tsx` (flat file in its page/layout-region folder) or `app/[locale]/<route>/`
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
| BND-1 | §7 Empty State | Empty collection | Jest | `<component_name>.test.tsx` | `items=[]` | Empty-state copy visible | PENDING |
| BND-2 | §7 Null Safety | Optional props omitted | Jest | `<component_name>.test.tsx` | `title={undefined}` | Documented defaults applied | PENDING |
| PROP-1 | §7 Prop Matrix | Conflicting flags | Jest | `<component_name>.test.tsx` | `isLoading + error` | Error wins deterministically | PENDING |
| A11Y-2 | §9 Accessibility | Keyboard activation | Jest | `<component_name>.test.tsx` | `Enter`, `Space` | Callback fires twice | PENDING |
| I18N-1 | §8 RTL | Persian glyphs | Jest | `<component_name>.edge.test.tsx` | `locale="fa"` | `dir="rtl"`, no clipping | PENDING |
| HYD-1 | §7 Hydration | SSR/CSR parity | Playwright | `tests/e2e/components/<surface>/<component_name>.spec.ts` | hard load | Zero console errors | PENDING |
| VIS-1 | §7 Viewport | Light/dark/RTL | Playwright | `tests/e2e/components/<surface>/<component_name>.spec.ts` | snapshots | Stable snapshots | PENDING |
| PAGE-2 | Plan §5 | Metadata | Playwright | `tests/e2e/pages/<route>.spec.ts` | `/en/<route>` | Title + description | PENDING |

---

## 3. Execution Commands

```bash
# Fast tier — run during development
pnpm test -- <component_dir>/<component_name>.test.tsx
pnpm test -- <component_dir>/<component_name>.edge.test.tsx

# Expensive tier — authored now, executed at git push (.husky/pre-push)
pnpm test:e2e tests/e2e/components/<surface>/<component_name>.spec.ts
pnpm test:e2e tests/e2e/pages/<route>.spec.ts
```

Status column: use `PASS` for an executed suite, `DEFERRED` for an authored-but-unrun
Playwright suite. Never mark a deferred suite `PASS`.

---

## 4. Risks & Notes

- [Flaky areas, environment requirements, snapshot policy]
