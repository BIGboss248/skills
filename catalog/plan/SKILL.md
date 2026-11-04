---
name: plan
description: >-
  Turns a request into an executable, verifiable step-by-step plan through three
  adaptive interview rounds and saves it to `docs/plan/<slug>.md`. Triggers on
  `/plan`, "plan this", "make a step-by-step plan", or "plan it out first".
metadata:
  author: BIGboss248
  version: "1.0"
---

# Planning (`plan`)

Converts a vague request into a plan another agent — or the user — can execute
without re-deciding anything: **inspect, interview, write, audit, hand off**.

---

## Contract

- **Inspect before asking.** Never ask a question the workspace, files, git
  history, or `docs/project.json` already answers.
- **Three rounds, five questions each, maximum fifteen total.** Adaptive: skip
  any question already answered, and stop early when the answers suffice.
- **One recommendation per question.** Every question offers a default so the
  user can reply "defaults".
- **Wait between rounds.** Never dump all rounds at once; restate the locked
  answers at the end of each round.
- **Planning is read-only.** No source file, config, or dependency is changed
  during planning. The only write is the plan file.
- **No invented steps.** Every step names an action, the artifact it touches,
  and a check that proves it is done. "Verify it works" is not a step.
- **Stop before execution.** The plan ends with an approval gate; implementation
  starts only after an explicit go-ahead in the same session.

---

## When to plan

Plan when the work needs **three or more steps**, touches more than one file or
system, is hard to undo, or the user is unsure what they want.

Do **not** write a plan file for a one-line fix, a question, or a single command.
Say so in one sentence and do the work instead. Never plan as a delay tactic.

---

## Stage 1 — Inspect (no questions)

- [ ] Read the request literally; extract the verb, the object, and the implied
      definition of done.
- [ ] Scan the workspace: stack manifests, directory layout, existing
      `docs/plan/`, `docs/project.json`, `AGENTS.md`, `.agents/autofix.json`,
      `README.md`, recent git history.
- [ ] Identify the task type with [task-types.md](./references/task-types.md)
      (feature, bugfix, refactor, migration, ops, research, writing, personal).
- [ ] List what the inspection already answers, and the genuine unknowns that
      remain. Only the unknowns become questions.

---

## Stage 2 — Interview (three adaptive rounds)

Ask with the interactive question tool when it is available; otherwise post
numbered questions in chat and stop. Full question bank, branches, and stop
rules: [interview-rounds.md](./references/interview-rounds.md).

| Round | Focus | Max |
| :--- | :--- | :--- |
| 1 | Intent, definition of done, non-goals | 3 |
| 2 | Context, constraints, dependencies, blast radius | 5 |
| 3 | Risks, unknowns, verification, review gate | 5 |

After each round:

- [ ] Restate the locked answers as a short `Decisions` block.
- [ ] Mark anything still unknown as an **assumption** with its fallback.
- [ ] Ask the next round only if a remaining answer would change the plan.

---

## Stage 3 — Write the plan

- [ ] Choose the slug from the request (kebab-case) and write
      `docs/plan/<slug>.md` from
      [plan.md.template](./resources/templates/plan.md.template). On a name
      collision, append `-2`, `-3`; never overwrite an existing plan.
- [ ] Deploy every section of [plan-structure.md](./references/plan-structure.md):
      goal, definition of done, non-goals, decisions, assumptions,
      prerequisites, phased steps, risks/rollback, open questions, execution log.
- [ ] Group steps into phases, and keep each step atomic: one action, one
      artifact set, one check.
- [ ] Number steps `P<phase>.<step>`; record `Depends on` so the order is
      mechanical, not a matter of memory.
- [ ] Give each step a **Done when** line with a command, diff, or observable
      state — not an opinion.
- [ ] Add a `Negative case` row for anything that can fail open (auth, routing,
      data writes, money, destructive commands, deletions).
- [ ] Include an explicit `## Approval gate` with the exact question you will ask.

---

## Stage 4 — Self-audit before presenting

- [ ] Every step is executable by someone who was not in the interview.
- [ ] Every step has a verifiable `Done when`; every phase has an exit check.
- [ ] No step contains more than one logical change.
- [ ] No unresolved decision leaks into the step list — it is a decision, an
      assumption, or an open question.
- [ ] Order is dependency-correct; prerequisites are available now, not later.
- [ ] Scope matches the non-goals; nothing speculative was added.
- [ ] No secret, token, credential, or personal datum appears in the plan.
- [ ] If the audit fails, fix the plan — do not present it with caveats.

---

## Stage 5 — Hand off and stop

- [ ] Print the summary from the output schema below, not the whole file.
- [ ] State the plan path and the number of phases and steps.
- [ ] Ask the approval question from `## Approval gate` and **stop**.
- [ ] On approval: execute step by step, ticking each `Done when` in the plan's
      execution log as it passes. On a rejection or change: revise the plan
      first, re-audit, ask again.
- [ ] If execution reveals a wrong assumption, amend the plan in place with an
      `A<n>` amendment note — never renumber or delete completed steps.

---

## Edge cases & known AI pitfalls

> [!WARNING]
>
> - **Interview theatre**: questions already answered by the repo, or asked to
>   look thorough. Inspect first, ask only what changes the plan.
> - **Question dumping**: all fifteen questions in one message. One round at a
>   time, then wait.
> - **Unverifiable steps**: "test it", "make sure it works", "handle errors".
>   Replace with a command, an expected value, or an observable state.
> - **Planning past the request**: adding migrations, abstractions, or cleanup
>   the user never asked for. Non-goals exist to keep the scope honest.
> - **Confusing plan with permission**: producing a plan is not approval to
>   implement, and approval to plan is not approval of each destructive step.
> - **Silent assumptions**: an unasked decision written as fact. Label it
>   `Assumption` with the fallback used if it is wrong.
> - **Renumbering completed work**: use `P2.3a` and supersede in place, so old
>   references and execution logs stay valid.
> - **One giant phase**: a phase with twelve steps hides a missing decision.
>   Split it until each phase has a single verifiable exit.
> - **Overwriting an earlier plan**: append a suffix; other sessions and
>   documents may link to the old file.
> - **Secrets in the plan**: plans get committed. Reference variable names, not
>   values.

---

## Output summary schema

```markdown
### Plan ready: <title>

- **File**: `docs/plan/<slug>.md`
- **Task type**: <feature|bugfix|refactor|migration|ops|research|writing|personal>
- **Rounds**: 1–3 (questions asked: N · skipped as already answered: M)
- **Phases**: X | **Steps**: Y | **Blocked steps**: Z
- **Decisions**: locked D · **Assumptions**: A · **Open questions**: Q

**Definition of done**: <one line>

**First three steps**
1. `P1.1` <action> → done when <check>
2. `P1.2` <action> → done when <check>
3. `P2.1` <action> → done when <check>

**Risks**: <top 1–2 with mitigation>

Approve this plan, or tell me what to change before I start?
```

---

## Reference guides

- [Interview rounds](./references/interview-rounds.md) — question bank, task-type branches, stop rules.
- [Plan structure](./references/plan-structure.md) — file schema, step grammar, audit rubric.
- [Task types](./references/task-types.md) — per-type probes, step skeletons, verification.
- [Plan template](./resources/templates/plan.md.template) — canonical `docs/plan/<slug>.md`.
- [Command template](../../.opencode/commands/plan.md) — `/plan` entrypoint used in this vault.
