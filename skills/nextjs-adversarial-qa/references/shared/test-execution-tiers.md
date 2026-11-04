# Test Execution Tiers (Fast vs Expensive)

Canonical policy for **when** a Next.js suite may run. Authoring rules live in
`references/authoring/` and `references/adversarial/`; this file only decides
which runner is allowed to start, and when.

The rule is simple: **development runs fast tests only. Expensive tests run
pre-push.**

---

## 1. Tier Definitions

| Tier | Suites | Target time | Runs during development | Runs pre-push |
| :--- | :--- | :--- | :--- | :--- |
| **Fast** | Targeted Jest file(s) under test (`<pm> test -- <file>`) | < 30 s | **Yes — always** | Yes |
| **Expensive** | Playwright component + page E2E, full Jest suite, `build`, Storybook smoke/build | minutes | **No — never** | **Yes — mandatory** |

Anything that starts a browser, compiles a production bundle, or walks the whole
test directory is expensive. A single Jest file is fast. A directory of Jest
files is expensive.

### Expensive by definition

- `<pm> run test:e2e` and any bare `<pm> exec playwright test` (spawns a browser
  + `next build`/`next start` through `webServer`).
- Bare `<pm> test` with no file argument (whole Jest project).
- `test:all`, `test:coverage`, `test:ci`.
- `next build`, `storybook build`, `storybook dev --smoke-test`.
- Visual regression and snapshot baselines.

### Fast by definition

- `<pm> test -- <path>/<ComponentName>.test.tsx`
- `<pm> test -- <path>/<ComponentName>.edge.test.tsx`
- `verify-dev`, `verify-page`, `audit-agent-writes`, `verify-qa -NoRun` /
  `--no-run` (static audits, no runner).

---

## 2. The Development Contract

1. **Never start a browser during component or page development.** Playwright is
   not a debugging loop. If a browser is genuinely required to observe a defect,
   say so, finish the change, and let pre-push run it.
2. **Never run the full Jest project during iteration.** Always pass the file
   paths under test.
3. **Authoring still happens now.** Page/component E2E specs are written by
   `nextjs-test-author` and `nextjs-qa-auditor` in this session. Authoring is not
   execution: the file is written, statically audited, and **explicitly deferred**.
4. **Every deferral is declared.** Each agent return carries
   `deferred_expensive_tests: []` naming the exact files and the command that will
   run them. Silent deferral is a contract violation.
5. **A deferred suite is not a passing suite.** Never write `all suites green` or
   `PASS` for something that was not executed. Use `DEFERRED (pre-push)`.
6. **The pre-push gate is the acceptance gate** for the expensive tier. It is the
   only place a full browser suite legitimately runs locally.

---

## 3. Command Surface

Required `package.json` scripts (deployed by `nextjs-dev-setup` N5/N6/N12):

```json
{
  "scripts": {
    "test": "jest --passWithNoTests",
    "test:fast": "jest --passWithNoTests --findRelatedTests",
    "test:e2e": "playwright test --pass-with-no-tests",
    "test:all": "jest --passWithNoTests && playwright test --pass-with-no-tests",
    "test:prepush": "pnpm run test:all"
  }
}
```

`.husky/pre-push` runs the expensive gate:

```bash
pnpm run test:prepush
```

### Verification scripts

| Script | Default tier | Expensive behaviour |
| :--- | :--- | :--- |
| `verify-dev` | fast | static only, never executes tests |
| `verify-page` | fast | static only |
| `verify-qa` | `-Tier fast` | Jest only; Playwright files audited and deferred |
| `verify-qa -Tier full` | full | Jest **and** Playwright — pre-push/CI only |
| `verify-component-create` | `-Tier fast` | fast QA gate; prints the deferred gate |
| `verify-component-create -Tier full` | full | all gates, pre-push/CI only |

`-Tier full` / `--tier full` is reserved for the pre-push hook, CI, and an
explicit user request. An agent never selects it on its own initiative.

---

## 4. Escalation

| Situation | Action |
| :--- | :--- |
| Fast suite fails | Fix the implementation, re-run the same file |
| Fast suite cannot express the behavior (async RSC, hydration) | Defer to the Playwright spec; never `await` an RSC in jsdom |
| Deferred suite fails at pre-push | Open the repair loop as a normal failure; the fast tier stays fast |
| User asks for a browser run mid-development | Allowed, on explicit instruction only; record it in the report |
| Pre-push hook missing or misconfigured | Report `BLOCKED: pre-push gate missing - run nextjs-dev-setup N12`; do not substitute a full local run |

---

## 5. Reporting

Every agent return and every execution report states the tier outcome:

```json
{
  "tier": "fast",
  "executed": ["components/home/Hero/Hero.test.tsx (12 passed)"],
  "deferred_expensive_tests": [
    "tests/e2e/components/home/Hero.spec.ts",
    "pnpm run test:e2e tests/e2e/components/home/Hero.spec.ts"
  ]
}
```

In markdown reports use `[PASSED]`, `[DEFERRED]`, or `[FAILED]` — never
`[PASSED]` for a deferred suite.
