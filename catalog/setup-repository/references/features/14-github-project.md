# F14 — GitHub Project Board

## Enable when

The repository wants a GitHub Project (the v2 board) that collects new issues
and pull requests by itself and marks them done when they close.

Two halves, two mechanisms:

| Half | Mechanism | Where it is configured |
| :--- | :--- | :--- |
| Add issues and PRs to the project | Built-in "Auto-add to project" workflow, or an Actions workflow | project UI (native) or a workflow file (headless) |
| Check items off on close | Built-in "Item closed" workflow (Status → Done) | on at project creation; UI only if it was turned off |

Auto-add is the only piece with no API: the GraphQL schema exposes
`deleteProjectV2Workflow` and the read-only `workflows` connection, nothing that
creates or edits a workflow. Pick the mode in the questions below.

## Questions

1. **Project owner** — the repository owner, or another org? A project can be
   owned elsewhere, but the token and the repository must both reach it.
2. **Title** — default `<repo>`; ask if the board is shared across repositories.
3. **Mode** — `native` (auto-add configured in the project UI, no code, no
   secret) or `headless` (Actions workflow plus a PAT). Default `native`.
4. **Done option** — which Status option means checked off? Default `Done`.
5. **Probe** — may I create and close one throwaway issue to prove the loop
   works end to end? Default yes.
6. **Backfill** — add the existing open issues and PRs now, or only future
   items? Auto-add never backfills.

The PAT owner, when using headless mode, must be able to write to both the
project and the repository; a classic token needs `project`, plus `repo` when the
repository is private.

## Steps

Helper path: run the script, then do the probe by hand.

```powershell
powershell -ExecutionPolicy Bypass -File <skill>/scripts/init_github_project.ps1 `
  -Owner <owner> -Title "<title>" [-Mode headless -DeployWorkflow]
```

It runs steps 1–7 below (preflight, project create/reuse, Projects tab, link,
Status field, workflow read, headless workflow plus variables and secret check)
and prints the native-mode handoff. It does not run the probe or the backfill.
When it fails, the numbered steps are the recovery path.

1. Preflight the scope. `gh project` needs `project`; without it every call
   fails with `missing required scopes [project]`.

   ```bash
   gh auth status
   gh auth refresh -s project,read:project    # interactive; hand off to the user
   ```

2. Re-enable the repository Projects tab. F6 runs
   `gh repo edit --enable-projects=false`, so reverse it here or the link step
   has nothing to attach to:

   ```bash
   gh repo edit <owner>/<repo> --enable-projects=true
   ```

3. Create the project, or reuse one with the same title:

   ```bash
   gh project list --owner <owner> --format json \
     --jq '.projects[] | select(.title == "<title>") | .number'
   gh project create --owner <owner> --title "<title>" --format json
   ```

   Keep `number` (per owner, not global) and `id` (`PVT_…`, used by
   `item-edit`) from the output.

4. Link the project to the repository:

   ```bash
   gh project link <number> --owner <owner> --repo <owner>/<repo>
   ```

5. Read the Status field and pick the done option:

   ```bash
   gh project field-list <number> --owner <owner> --format json \
     --jq '.fields[] | select(.name == "Status")'
   ```

   A new project ships `Status` with `Todo`, `In Progress`, `Done`. If the field
   or the confirmed option is missing, create a replacement:

   ```bash
   gh project field-create <number> --owner <owner> \
     --name Status --data-type SINGLE_SELECT \
     --single-select-options "Todo,In Progress,Done"
   ```

   Save `fields[].id` and `options[].id` — the headless workflow and any manual
   fix need both. When `docs/project.json` exists, merge
   `project_context_and_metadata.github_project` with
   `{url, number, mode, done_option}` so other skills can file work on the board.

6. Verify the close automation. Every project starts with two workflows on:
   `Item closed` (Status → Done) and `Pull request merged` (Status → Done).
   Read them, never assume:

   ```bash
   gh api graphql -f query='
     query($login: String!, $number: Int!) {
       user(login: $login) {
         projectV2(number: $number) {
           workflows(first: 20) { nodes { name enabled } }
         }
       }
     }' -f login=<owner> -F number=<number>
   ```

   Use `organization(login: …)` instead of `user(login: …)` when the owner is an
   org. A disabled `Item closed` must be turned on in the UI (project → menu →
   Workflows → Item closed → Edit → set the done option → Save and turn on
   workflow) and recorded as `[MANUAL]`; the schema cannot enable it.

7. Configure auto-add for the chosen mode.

   **native** — hand off one UI step, then verify:

   > Open `https://github.com/users/<owner>/projects/<number>` (or
   > `/orgs/<org>/projects/<number>`) → menu → Workflows → Auto-add to project →
   > Edit → select repository `<owner>/<repo>` → filter `is:issue,pr` →
   > Save and turn on workflow.

   **headless** — deploy the workflow and its inputs:

   ```bash
   gh variable set PROJECT_OWNER --body "<owner>"
   gh variable set PROJECT_NUMBER --body "<number>"
   gh secret set PROJECT_TOKEN    # paste a PAT: classic scopes repo + project
   ```

   Copy [project-sync.yml.template](../../resources/templates/project-sync.yml.template)
   to `.github/workflows/project-sync.yml`. It adds items on `opened`,
   `reopened` and `transferred`, and on `closed` resolves the existing item and
   sets the done option; an item that was never added is added first, then
   checked off. Change `DONE_OPTION` in the copied file when the confirmed option
   is not `Done`. Commit it — it only runs once it is on the default branch.

