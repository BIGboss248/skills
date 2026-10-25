---
name: github-triage
description: >-
  Automate GitHub issue tracking for repository bugs, logging diagnostic root cause analysis, code fixes, and self-repair rule links. Triggers whenever fixing any bug, error, or regression, whether autonomously detected during development and testing or explicitly requested by the user, and on "/github-triage", "fix bug", "triage issue", or "log bug".
---

# GitHub Triage (`github-triage`)

An automated GitHub issue management and triage engine that creates tracking issues for bugs, logs diagnostic investigations, verifies code fixes, and extracts preventative rules into the `self-repair` memory loop.

---

## Prerequisites & Preconditions

- [ ] Working workspace repository with a configured Git remote (`git remote -v`).
- [ ] Either `github-mcp-server` MCP tools or GitHub CLI (`gh`) available in PATH.
- [ ] Active project test suite (e.g., Jest, Playwright, or verification scripts).

---

## Operational Triage Runbook

```mermaid
flowchart LR
    A["1. Infra Check"] --> B["2. Create/Find Issue"]
    B --> C["3. Log Diagnosis"]
    C --> D["4. Fix & Verify"]
    D --> E["5. autofix.json Bridge"]
    E --> F["6. Close Issue"]
```

### Stage 1: Infrastructure Scaffolding
- [ ] Check if `.github/ISSUE_TEMPLATE/bug_report.yml` exists.
- [ ] If missing, execute [`init_triage_infra.ps1`](./scripts/init_triage_infra.ps1) to scaffold [bug_report.yml](./resources/templates/bug_report.yml) and register standard labels (`bug`, `agent-triage`, `self-repair`, `verified`).

### Stage 2: Deduplication & Issue Registration
- [ ] Search existing open repository issues for keywords matching the bug.
  - Review tool invocation examples in [github-mcp-and-cli.md](./references/github-mcp-and-cli.md).
- [ ] **If matching open issue exists:** Note Issue `#N` and append a status comment.
- [ ] **If new issue:** Create issue using title format `fix(<scope>): <short description>` and labels `["bug", "agent-triage"]`. Save returned Issue `#N`.

### Stage 3: Root Cause Investigation & Diagnostic Logging
- [ ] Analyze the failure origin, reproduction conditions, and affected files.
- [ ] Post a diagnostic comment on Issue `#N` utilizing the [diagnostic_comment.md](./resources/templates/diagnostic_comment.md) template.
- [ ] Consult [triage-lifecycle.md](./references/triage-lifecycle.md) for state transitions and diagnostic requirements.

### Stage 4: Implementation & Verification Gate
- [ ] Apply code edits to resolve the bug in the workspace.
- [ ] Author or update automated tests (`.test.tsx` or E2E spec) to prevent regression.
- [ ] Execute verification commands (e.g., `pnpm test` or component verification scripts).
- [ ] **CRITICAL:** Do NOT proceed to close the issue if tests or verification checks fail.

### Stage 5: Self-Repair Memory Bridge (`autofix.json`)
- [ ] Extract an imperative constraint preventing this failure class from recurring.
- [ ] Append the rule to `.agents/autofix.json` following the schema in [self-repair-bridge.md](./references/self-repair-bridge.md):
  - Incremented `Rule_number`
  - Valid `Category` (`[CODE]`, `[ARCH]`, `[STYLE]`, `[TOOL]`, etc.)
  - Clear `Instruction` and `Why`
  - Audit link: `"Issue": "#N"`

### Stage 6: Resolution Summary & Closure
- [ ] Post a final comment on Issue `#N` using [resolution_comment.md](./resources/templates/resolution_comment.md) summarizing changes, test passes, and the new autofix rule.
- [ ] Close Issue `#N` with `state: "closed"` and `state_reason: "completed"`.

---

## Edge Cases & Known AI Pitfalls

- **Duplicate Spawns**: Always search existing open issues before calling `issue_write` to avoid duplicate bug tickets.
- **Premature Closure**: Never close an issue before the full test suite passes. If tests fail, iterate on the fix.
- **Unauthenticated Fallback**: When `gh` is unauthenticated and MCP is unavailable, log the triage report to a local markdown file and warn the user.
- **Vague autofix Rules**: Ensure the rule in `autofix.json` specifies concrete imperative instructions, not vague sentiments like "be more careful".

---

## Output Contract

Upon completing a triage cycle, report the resolution to the user:

```markdown
### 🎯 GitHub Triage Summary
- **Issue:** [#24: fix(cart): hydration mismatch](https://github.com/...)
- **Status:** Closed as completed
- **Root Cause:** Synchronous localStorage access in initial render
- **Verification:** Unit tests passed (`pnpm test:unit`)
- **Self-Repair:** Rule #12 added to `.agents/autofix.json`
```
