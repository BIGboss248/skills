---
name: nextjs-adversarial-qa
description: >-
  Author and adversarially audit Jest/RTL and Playwright suites for Next.js components and pages. Triggers on "/nextjs-adversarial-qa", "write tests", "audit tests", or "repair failing suite".
metadata:
  author: BIGboss248
  version: "3.0"
---

# Next.js Test Authoring & Adversarial QA (`nextjs-adversarial-qa`)

Single source of truth for planning, authoring, executing, and hardening Next.js App Router test suites for **components and pages**. Work is split across two OpenCode agents with hard write boundaries; this skill holds the material for both.

> [!IMPORTANT]
> **Material is partitioned by role.** Each agent reads only its own subtree. Shared rules live in exactly one place so the two roles cannot drift.
> - **Shared:** [`references/shared/`](./references/shared/) — strategy, E2E mechanics, pitfalls, protocol, schemas
> - **Test Author:** [`references/authoring/`](./references/authoring/) + [`templates/authoring/`](./resources/templates/authoring/)
> - **QA Auditor:** [`references/adversarial/`](./references/adversarial/) + [`templates/adversarial/`](./resources/templates/adversarial/)
> - **Prompts / payloads:** [`resources/prompts/`](./resources/prompts/)
> - **Verification:** [`scripts/verify-qa.ps1`](./scripts/verify-qa.ps1) / [`.sh`](./scripts/verify-qa.sh)
> - **Execution tiers (fast vs pre-push):** [`references/shared/test-execution-tiers.md`](./references/shared/test-execution-tiers.md)

---

## Execution Tiers

Development runs the **fast** tier only. Expensive suites run **pre-push**.

| Tier | What runs | When |
| :--- | :--- | :--- |
| **Fast** | The targeted Jest file(s) under test | Every development loop |
| **Expensive** | Playwright component/page E2E, full Jest, build, Storybook build | `.husky/pre-push`, CI, or an explicit user request |

- Authoring is not execution: E2E specs are still written now, statically
  audited, and declared in `deferred_expensive_tests[]`.
- Never start a browser to debug. Never run the whole Jest project during
  iteration.
- A deferred suite is reported `DEFERRED (pre-push)`, never `PASS`.
- Full policy: [`references/shared/test-execution-tiers.md`](./references/shared/test-execution-tiers.md).

---

## Roles & Write Boundaries

| Role | Agent | Modes | May write | Must never write |
| :--- | :--- | :--- | :--- | :--- |
| **Test Author** | `nextjs-test-author` | `baseline`, `page` | `<component_name>.test-plan.md`, `*.test.ts(x)`, `tests/e2e/pages/**` | components, pages, dictionaries, runner configs, `package.json` |
| **QA Auditor** | `nextjs-qa-auditor` | `adversarial`, `audit` | `*.edge.test.tsx`, `tests/e2e/components/**`, QA report | components, pages, baseline tests, runner configs |
| **Orchestrator** | `nextjs-orchestrator` | — | delegates, runs gates, ticks plan | test or implementation code |

`repair` is not a test role: the **dev agent** fixes implementation and the **auditor** re-runs. A test agent that reports `code_fixes_required` is behaving correctly.

---

## Operating Modes

| Mode | Agent | Invoked when | Deliverables |
| :--- | :--- | :--- | :--- |
| `baseline` | `nextjs-test-author` | Spec approved, **before** JSX (TDD gate) | `<component_name>.test-plan.md` + `<component_name>.test.tsx` |
| `page` | `nextjs-test-author` | Page spec approved and route implemented | `tests/e2e/pages/<route>.spec.ts` |
| `adversarial` | `nextjs-qa-auditor` | Implementation and baseline complete | `<component_name>.edge.test.tsx` (immutable) + `tests/e2e/components/<surface>/<component_name>.spec.ts` |
| `audit` | `nextjs-qa-auditor` | Existing suite review | Coverage-gap report against the spec, no rewrites |
| `repair` | orchestrator-loop | Any suite fails | dev fixes code → auditor re-runs until exit `0` |

Never invent a mode. Infer from artifacts: no test file → `baseline`; test file but no edge file → `adversarial`; route exists but no page spec → `page`.

---

## Required Inputs

1. **`docs/project.json`** — `package_manager`, `new_component_dir`, `dictionaries_dir`, `supported_languages`, test scripts, agent roster.
2. **Specification** — component `design-spec.md` §7 *Edge Cases & Boundary States*, or `page-spec.md` §7 for pages.
3. **Implementation plan** — `implementation_plan.md` §5 (TDD matrix) when present.
4. **Target source** — `<component_name>.tsx`, `<component_name>_skeleton.tsx`, `page.tsx`, `loading.tsx`, `error.tsx`, `messages/[locale].json`.
5. **Existing suite** — to avoid duplicate coverage.

