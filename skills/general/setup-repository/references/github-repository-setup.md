# GitHub Repository Provisioning Runbook

Backs features **F6** (repository, metadata, docs), **F7** (templates), **F8**
(Release Please), **F13** (CodeQL code scanning), **F14** (project board) and
**F9** (branch protection). Derived from the `nextjs-wordpress-starter` Phase 0
gate. Use it after the local scaffold exists and before CI/CD work starts.

---

## 0. Preflight

```bash
gh auth status
gh api user --jq .login
```

Required scopes for the full flow: `repo`, `workflow`, `gist`, `read:org`.
Record the account and date in the project plan.

---

## 1. Create the remote (or attach an existing local repo)

Preferred for a repo that already has commits and a plan file:

```bash
gh repo create <owner>/<repo> \
  --private \
  --description "<one-line purpose>" \
  --source=. \
  --remote=origin \
  --push
```

- `--license` / `--gitignore` make `gh` scaffold files. Only use them when the
  local tree does **not** already contain those files; otherwise commit first
  and verify the diff afterwards.
- `--source=.` requires at least one commit. The plan file should be the root
  commit so the repository's first state is its scope contract.
- Add `--disable-wiki` at creation time if the wiki should stay off.

Verify:

```bash
gh repo view --json name,visibility,defaultBranchRef
```

---

## 2. Metadata and topics

`gh repo create` cannot mark a repository as a template; do it in the edit step.

```bash
gh repo edit <owner>/<repo> \
  --enable-issues \
  --enable-projects=false \
  --enable-wiki=false \
  --delete-branch-on-merge \
  --template \
  --add-topic nextjs --add-topic wordpress --add-topic woocommerce \
  --add-topic wpgraphql --add-topic woographql --add-topic docker \
  --add-topic docker-compose --add-topic traefik --add-topic headless \
  --add-topic ecommerce --add-topic typescript --add-topic pnpm
```

Rules:

- Topics are lowercase, hyphen-separated, and discoverable; keep them specific
  to the stack rather than generic (`web`, `app`).
- `--template` means "this repository can be used as a template"; it is not the
  same as `gh repo create --template <other-repo>`.
- `--enable-secret-scanning` is optional and depends on account support for
  private repositories.
- Enable "delete branch on merge" so release-please and feature branches do not
  accumulate.
- `--enable-projects=false` hides the Projects tab. F14 reverses it with
  `gh repo edit <owner>/<repo> --enable-projects=true`.

Verify:

```bash
gh repo view --json \
  visibility,isTemplate,hasIssuesEnabled,hasWikiEnabled,deleteBranchOnMerge,repositoryTopics
```

Note: version **tags** (`vX.Y.Z`) are produced later by Release Please, not by
`gh repo edit`. Until the first release PR is merged there are no tags.

---

## 3. Repository documents

Every repository gets, at minimum:

| File | Purpose |
| :--- | :--- |
| `README.md` | What it is, prerequisites, run/deploy path, links to the rest. Status badges (CI + latest release) come from F15. |
| `LICENSE` | Confirm the license with the owner before creating the repo. |
| `CONTRIBUTING.md` | Branch/commit/review rules and the local test gate. |
| `SECURITY.md` | Supported versions and private vulnerability reporting. |
| `CODE_OF_CONDUCT.md` | Contributor Covenant or the organization's policy. |
| `PLAN.md` (or `docs/plan.md`) | Scope, ordered checklist, gate criteria, continuation protocol. |
| `AGENTS.md` | Mandatory skills and agent rules; see the skill's Step 3. |

Check that every relative link in `README.md` resolves, and that issue-form
links use absolute URLs (GitHub renders forms on `/issues/new`, not in the repo
tree).

---

## 4. Issue and PR templates

```bash
powershell -ExecutionPolicy Bypass \
  -File .agents/skills/setup-repository/scripts/init_triage_infra.ps1
```

The script deploys:

- `.github/ISSUE_TEMPLATE/bug_report.yml` — reproduction, expected/actual, logs.
- `.github/ISSUE_TEMPLATE/feature_request.yml` — problem, proposal, area, acceptance.
- `.github/ISSUE_TEMPLATE/config.yml` — contact links, blank-issue policy.
- `.github/PULL_REQUEST_TEMPLATE.md` — summary, verification, no-secrets checklist.

It also provisions the remote labels used by `triage` (`bug`,
`agent-triage`, `self-repair`, `verified`). GitHub only reads templates from the
default branch, so verification happens after the first push to `main`.

Validate issue forms structurally: unique `id`s per form, supported block types,
at least one option per dropdown/checkbox, and required flags on the blocks that
matter.

---

## 4b. Project board (F14)

