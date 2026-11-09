---
name: self-repair
description: >-
  Record and apply durable project rules. Use when the user corrects you, states
  a preference, or a bug reveals a rule worth keeping.
---

# Self-Repair

How a correction becomes a durable constraint. This skill owns the ruleset.

## Storage

Look for the ruleset in this order, and create `.agents/autofix.json` only when a
rule must be written and none exists:

1. `.agents/autofix.json`
2. `autofix.json` at the workspace root
3. `.rules/autofix.json`

## Rule schema

Each entry is an object in a JSON array:

| Field | Required | Meaning |
| :--- | :--- | :--- |
| `Rule_number` | yes | Sequential integer |
| `Category` | yes | One of the categories below |
| `Instruction` | yes | Imperative rule: "Never/Always X — because Y" |
| `Why` | yes | Short reason: user preference, codebase pattern, framework limit |
| `Issue` | no | Issue that produced the rule, from the tracker via `triage` (`#42`) |

## Categories

| Category | Scope |
| :--- | :--- |
| `STYLE` | Formatting, naming, imports, comments |
| `CODE` | Language and library patterns, types, error handling |
| `ARCH` | Directory structure, module boundaries, layers |
| `TOOL` | CLI, build tools, package manager, test runner |
| `PROCESS` | Git workflow, commits, PR rules, gates |
| `DATA` | Schemas, migrations, caching, state shapes |
| `UX` | UI behavior, copy, accessibility |
| `OTHER` | Domain-specific preferences |

## Pre-task scan

Before planning or editing:

1. Load the ruleset.
2. Select the rules that touch the files, tools, or patterns in this task.
3. Resolve conflicts by precedence: the higher `Rule_number` wins.
4. Treat selected rules as hard constraints, not suggestions.

## When to add a rule

- The user corrects the output ("no, use X").
- The user rejects a pattern or a file location.
- The user states a preference.
- A bug was caused by a wrong assumption.
- The user asks to remember something.
- A `triage` cycle closed an issue and produced a durable cause.

## Adding a rule

1. Read the array; determine the next `Rule_number`.
2. Write one imperative sentence that another agent can follow without context.
3. Append, keep valid JSON, format with two-space indentation.
4. Deduplicate: merge overlapping rules in the same domain and renumber `1..N`.
5. State the new rule number to the user in one line.

When a new rule supersedes an old one, add the new rule and name the superseded
number in `Why`; never silently delete history.

## Prefer better enforcement

If the constraint is mechanical — a banned API, an import shape, a file location
— propose a deterministic check (lint rule, hook, CI job) instead of another
prose rule. Keep prose rules for judgement calls that no check can decide.

## Definition of Done

- [ ] The ruleset is valid JSON with sequential numbers.
- [ ] Each new rule is imperative and unambiguous.
- [ ] Conflicts are resolved by the newer rule.
- [ ] Duplicates were merged, not accumulated.
- [ ] The user was told which rule number was added.

## Edge Cases & Pitfalls

- **Vague rules** — "write clean code" cannot be applied or checked.
- **Corrupt file** — always parse, append, and write back; never string-concat
  into JSON.
- **Rule flood** — one rule per correction, not per sentence.
- **Silent supersede** — deleting an old rule loses the reason it existed.
- **Non-rule** — a one-off task instruction is not a durable rule.
- **Self-recursion** — do not record a rule about recording rules.
- **Stale rules** — a rule that contradicts the current codebase is a finding;
  surface it rather than obeying it blindly.

## References

- The ruleset file itself is the reference: read it before every task.
