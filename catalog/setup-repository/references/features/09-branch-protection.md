# F9 — Branch Protection

## Enable when

A CI check already exists and more than one person (or an agent) pushes to the
default branch. Otherwise defer.

F13 (Code scanning) supplies a check name but not a run: it is committed at the
end of the setup, so the check does not exist yet on a fresh run.

## Questions

1. Solo maintainer or team?
2. Exact CI check name(s) to require.
3. Require pull requests? How many approvals?
4. Enforce the rules for admins? Allow force pushes or deletions?
5. Is the candidate check **blocking by design**? A non-blocking scan (F13) never
   becomes a required context.

## Steps

1. If no CI check exists, **do not enable**. Record the deferral and revisit at
   the CI gate.
2. When F13 was enabled in this run, record the exact contexts it will publish
   (`Analyze (javascript-typescript)`, …) under `notes.F9` and defer: the check
   cannot be required before its first run exists. Re-enable F9 in a later run
   once `gh run list --workflow=codeql.yml` shows a completed run. **Never**
   require a CodeQL context of a non-blocking scan — F13 is a signal, not a gate.
3. Write `protection.json` with the confirmed rules:

```json
{
  "required_status_checks": { "strict": true, "contexts": ["<ci-check>"] },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 1 },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
```

4. Apply it:
   `gh api -X PUT repos/<owner>/<repo>/branches/<branch>/protection --input protection.json`.
5. For a solo bootstrap repository, the expected outcome is a recorded deferral,
   not a rule that blocks direct pushes.

## Acceptance

- [ ] If enabled: `gh api repos/<owner>/<repo>/branches/<branch>/protection`
      reports the confirmed contexts and review rules.
- [ ] If deferred: `PLAN.md` (or the project log) states why and when to revisit.
- [ ] A valid direct push is still possible when protection is deferred.

## Notes

- Requiring a check that does not exist blocks every push — the most common way
  to stall a bootstrap.
- Re-check the check name when CI is renamed; protection does not follow renames.
- A non-blocking CodeQL workflow (F13) must never appear in `contexts`. It has no
  `pull_request` trigger, so the context would never report on a PR and the branch
  would deadlock.