If the spec is missing, stop and return `BLOCKED: missing specification` to the orchestrator. Never guess requirements.

---

## Architectural Rules

1. **Unbiased Auditor Principle** — the agent that wrote the component or page must not certify its edge cases, and the author of the baseline suite must not author the edge suite.
2. **Spec Traceability** — every §7 edge case maps to a test ID (`BND-1`, `PROP-2`, `PAGE-4`). Unmapped spec rows are a defect.
3. **Immutable Adversarial Tests** — deleting, skipping, or weakening `*.edge.test.tsx` is forbidden; only an explicit user decision may change one, and the change is logged in the QA report.
4. **Baseline Tests Are Mutable With a Reason** — `nextjs-test-author` may revise a baseline test when the spec changed or the assertion was wrong, recording the reason in `<component_name>.test-plan.md`. It may never weaken coverage to make a failing implementation pass.
5. **Fix the Code, Not the Tests** — a failing assertion means the implementation is wrong until proven otherwise.
6. **Targeted Execution** — run only the files under test. Never the full suite during iteration.
7. **Fast Tier During Development** — Jest only; Playwright, the full Jest project, builds, and Storybook builds are deferred to the pre-push gate and declared in `deferred_expensive_tests[]`.
8. **Zero Placeholder Tests** — no `it.skip`, `test.fixme`, `test.only`, empty bodies, or assertions that cannot fail.
9. **Real Providers** — wrap with the real `NextIntlClientProvider` (dictionary messages) and `QueryClientProvider`. Mocking translations hides i18n defects.
10. **Deterministic Async** — `userEvent.setup()`, `findBy*`/`waitFor`, fake timers, and teardown of subscriptions.

---

## Workflow

- [ ] **Step 0: Load Context & Detect Stack** (orchestrator)
  - Read `docs/project.json`, resolve package manager and test scripts, locate spec and targets.

- [ ] **Step 1: Build the Test Plan** (`nextjs-test-author`)
  - Scaffold from [`test-plan.template.md`](./resources/templates/authoring/test-plan.template.md).
  - Enumerate every spec edge case with an ID, layer, input, and expected assertion.
  - Select layers using [`test-strategy-matrix.md`](./references/shared/test-strategy-matrix.md).

- [ ] **Step 2: Author the Baseline / Page Suite** (`nextjs-test-author`)
  - Read [`unit-testing-standards.md`](./references/authoring/unit-testing-standards.md) or [`page-testing-standards.md`](./references/authoring/page-testing-standards.md).
  - Write files at exactly the paths in the payload; run only those files.
  - Jest files run immediately (fast tier). Playwright files are authored, statically audited, and **deferred** to pre-push.

- [ ] **Step 3: Baseline Gate** (orchestrator)
  - Green baseline before implementation proceeds (TDD gate). For Jest that means a real execution; for a Playwright page suite it means authored + audited + `DEFERRED (pre-push)`.

- [ ] **Step 4: Adversarial Audit** (`nextjs-qa-auditor`)
  - Read [`adversarial-test-matrix.md`](./references/adversarial/adversarial-test-matrix.md).
  - Diff baseline coverage against spec §7, then write the immutable edge suite and component E2E spec.
  - Return `code_fixes_required[]`; never touch implementation.
  - Do not launch a browser. The component E2E spec is deferred.

- [ ] **Step 5: Execute & Repair** (orchestrator loop)
  - Run edge + page suites through `verify-qa` in the fast tier (Jest only).
  - On failure, route `code_fixes_required` to the dev agent, then re-run.
  - Re-run until exit code `0`. Consult [`pitfalls.md`](./references/shared/pitfalls.md) before blaming a test.
  - Expensive suites are exercised by the pre-push gate; a failure there reopens this loop.

- [ ] **Step 6: Report & Handoff**
  - Fill [`qa-report.template.md`](./resources/templates/adversarial/qa-report.template.md) and return it as the final message. Do not write the report to disk — the auditor has no edit permission outside its test artifacts.
  - Return the report, test file paths, and exact commands to the orchestrator.

---

## Test Layer Matrix (Summary)

| Artifact | Suite | Path | Runner |
| :--- | :--- | :--- | :--- |
| Component props/state/a11y | Jest + RTL | `<component_dir>/<component_name>.test.tsx` | `<pm> test` |
| Component edge cases | Jest + RTL | `<component_dir>/<component_name>.edge.test.tsx` | `<pm> test` |
| Component hydration/visual/instant | Playwright | `tests/e2e/components/<surface>/<component_name>.spec.ts` | `<pm> test:e2e` |
| Page metadata/JSON-LD/routes/boundaries | Playwright | `tests/e2e/pages/<route>.spec.ts` | `<pm> test:e2e` |
| Async RSC output | Playwright (only option) | same as above | `<pm> test:e2e` |

