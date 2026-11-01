# Test Plan & Report Schema

Structured outputs so the orchestrator never has to parse prose.

---

## 1. `test-plan.md`

Scaffold: [`../../resources/templates/authoring/test-plan.template.md`](../../resources/templates/authoring/test-plan.template.md)

```markdown
# Test Plan: [Target]

- Mode: baseline | page | adversarial
- Target: <path or route>
- Spec: <spec path>
- Package manager: pnpm
- Locales: en, fa

## Coverage Matrix

| ID | Spec Ref | Scenario | Layer | File | Input / State | Expected Assertion | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| BND-1 | §7 Empty State | Empty collection | Jest | `[ComponentName].test.tsx` | `items=[]` | empty-state role visible | PENDING |
```

Rules:

- `Spec Ref` must point to a real section/row in the design spec or page plan.
- `Status` is one of `PENDING`, `PASS`, `FAIL`, `N/A (reason)`.
- `N/A` requires a reason; unexplained gaps are rejected.

---

## 2. `qa-report.md`

Scaffold: [`../../resources/templates/adversarial/qa-report.template.md`](../../resources/templates/adversarial/qa-report.template.md)

```markdown
## 🧪 QA Report: [Target]

| Field | Value |
| :--- | :--- |
| Mode | baseline |
| Spec | docs/design/components/home/hero/design-spec.md |
| Author role | Test Author Subagent |
| Files created | Hero.test.tsx |
| Command | pnpm test -- .../Hero.test.tsx |
| Exit code | 0 |
| Cases | 9 passed / 0 failed / 0 skipped |
| Coverage gaps | MOT-1 N/A (no animation) |
| Code fixes required | none |
| Verdict | PASS |
```

---

## 3. JSON Return Payload

Schema: [`../../resources/test-plan.schema.json`](../../resources/test-plan.schema.json)

```json
{
  "status": "PASS",
  "mode": "adversarial",
  "target": { "kind": "component", "name": "Hero", "path": "components/home/Hero" },
  "plan_path": "components/home/Hero/test-plan.md",
  "files_created": ["components/home/Hero/Hero.edge.test.tsx"],
  "commands": ["pnpm test -- components/home/Hero/Hero.edge.test.tsx"],
  "cases": { "passed": 8, "failed": 0, "skipped": 0 },
  "failures": [],
  "code_fixes_required": [],
  "coverage_gaps": [],
  "verdict": "PASS"
}
```

---

## 4. Verdict Rules

| Verdict | Condition |
| :--- | :--- |
| `PASS` | Exit code `0`, zero skipped, every plan row `PASS` or justified `N/A` |
| `FAIL` | Any failing assertion or unexplained gap |
| `BLOCKED` | Missing spec, missing target source, or missing runner script |

A report without a command and exit code is invalid.
