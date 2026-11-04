# Interview Rounds — Question Bank

Three adaptive rounds, five questions maximum each, fifteen in total. Inspect
first; ask only what the inspection cannot answer and what would **change the
plan**.

## How to ask

- Use the interactive question tool when it exists (OpenCode: the `question`
  tool). Otherwise post a numbered list in chat and stop.
- Put the recommended option first and label it `(Recommended)`.
- One sentence of context per question; no essays.
- Batch a round into a single message, then wait for the answer.
- If the user answers "defaults", "you decide", or "just plan it", take every
  recommended option, record them as decisions, and move on. Do not re-ask.
- If the user answers only part of a round, treat the rest as defaults and say
  which defaults you applied.

## Stop rules

Stop asking when all three are true:

1. The definition of done is observable.
2. Scope and non-goals are clear.
3. Verification and rollback are known.

Also stop at fifteen questions even if something is still fuzzy — convert the
rest into labelled assumptions and open questions in the plan.

---

## Round 1 — Intent and definition of done (max 3)

1. **Outcome** — In one sentence, what exists or works after this that does not
   today? *(Recommended: restate the request back and let the user correct it.)*
2. **Proof** — How will we know it is done? Name the observable result, command,
   or artifact. *(Recommended: derive from the request — a passing check, a
   rendered screen, a merged file.)*
3. **Non-goals** — What should this explicitly **not** touch or change?
   *(Recommended: leave related cleanup out; list it as follow-up.)*

Skip a question already answered by the request or the repository.

## Round 2 — Context, constraints, dependencies (max 5)

Ask only the ones that apply to the detected task type:

4. **Location** — Where does this live: repository paths, services, accounts,
   documents? *(Recommended: the path the inspection already suggests.)*
5. **Blast radius** — What or who else depends on the thing being changed?
   *(Recommended: nothing known — verify before changing shared surfaces.)*
6. **Compatibility** — What must keep working unchanged: public API, existing
   files, data, formatting, links, conventions?
7. **Inputs** — What do I need that I do not have: access, credentials, a file,
   an approval, a decision from someone else?
8. **Budget** — How much time or effort is acceptable, and should I optimize for
   smallest change or for the clean long-term shape? *(Recommended: smallest
   change that fully solves it.)*

## Round 3 — Risk, unknowns, verification, gate (max 5)

9. **Top risk** — What is most likely to fail or cause damage, and what is the
   worst realistic outcome? *(Recommended: name the risk you already see.)*
10. **Unknowns** — Which unknowns need a short spike before the plan commits?
    *(Recommended: none — but flag every assumption.)*
11. **Rollback** — If this goes wrong, how do we get back: git, backup, feature
    flag, restore command? *(Recommended: revert the branch/commit.)*
12. **Verification** — Which commands or checks are available: build, lint,
    tests, manual review, a checklist? *(Recommended: the project's documented
    gate.)*
13. **Review gate** — Should I stop for approval after each phase, only at the
    end, or only before destructive steps? *(Recommended: stop at the end; always
    stop before anything destructive.)*

---

## Task-type branches

Detect the type in Stage 1, then add the matching probes from
[task-types.md](./task-types.md).

| Type | Extra probes (pick ≤2) |
| :--- | :--- |
| Feature | user-visible behavior, data model impact, rollout/flag, edge cases |
| Bugfix | reproduction steps, expected vs actual, regression test location |
| Refactor | byte-for-byte behavior contract, test coverage before/after, review size |
| Migration / upgrade | version targets, breaking changes, data backup, staged rollout |
| Ops / infra | environment, credentials, downtime window, monitoring, restore path |
| Research | source quality bar, depth, deliverable format, citation rules |
| Writing / docs | audience, length, structure, house style, where it is published |
| Personal / life goal | success measure, cadence, obstacles, accountability |

## Round close-out template

After each round, print this block and wait:

```markdown
### Locked so far

- **Outcome**: …
- **Done when**: …
- **Non-goals**: …
- **Constraints**: …

**Assumptions** (used if you do not correct them): …
**Still unknown**: … (Round 3 if it changes the plan)
```
