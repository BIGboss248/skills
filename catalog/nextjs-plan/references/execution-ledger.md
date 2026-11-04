# Execution Ledger Reference (`docs/plan/`)

A plan is a **ledger**, not a to-do list. This reference defines the grammar that
lets any agent resume work from the file alone: item state, commit traceability,
phase gates, amendments, supersession, and deferrals.

---

## 1. Why the ledger matters

A blueprint says *what to build*. A ledger also says *what is already true*:
which item is next, which commit delivered it, which gate proved it, and which
earlier decision it replaced. Without that layer, every resume re-derives state
from git history and guesses.

---

## 2. Item grammar

Every item is small enough to land in **one commit** and carries an executable
check. Use this shape in every phase file:

```md
- [ ] **P4.14** Iran-only store configuration
  - **Depends on:** P4.13
  - **Acceptance (command → expected):**
    - `wp option get woocommerce_currency` → `IRT`
    - `wp option get woocommerce_default_country` → `IR:THR`
  - **Negative case:** a `US` billing address cannot complete checkout
  - **Idempotency:** second `wp-setup` run reports zero drift
  - **Evidence:** option dump, zone/method listing, exit codes
  - **Result:** _filled on completion_
```

Rules:

- **One item = one commit.** If an item needs two commits, split it. If it needs
  a migration plus a code change plus a doc, that is three items.
- **`Acceptance` is a command and an expected value**, never "works correctly".
- **`Negative case` is mandatory** for auth, routing, validation, permissions,
  money, and anything that can silently degrade to a default. Omit it only when
  no wrong-input path exists.
- **`Idempotency` is mandatory** for setup, seeding, installers, migrations, and
  container recreation.
- **`Evidence`** names what will be pasted on completion (counts, status codes,
  digests, screenshots, report links).
- **`Result`** is filled when the item completes, in the same commit as the code
  or the immediate plan-update commit.

---

## 3. State markers

| Marker | Meaning |
| :--- | :--- |
| `- [ ]` | Not started, or started and not verified |
| `- [x] \`abc1234\`` | Done; hash of the **code/config** commit |
| `- [x] \`manual\`` | Done by hand (repo creation, secret provisioning, dashboard toggle) |
| `- [x] **Superseded by P4.7**` | Replaced; keep the text and the reason |
| `- [x] **Skipped on purpose**` | Deliberately out of scope; requires a revisit trigger |

Never mark an item `- [x]` because the code exists. Mark it when its acceptance
check has been executed and its evidence recorded.

---

## 4. Continuation protocol

Write this section into `docs/plan/README.md` so the next reader does not need
this reference:

1. Read `README.md` → **Current status** and **Next action**.
2. Read the current phase file top to bottom.
3. Take the **first unchecked item**; do not batch items.
4. Implement only that item, then run its acceptance check.
5. Record the short hash in front of the item and fill `Result`.
6. Commit the code and the plan update **separately**:
   - `feat(scope): …` + body `Refs: P4.14`
   - `docs(plan): mark P4.14 complete (abc1234)`
7. Update **Current status** and **Next action**.
8. Push after each commit.

Hash discipline: the hash in the checklist always points to the code commit, not
to the plan-update commit.

---

## 5. Phase gate grammar

A phase is done when a **gate** passes, not when its checkboxes are ticked. Each
phase file ends with:

```md
**Phase 4 gate:** one sentence describing the user-visible outcome.

> **Gate verified 2026-11-03 (P4.13–P4.17):** `verify-wordpress` 32/32,
> `smoke -RequireWordPress` 14/14, `pnpm test:all` 93 unit + 3 browser,
> `pnpm test:e2e:edge` 30 passed / 1 skipped; opt-in order #21 owned by
> customer 2 and visible on `/account`.
```

A gate must name:

- the **commands** that ran,
- the **observed counts/statuses**,
- the **date** and the **items** it covers.

The `README.md` phase table carries the gate status: `Pending`, `In progress`,
`Verified <date>`, or `Verified with amendments`.

---

## 6. Amendment protocol

Plans change. Handle it explicitly instead of silently reordering:

1. **Never renumber completed items.** Append a letter suffix: `Phase 4b`,
   `Phase 4c`, `P4.13`–`P4.17`.
2. **Announce the amendment** in `README.md` → `## Amendments` with the date,
   the trigger, and the items it adds or changes.
3. **State downstream impact**: "runs before `P5.1`; phases 5–8 numbering
   unchanged".
4. **Supersede in place**: keep the original text, append
   `**Superseded by P4.7:** <reason>`. Deleting history destroys the audit trail.
5. **Re-run affected gates** and record the new evidence line under the old one.

Amendment entry shape:

```md
- **2026-10-30 — Phase 4b (auth provider change).** Trigger: JWT sessions never
  authenticate the backend, so native checkout sees a guest. Adds `P4.7`–`P4.12`
  before `P5.1`. Supersedes `P4.3` login and the JWT path in `P4.1`. Phase 5–8
  numbering unchanged.
```

---

## 7. Deferral grammar

A skipped item is a decision, not an omission:

```md
- [x] `manual` **P1.8** Optional i18n
  - **Skipped on purpose.** No acceptance criterion requires a second locale, and
    `[locale]` routing would move every route that later smoke checks depend on.
  - **Revisit if:** a storefront needs a second locale. Cost then: `app/`,
    `proxy.ts`, and the message catalogs only.
```

Every deferral needs a **reason** and a **revisit trigger**. Without a trigger,
the deferral silently becomes permanent.

---

## 8. Status dashboard schema

`docs/plan/README.md` must open with exactly these fields:

```md
## Current status

| Field | Value |
| :--- | :--- |
| Last completed item | `P4.17` |
| Next item | `P6.3` |
| Blocker | None |
| Active amendments | Phase 4c (2026-10-30) |
| Gate status | Phases 0–5 verified; Phase 6 in progress |
| Open decisions | `RELEASE_PLEASE_TOKEN` provisioning |
```

Then the phase table (with gate status), amendments, definition of done, and a
`## Next action` paragraph naming the next item plus the constraints to carry
into it.

---

## 9. Execution log

Keep a single append-only table so the audit trail survives even if a phase file
is rewritten:

```md
| Item | Commit | Date | One-line result |
| :--- | :--- | :--- | :--- |
| P4.14 Iran store config | `f342e9e` | 2026-11-03 | `IRT`, `IR:THR`, one zone, 0 drift |
```

One row per completed item. Never rewrite past rows.
