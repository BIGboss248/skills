---
name: self-repair
description: >-
  Record and apply durable project rules. Use when the user corrects you, states
  a preference, or a bug reveals a rule worth keeping.
---

# Self-Repair

How a correction becomes a durable constraint. This skill owns the ruleset.

## Storage

Each workspace owns exactly one ruleset, at a fixed path from its root:

```
<workspace root>/.agents/autofix.json
```

That is the only location. There is no fallback filename, no parent-directory
search, and no global ruleset. A missing file means the workspace has no rules:
continue without rules and create the file with `[]` only when a rule must be
written.

## Scope

A ruleset governs the workspace that owns it, and nothing else. Never read,
merge, inherit, or cite a ruleset from another workspace — the Obsidian vault at
`D:\Scripts\Obsidian` is one workspace, not a shared rule layer for the
projects beside it. When a rule from elsewhere is worth keeping here, add it as
a new rule in the current workspace's file and name the origin in `Why`
("carried over from vault rule 39"). For a task that touches two workspaces,
each edit obeys the ruleset of the workspace it lands in.

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

1. Load `<workspace root>/.agents/autofix.json` of the workspace that holds the
   files you will change.
2. If the file is absent, continue with no rules; do not search other
   directories for a ruleset.
3. Select the rules that touch the files, tools, or patterns in this task.
4. Resolve conflicts by precedence: the higher `Rule_number` wins.
5. Treat selected rules as hard constraints, not suggestions.

## When to add a rule

- The user corrects the output ("no, use X").
- The user rejects a pattern or a file location.
- The user states a preference.
- A bug was caused by a wrong assumption.
- The user asks to remember something.
- A `triage` cycle closed an issue and produced a durable cause.

## Adding a rule

1. Confirm the workspace that owns the rule, and edit only that workspace's
   `.agents/autofix.json`.
2. Read the array; determine the next `Rule_number`.
3. Write one imperative sentence that another agent can follow without context.
4. Append, keep valid JSON, format with two-space indentation.
5. Deduplicate: merge overlapping rules in the same domain and renumber `1..N`.
6. State the new rule number to the user in one line.

When a new rule supersedes an old one, add the new rule and name the superseded
number in `Why`; never silently delete history.

## Prefer better enforcement

If the constraint is mechanical — a banned API, an import shape, a file location
— propose a deterministic check (lint rule, hook, CI job) instead of another
prose rule. Keep prose rules for judgement calls that no check can decide.

## Definition of Done

- [ ] Only the current workspace's ruleset was read and written.
- [ ] The ruleset is valid JSON with sequential numbers.
- [ ] Each new rule is imperative and unambiguous.
- [ ] Conflicts are resolved by the newer rule.
- [ ] Duplicates were merged, not accumulated.
- [ ] The user was told which rule number was added.

## Edge Cases & Pitfalls

- **Vague rules** — "write clean code" cannot be applied or checked.
- **Corrupt file** — always parse, append, and write back; never string-concat
  into JSON.
- **Cross-workspace import** — obeying another workspace's rules changes
  behaviour in a repo whose owner never agreed to them; surface the rule and let
  the user decide, then record it locally if accepted.
- **Rule flood** — one rule per correction, not per sentence.
- **Silent supersede** — deleting an old rule loses the reason it existed.
- **Non-rule** — a one-off task instruction is not a durable rule.
- **Self-recursion** — do not record a rule about recording rules.
- **Stale rules** — a rule that contradicts the current codebase is a finding;
  surface it rather than obeying it blindly.

## References

- The ruleset file itself is the reference: read it before every task.