8. Backfill when requested, one URL per item:

   ```bash
   gh project item-add <number> --owner <owner> --url <issue-or-pr-url>
   ```

9. Probe the loop when approved:

   ```bash
   probe=$(gh issue create --repo <owner>/<repo> --title "[setup-probe] project sync" \
     --body "Created and closed by setup-repository F14.")
   probe_number=${probe##*/}

   gh project item-list <number> --owner <owner> --format json \
     --jq ".items[] | select(.content.number == $probe_number) | {id, status}"

   gh issue close "$probe_number" --repo <owner>/<repo> --reason "not planned"
   gh project item-list <number> --owner <owner> --format json \
     --jq ".items[] | select(.content.number == $probe_number) | {id, status}"
   ```

   The first list must return the item, the second must return `status: Done`
   (or the confirmed option). In native mode the add lags the issue by a few
   seconds; retry once before calling it broken. `gh issue create` prints the URL
   and nothing else, so the number comes from the URL.

## Acceptance

- [ ] `gh project view <number> --owner <owner> --format json` returns the
      project `id` and `url`.
- [ ] GraphQL `projectV2.repositories` contains `<owner>/<repo>`.
- [ ] `workflows` reports `Item closed` with `enabled: true`.
- [ ] Auto-add is on: `native` → the UI shows the repository and filter and the
      workflow is on (recorded `[MANUAL]` with a screenshot or the user's
      confirmation); `headless` → the workflow file is on the default branch,
      `PROJECT_TOKEN`, `PROJECT_OWNER` and `PROJECT_NUMBER` exist, and one run
      is green.
- [ ] Probe result: the item shows up after creation and reads the done option
      after close. Skip only with a stated reason, never silently.
- [ ] `docs/project.json` (with F1) or `.agents/setup-features.json` records the
      project URL, number, mode and done option.
- [ ] The probe issue is closed and named in the report.

## Notes

- **Plan limits** — GitHub Free allows one auto-add workflow per project, Pro
  and Team five, Enterprise Cloud and Server twenty. One workflow with
  `is:issue,pr` covers both item types on Free.
- **No auto-add API** — do not invent `createProjectV2Workflow`; it does not
  exist. Browser automation of the UI is out of scope for this skill.
- **GITHUB_TOKEN cannot touch projects** — the default Actions token has no
  `project` scope for user or org projects. Headless mode needs a PAT (classic:
  `repo` + `project`; fine-grained: Projects read/write, Issues read, Pull
  requests read). Do not put a PAT in a file `git ls-files` can see.
- **Auto-add is not retroactive** — items created before the workflow was
  enabled are never added by it. Backfill explicitly.
- **Auto-add can be silent** — a workflow that reads `enabled: true` can still
  ignore events when the filter does not match. `is:issue,pr` without a state
  qualifier matches both item types in every state; if the UI rejects the
  combined filter, pick one type (Free allows a single auto-add workflow).
- **A board is not a gate** — it is a view. Do not add it to F9 required
  checks.
- **Status options are not states** — closing an issue does not close a project
  item, and moving an item to Done does not close the issue. The two directions
  are configured separately; only the close → Done direction is needed here.
- **Native mode writes nothing to the repository** — nothing to stage. Headless
  mode stages `.github/workflows/project-sync.yml` only.