---

## Verification & Self-Check

```bash
# Component — fast tier (default): static audit + targeted Jest, Playwright deferred
pwsh .agents/skills/nextjs-adversarial-qa/scripts/verify-qa.ps1 -TargetPath <component_dir> -Mode all

# Page suite — fast tier: suite authored and audited, Playwright deferred
pwsh .agents/skills/nextjs-adversarial-qa/scripts/verify-qa.ps1 -TargetPath <route_dir> -Mode page

# Expensive tier — pre-push / CI / explicit user request only
pwsh .agents/skills/nextjs-adversarial-qa/scripts/verify-qa.ps1 -TargetPath <component_dir> -Mode all -Tier full

# Linux / macOS
bash .agents/skills/nextjs-adversarial-qa/scripts/verify-qa.sh <component_dir> all
bash .agents/skills/nextjs-adversarial-qa/scripts/verify-qa.sh <route_dir> page
bash .agents/skills/nextjs-adversarial-qa/scripts/verify-qa.sh <component_dir> all --tier full
```

- [ ] Fast suites exit `0` with zero skipped tests.
- [ ] Every deferred Playwright file is listed in `deferred_expensive_tests[]`; nothing deferred is reported as `PASS`.
- [ ] Every `<component_name>.test-plan.md` row has a status of `PASS` or `DEFERRED`.
- [ ] `*.edge.test.tsx` exists and was authored by `nextjs-qa-auditor`.
- [ ] No `test.only`, `it.skip`, or `test.fixme` in any created file.
- [ ] No hardcoded English copy asserted in place of dictionary values.
- [ ] Page suite asserts metadata, JSON-LD, locale routing, and error boundary.
- [ ] Every baseline revision is logged with a reason.
- [ ] No browser was launched during development.

---

## Edge Cases & Known AI Pitfalls

| Pitfall | Correct Behavior |
| :--- | :--- |
| Testing async RSC directly in jsdom | Assert through Playwright; Jest cannot await server components |
| Mocking `useTranslations` | Wrap with `NextIntlClientProvider` and real dictionary messages |
| `fireEvent` instead of `userEvent` | Use `@testing-library/user-event` |
| Snapshot-only assertions | Assert roles, text, ARIA state, and geometry classes |
| Co-located `.spec.tsx` | Put Playwright specs under `tests/e2e/` |
| Asserting implementation details | Assert user-visible behavior and the accessibility contract |
| Fixed `setTimeout` waits | Use `findBy*`, `waitFor`, or fake timers |
| Weakening an edge test to pass CI | Fix the component; edge tests are immutable |
| Test agent editing the component "to unblock" | Forbidden by permission; return `code_fixes_required` |
| Running Playwright to "check quickly" during development | Defer it; declare it in `deferred_expensive_tests[]` |
| Running the whole Jest project during iteration | Run only the file under test |
| Reporting a deferred suite as `PASS` | Report `DEFERRED (pre-push)` |

Full catalogue: [`references/shared/pitfalls.md`](./references/shared/pitfalls.md).

---

## Reference Index

**Shared**
- [Test Strategy Matrix](./references/shared/test-strategy-matrix.md) — layer selection and gates.
- [Test Execution Tiers](./references/shared/test-execution-tiers.md) — fast vs expensive, pre-push gate, deferral contract.
- [Playwright E2E Standards](./references/shared/playwright-e2e-standards.md) — hydration, instant navigation, visual, network.
- [Subagent & Agent Protocol](./references/shared/subagent-test-author-protocol.md) — role contract and return payloads.
- [Test Plan & Report Schema](./references/shared/test-plan-and-report-schema.md) — output contract.
- [Pitfalls](./references/shared/pitfalls.md) — anti-patterns and fixes.

**Test Author**
- [Unit Testing Standards](./references/authoring/unit-testing-standards.md) — Jest + RTL rules.
- [Page Testing Standards](./references/authoring/page-testing-standards.md) — metadata, JSON-LD, routing, boundaries.

**QA Auditor**
- [Adversarial Test Matrix](./references/adversarial/adversarial-test-matrix.md) — edge-case taxonomy.

**Prompts**
- [Test Author payload](./resources/prompts/authoring/test-author-subagent.md)
- [Adversarial Auditor payload](./resources/prompts/adversarial/adversarial-auditor-subagent.md)
