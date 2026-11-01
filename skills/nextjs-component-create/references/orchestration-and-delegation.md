# Orchestration & Delegation

Contract for the `nextjs-component-create` master orchestrator: how it delegates,
what each agent may write, how failures route, and how the write audit proves the
boundaries held.

---

## 1. Agent Roster

Installed by `nextjs-dev-setup` into `.opencode/agents/`.

| Agent | Mode | Spawned by | Skill it loads |
| :--- | :--- | :--- | :--- |
| `nextjs-orchestrator` | primary | user (`Tab`, `/create-nextjs-*`) | `nextjs-component-create` |
| `nextjs-dev` | subagent | orchestrator | `nextjs-component-dev` / `nextjs-page-dev` |
| `nextjs-test-author` | subagent | orchestrator | `nextjs-adversarial-qa` (`baseline`, `page`) |
| `nextjs-qa-auditor` | subagent | orchestrator | `nextjs-adversarial-qa` (`adversarial`, `audit`) |

Spawn with the `task` tool naming the agent explicitly:

```
task(agent: "nextjs-test-author", prompt: <payload>)
```

The orchestrator's `permission.task` allows only these three names. A role agent's
`task` is denied, so delegation cannot recurse.

---

## 2. Write Matrix

| Path class | orchestrator | dev | test-author | qa-auditor |
| :--- | :--- | :--- | :--- | :--- |
| `app/**`, `components/**`, `lib/**`, `hooks/**` | approve | write | deny | deny |
| `messages/**` | approve | write | deny | deny |
| `docs/design/**` | write | read | read | read |
| `docs/plan/05-pages-and-components.md` | write | deny | deny | deny |
| `*.test.ts(x)` | escalate | deny | write | deny |
| `*.edge.test.tsx` | user-approved only | deny | deny | write |
| `tests/e2e/pages/**` | escalate | deny | write | deny |
| `tests/e2e/components/**` | escalate | deny | deny | write |
| `test-plan.md` | approve | deny | write | read |
| `package.json`, lockfiles, `jest.config.*`, `playwright.config.*`, `next.config.*` | user only | deny | deny | deny |

`approve` = coordinates but does not perform. `escalate` = requires a user decision
before any write.

---

## 3. Handoff Payload

Every delegation carries the same envelope. Agents never guess paths.

```yaml
mode: baseline | page | implement | adversarial | audit | repair
target:
  kind: component | page
  name: ComponentName | <route>
  path: <new_component_dir>/<page>/<ComponentName>/ | app/[locale]/<route>/
spec: <design-spec.md | page-spec.md>
plan: <implementation_plan.md | none>
project:
  config: docs/project.json
  package_manager: pnpm
  locales: [en, fa]
  dictionaries: messages
failure_report: []        # repair rounds only
rules:
  - One role per artifact.
  - Edge tests are immutable; baseline tests change only with a logged reason.
  - Failing test means failing code.
  - Targeted execution only.
  - No test.only / it.skip / placeholder assertions.
```

Return payloads are defined in
[`nextjs-adversarial-qa/references/shared/subagent-test-author-protocol.md`](../../nextjs-adversarial-qa/references/shared/subagent-test-author-protocol.md)
for test agents and in the `nextjs-dev` agent prompt for implementation.

---

## 4. Phase Gates

| Gate | Owner | Pass condition |
| :--- | :--- | :--- |
| Spec complete | orchestrator | `design-spec.md` / `page-spec.md` §7 rows are explicit and verifiable |
| Baseline authored | test-author | `test-plan.md` maps every §7 row to an ID and layer |
| Baseline green | orchestrator | targeted suite exits `0`, output recorded |
| Implementation clean | dev | `verify-dev` / `verify-page` exits `0`, no dev-server errors |
| Edge suite authored | qa-auditor | ≥6 cases across ≥4 categories (component) or ≥4 page-boundary cases |
| All suites green | orchestrator | baseline + edge + Playwright exit `0` |
| Boundaries held | orchestrator | write audit exit `0` |

Never accept `status: PASS` from an agent without the command and exit code.

---

## 5. Repair Routing

```
failure
  ├─ code_fixes_required non-empty  -> nextjs-dev (implementation only)
  ├─ baseline assertion wrong       -> nextjs-test-author (log revision_reasons)
  ├─ edge assertion wrong           -> user decision; orchestrator edits + logs
  └─ spec ambiguous                 -> BLOCKED with the rows in question
```

Rules:

1. A failing edge test is presumptively a product bug.
2. A dev agent never receives "edit the test" as an instruction.
3. A test agent never receives "fix the component" as an instruction.
4. Re-run exactly the same files after a fix; do not expand scope.
5. Log every escalation in the execution report.

---

## 6. Write Audit

`scripts/audit-agent-writes.ps1` / `.sh` classifies every file changed since a git
ref and fails when a phase touched a forbidden class.

```bash
# A repair round should only contain implementation changes
pwsh audit-agent-writes.ps1 -Since origin/main -Phase implementation

# Adversarial round should only add edge tests / component E2E
pwsh audit-agent-writes.ps1 -Since <sha> -Phase adversarial
```

Classes:

| Class | Matches |
| :--- | :--- |
| `impl` | `app/**`, `components/**`, `lib/**`, `hooks/**`, `messages/**` |
| `test-baseline` | `*.test.ts(x)` excluding `*.edge.test.tsx` |
| `test-edge` | `*.edge.test.tsx` |
| `test-e2e-page` | `tests/e2e/pages/**` |
| `test-e2e-component` | `tests/e2e/components/**` |
| `test-plan` | `test-plan.md` |
| `plan` | `docs/plan/**` |
| `design` | `docs/design/**` |
| `config` | `package.json`, lockfiles, `jest*`, `playwright*`, `next.config.*`, `tsconfig*`, `eslint*` |

Phase expectations:

| Phase | Allowed | Everything else |
| :--- | :--- | :--- |
| `baseline` | `test-baseline`, `test-plan` | violation |
| `page` | `test-e2e-page`, `test-plan` | violation |
| `implementation` | `impl` | violation |
| `adversarial` | `test-edge`, `test-e2e-component` | violation |
| `final` | `plan`, `design` | violation |
| `all` | any except `config` | config is a violation |

`config` is always a violation for role agents: dependency and runner changes are
a human/orchestrator decision, not an agent side effect.

---

## 7. Degraded Mode

Without `.opencode/agents/`, permissions cannot enforce anything. The orchestrator
must:

1. Announce `DEGRADED: agent permissions unavailable`.
2. Use the prompts in `nextjs-adversarial-qa/resources/prompts/`.
3. Run the write audit after **each** phase, not just at the end.
4. Report the degraded status in the execution report; never present it as
   equivalent to the enforced path.

---

## 8. Orchestrator Checklist

- [ ] Roster present and loaded (`opencode debug agents` if available).
- [ ] Target classified; mode decided; paths resolved from `docs/project.json`.
- [ ] Spec gate passed.
- [ ] Baseline delegated, authored, and green (or expected-red) with output.
- [ ] Implementation delegated; verification output recorded.
- [ ] Adversarial audit delegated; `immutable_edits` empty.
- [ ] Repair loop closed with exit `0`.
- [ ] Write audit exit `0`.
- [ ] Plan checklist ticked by the orchestrator only.
- [ ] Report rendered with commands and exit codes.
