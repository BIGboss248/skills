# Agent & Subagent Test Protocol

Contract between the orchestrator (`nextjs-component-create`) and the two agents that own tests. Both are OpenCode project subagents installed by `nextjs-dev-setup`; their write boundaries are enforced by `permission.edit`, not by prompt text alone.

---

## 1. Why Two Agents

The implementer cannot certify its own edge cases. A separate context also prevents the author from inheriting assumptions made while writing the component. A second separation prevents the baseline author from grading its own coverage.

| Role | Agent | Modes | Writes |
| :--- | :--- | :--- | :--- |
| **Test Author** | `nextjs-test-author` | `baseline`, `page` | `<component_name>.test-plan.md`, `<component_name>.test.tsx`, `tests/e2e/pages/<route>.spec.ts` |
| **Adversarial Auditor** | `nextjs-qa-auditor` | `adversarial`, `audit` | `<component_name>.edge.test.tsx`, `tests/e2e/components/<surface>/<component_name>.spec.ts` |

Never let one agent perform both roles in the same run for the same target. This is enforced structurally: neither agent's `edit` allow-list covers the other's artifacts.

---

## 2. Write Boundaries (enforced)

| Path | `nextjs-test-author` | `nextjs-qa-auditor` | `nextjs-dev` |
| :--- | :--- | :--- | :--- |
| `*.test.ts(x)` | write | deny | deny |
| `*.edge.test.tsx` | deny | write (immutable after creation) | deny |
| `tests/e2e/pages/**` | write | deny | deny |
| `tests/e2e/components/**` | deny | write | deny |
| `<component_name>.test-plan.md` | write | read | deny |
| `*.tsx`, `messages/**`, `app/**` | deny | deny | write |
| `jest.config.*`, `playwright.config.*`, `package.json`, lockfiles | deny | deny | deny |
| `docs/plan/05-pages-and-components.md` | deny | deny | deny (orchestrator only) |

If an agent is denied a write it needs, it must report the need in its return payload. Working around the boundary with shell redirection is a protocol violation, not a shortcut.

---

## 3. Orchestrator → Agent Payload

```yaml
mode: baseline | page | adversarial | audit
target:
  kind: component | page
  name: ComponentName
  path: <new_component_dir>/<surface>/<component_name>.tsx
  route: app/[locale]/<route>/        # page mode only
spec:
  component: docs/design/components/<page>/<component>/design-spec.md
  page: docs/design/pages/<route>/page-spec.md
plan: <component_dir>/implementation_plan.md   # optional
project:
  config: docs/project.json
  package_manager: pnpm
  locales: [en, fa]
  dictionaries: messages
conventions:
  baseline_unit: <component_dir>/<component_name>.test.tsx
  edge_unit: <component_dir>/<component_name>.edge.test.tsx
  component_e2e: tests/e2e/components/<surface>/<component_name>.spec.ts
  page_e2e: tests/e2e/pages/<route>.spec.ts
rules:
  - Edge tests are immutable after creation.
  - Baseline tests may be revised only with a logged reason.
  - Fix the code, not the tests.
  - Targeted execution only.
  - No test.only / it.skip / placeholder assertions.
```

---

## 4. Return Payloads

Both agents return JSON only, with no prose before or after.

**Test Author**

```json
{
  "status": "PASS | FAIL | BLOCKED",
  "agent": "nextjs-test-author",
  "mode": "baseline",
  "plan_path": "...",
  "files_created": ["..."],
  "files_modified": ["..."],
  "revision_reasons": ["BND-3 assertion targeted the wrong role"],
  "commands": ["pnpm test -- <file>"],
  "failures": [{ "test": "BND-3", "reason": "..." }],
  "code_fixes_required": ["<component_name>.tsx: handle null items"],
  "coverage_gaps": ["MOT-1 not applicable: no animation"]
}
```

**QA Auditor**

```json
{
  "status": "PASS | FAIL | BLOCKED",
  "agent": "nextjs-qa-auditor",
  "mode": "adversarial",
  "worktree": { "branch": "agent/<slug>", "path": "..." },
  "tier": "fast",
  "files_created": ["..."],
  "commands": ["..."],
  "deferred_expensive_tests": ["tests/e2e/components/<surface>/<component_name>.spec.ts"],
  "cases": { "passed": 0, "failed": 0, "skipped": 0 },
  "failures": [{ "test": "BND-3", "severity": "major", "reason": "..." }],
  "code_fixes_required": ["..."],
  "coverage_gaps": ["..."],
  "immutable_edits": []
}
```

`immutable_edits` must be empty. A non-empty array means the auditor modified a previously created edge assertion; the orchestrator must reject the run and restore the file.

---

## 5. Prohibitions

Both test agents:

- Editing implementation files, dictionaries, or runner configuration.
- Running the full test suite, Playwright, or any production build during development (fast tier only).
- Reporting a deferred Playwright suite as `PASS`; it is `DEFERRED (pre-push)`.
- Writing outside the assigned `agent/<slug>` worktree.
- Creating dummy or sample tests outside the target directory.
- Adding dependencies.
- Asserting hardcoded English copy instead of dictionary-driven values.

Test Author additionally:

- Weakening coverage to accommodate a failing implementation.
- Revising an edge test (it cannot write them at all).
- Revising a baseline test without recording the reason.

QA Auditor additionally:

- Duplicating baseline coverage.
- Editing `*.test.tsx`.
- Deleting, skipping, or relaxing an edge assertion.

---

## 6. Repair Handoff

`repair` is an orchestrator loop, not an agent.

1. A suite fails; the owning agent returns `status: FAIL` with `failures[]` and `code_fixes_required[]`.
2. The orchestrator passes `code_fixes_required[]` to `nextjs-dev`.
3. `nextjs-dev` changes implementation only and reports `files_written[]` plus the command it ran.
4. The owning agent re-runs the **same** files and returns a fresh payload.
5. Repeat until exit `0`.

Escalation, in order:

- **Baseline test is wrong** → `nextjs-test-author` fixes it and records `revision_reasons[]`.
- **Edge test is wrong** (rare: wrong role name, wrong dictionary key) → stop and ask the user. The orchestrator applies the change itself and logs it. No test agent may edit an edge test.
- **Spec is ambiguous** → return `BLOCKED: ambiguous specification` with the exact rows in question.

---

## 7. Orchestrator Responsibilities

1. Verify the spec exists; otherwise return `BLOCKED`.
2. Pass absolute or repo-relative paths, never guesses.
3. Review the diff before accepting: paths, naming, no skipped tests.
4. Verify the agent did not write outside its boundary (see the write audit in the orchestrator skill).
5. Never accept `status: PASS` without command output.
6. Record the result in the orchestrator report and update `docs/plan/05-pages-and-components.md` itself.

---

## 8. Non-OpenCode Harnesses

When the target repository has no `.opencode/agents/` roster, the orchestrator may still run the pipeline, but it must:

1. Announce degraded mode: `DEGRADED: agent permissions unavailable`.
2. Spawn fresh contexts with [`../../resources/prompts/`](../../resources/prompts/) prompts.
3. Run the diff-class audit before reporting success, so boundary violations are caught after the fact rather than prevented.

Prompt templates:

- [Test Author](../../resources/prompts/authoring/test-author-subagent.md)
- [Adversarial Auditor](../../resources/prompts/adversarial/adversarial-auditor-subagent.md)
