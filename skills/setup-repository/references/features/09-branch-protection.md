# F9 — Branch Protection

## Enable when

A CI check already exists and more than one person (or an agent) pushes to the
default branch. Otherwise defer.

## Questions

1. Solo maintainer or team?
2. Exact CI check name(s) to require.
3. Require pull requests? How many approvals?
4. Enforce the rules for admins? Allow force pushes or deletions?

## Steps

1. If no CI check exists, **do not enable**. Record the deferral and revisit at
   the CI gate.
2. Write `protection.json` with the confirmed rules:

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

3. Apply it:
   `gh api -X PUT repos/<owner>/<repo>/branches/<branch>/protection --input protection.json`.
4. For a solo bootstrap repository, the expected outcome is a recorded deferral,
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
