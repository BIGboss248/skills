# Task Types — Probes, Skeletons, Verification

Detect the type in Stage 1. It decides the extra interview probes, the phase
shape, and what counts as proof.

---

## Feature

**Probes**: user-visible behavior, data-model impact, rollout (flag or not),
edge cases the user expects handled.

**Skeleton**

1. Prepare — read the surrounding code, confirm the contract, list touched
   modules.
2. Build — smallest vertical slice end to end, then widen.
3. Verify — happy path + at least one failure path + the project gate.
4. Ship — docs/changelog note, staged diff, approval.

**Proof**: the feature is observable through its real entry point (UI, CLI,
API), plus the project's test/lint/build gate.

---

## Bugfix

**Probes**: reproduction steps, expected vs actual, when it last worked,
regression-test location.

**Skeleton**

1. Reproduce — a failing test or a scripted reproduction, recorded verbatim.
2. Diagnose — root cause written down before any fix.
3. Fix — minimal change, regression test added.
4. Verify — failing test now passes; nothing else regressed; gate green.

**Proof**: the reproduction fails before and passes after, with the command and
output quoted.

**Pitfall**: fixing the symptom. If the root cause is unknown, the plan's first
step is investigation, not a patch.

---

## Refactor

**Probes**: behavior contract that must not change, current test coverage,
acceptable review size.

**Skeleton**

1. Freeze — tests/characterization checks that prove current behavior.
2. Move — mechanical, reviewable changes in small batches.
3. Clean — remove the old path only after the new one passes.
4. Verify — identical outputs before/after; gate green.

**Proof**: behavior equivalence evidence (same snapshots, same test results,
same outputs), not "it looks cleaner".

**Pitfall**: refactor and feature in one step. Split it.

---

## Migration / upgrade

**Probes**: source and target versions, breaking changes, data volume, backup
and restore path, allowed downtime.

**Skeleton**

1. Inventory — what uses the thing, what breaks, pinned versions.
2. Rehearse — run the migration on a copy or dry run.
3. Backup — a verified restore point, tested restore command.
4. Execute — in the agreed window, one change per step.
5. Verify — real workload check, not just "build succeeded".
6. Rollback drill — prove the restore path works or record why it cannot.

**Proof**: a restore or rollback that was actually exercised, plus post-migration
functional checks.

---

## Ops / infrastructure / release

**Probes**: environment, credentials source, maintenance window, monitoring,
who is on call if it fails.

**Skeleton**

1. Pre-flight — access, quota, backups, current state captured.
2. Change — one system at a time, idempotent commands.
3. Observe — health check, logs, metrics for an agreed period.
4. Rollback — documented and, where cheap, tested.

**Proof**: health endpoint/status page plus a log or metric sample from **after**
the change.

**Pitfall**: irreversible commands (`rm -rf`, `DROP`, force push, `--force`) need
explicit confirmation inside the step, not just at the plan gate.

---

## Research / learning

**Probes**: question to answer, source quality bar, depth, deliverable format,
citation rules, deadline.

**Skeleton**

1. Frame — the exact question, sub-questions, and what would falsify the answer.
2. Collect — sources with a quality bar (primary > secondary > blog).
3. Synthesize — notes structured by sub-question, contradictions flagged.
4. Deliver — artifact in the agreed format with sources listed.
5. Verify — every claim traceable to a source; re-check the weakest one.

**Proof**: a deliverable whose claims each cite a source, plus an explicit
"confidence and gaps" section.

---

## Writing / documentation

**Probes**: audience, length, structure, house style, publication location,
reviewer.

**Skeleton**

1. Outline — sections and one-line intent each.
2. Draft — content only, no polish.
3. Review — facts, links, code samples actually run.
4. Publish — placement, links from index pages, metadata/frontmatter.
5. Verify — links resolve, samples run, style matches the house convention.

**Proof**: the published file plus a link check and a claim check.

---

## Personal goal / habit

**Probes**: success measure, cadence, obstacles, accountability, review date.

**Skeleton**

1. Baseline — current state measured without judgement.
2. Plan — weekly cadence, minimum viable action, trigger/reminder.
3. Review points — dated check-ins with the metric to look at.
4. Adjust — one change per review, based on what actually drifted.

**Proof**: a recorded baseline and dated measurements, not a feeling of progress.

**Pitfall**: plans that only add effort. Ask what gets dropped to make room.

---

## Mixed requests

A request that contains two types (for example "fix the bug and add a test
suite") gets **separate phases**, not merged steps, and the second phase becomes
an explicit follow-up with its own approval. Never bury a second task inside a
step.