A GitHub Project (v2) that collects the repository's issues and pull requests
and checks them off on close. Two halves, two mechanisms:

| Half | Mechanism |
| :--- | :--- |
| Add issues and PRs | Built-in "Auto-add to project" workflow — **UI only** — or the `.github/workflows/project-sync.yml` job |
| Check off on close | Built-in "Item closed" workflow (Status → Done), on by default at project creation |

```bash
gh auth status                                   # needs the 'project' scope
gh auth refresh -s project,read:project          # interactive; the user does it

gh repo edit <owner>/<repo> --enable-projects=true
gh project create --owner <owner> --title "<title>" --format json
gh project link <number> --owner <owner> --repo <owner>/<repo>
gh project field-list <number> --owner <owner> --format json \
  --jq '.fields[] | select(.name == "Status")'
```

Verify the link and the workflows — the schema cannot create or edit a workflow,
only read and delete it:

```bash
gh api graphql -f query='
  query($login: String!, $number: Int!) {
    user(login: $login) {
      projectV2(number: $number) {
        id
        url
        repositories(first: 20) { nodes { nameWithOwner } }
        workflows(first: 20) { nodes { name enabled } }
      }
    }
  }' -f login=<owner> -F number=<number>
```

Use `organization(login: …)` for an org owner. Expect `Item closed` to report
`enabled: true`; `Pull request merged` is the matching default for PRs.

Auto-add is the one step with no API. Either hand off the UI step (project menu
→ Workflows → Auto-add to project → repository + filter `is:issue,pr` → Save
and turn on workflow), or run headless with the PAT-backed workflow:

```bash
gh variable set PROJECT_OWNER --body "<owner>"
gh variable set PROJECT_NUMBER --body "<number>"
gh secret set PROJECT_TOKEN        # PAT: classic repo + project
```

Prove the loop before reporting success: create one issue, watch it appear in the
project, close it, and confirm its Status is the done option. Auto-add is not
retroactive — items created before the workflow was enabled never arrive by
themselves.

Full procedure: [features/14-github-project.md](./features/14-github-project.md).

---

## 5. Release automation bootstrapping

Commit the config before the first feature commit so Release Please has a
baseline:

```json
// release-please-config.json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "bootstrap-sha": "<first-commit-after-tooling>",
  "separate-pull-requests": false,
  "packages": {
    ".": {
      "release-type": "node",
      "package-name": "<repo>",
      "changelog-path": "CHANGELOG.md",
      "include-component-in-tag": false,
      "initial-version": "0.1.0",
      "bump-minor-pre-major": true
    }
  }
}
```

```json
// .release-please-manifest.json
{ ".": "0.0.0" }
```

Workflow essentials:

- Trigger on `push` to `main`.
- `concurrency.cancel-in-progress: false` — cancelling a release run can leave a
  half-updated PR.
- `permissions: contents: write`, `pull-requests: write`.
- `bootstrap-sha` prevents Release Please from scanning history before the
  tooling existed.

With manifest `0.0.0`, `initial-version: 0.1.0`, and `bump-minor-pre-major`, the
first `feat:` produces `v0.1.0`; later fixes stay on `0.1.x` until `1.0.0`.
Image publishing, test gates, and digest recording belong to the CI phase — the
bootstrap workflow intentionally does none of that.

---

## 6. Branch protection decision

Do not enable protection reflexively on a solo bootstrap repository.

| Condition | Decision |
| :--- | :--- |
| Solo maintainer, no CI check yet | Skip; direct pushes are required by the plan protocol. Record the reason in `PLAN.md`. |
| CI check exists (lint/test/build) | Require the check, require PRs, disallow force pushes. |
| Multiple maintainers | Require review as well. |

Revisit at the CI gate. A protection rule that requires a non-existent check
blocks every push and stalls the plan.

When protection is justified, write `protection.json` and apply it:

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

```bash
gh api -X PUT repos/<owner>/<repo>/branches/<branch>/protection --input protection.json
gh api repos/<owner>/<repo>/branches/<branch>/protection
```

---

## 7. Gate

```bash
gh repo view --json \
  visibility,isTemplate,hasIssuesEnabled,hasWikiEnabled,deleteBranchOnMerge,repositoryTopics,defaultBranchRef

git log --oneline | tail -1          # plan is the root commit
git ls-files | grep -E '(^|/)\.env|\.sql$|acme\.json'   # must be empty
```

When F14 is enabled, also record `gh project view <number> --owner <owner>
--format json` (id, url) and the workflow states from section 4b.

Record the result in `PLAN.md` with the date, the repository URL, and the topics
count. A repository setup is not "done" until these commands have been run, not
merely until the files exist.
