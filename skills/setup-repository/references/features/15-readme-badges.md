# F15 — README badges (CI validation + release version)

## Enable when

The repository has a `README.md` and at least one GitHub Actions workflow, and
the reader should see whether the build passes and which version shipped without
opening the Actions tab.

## Questions

1. Which workflow file is the CI gate (`release-please.yml`, `ci.yml`, …), and
   which branch does it gate?
2. Are the two badges the whole set, or add license / runtime version / last
   commit?
3. Placement: directly under the H1 (default), or a "Status" list further down?

## Steps

1. Resolve the identity once:
   `gh repo view --json nameWithOwner,defaultBranchRef,visibility`.
   Without a remote, parse `git remote get-url origin` and record it.
2. List the real workflow files: `ls .github/workflows/`. The badge path must
   match a committed file name exactly; a guessed name renders "no status".
3. Read `README.md` before writing. If the block already exists (both URLs
   present), stop and report `[UNTOUCHED]`. If there is no H1, create
   `# <repo>` first, then insert.
4. Insert the block from
   [readme-badges.md.template](../../resources/templates/readme-badges.md.template)
   directly under the H1, one blank line above and below, one badge per line.
   Set `WORKFLOW_FILE` to the file name and `BRANCH` to the default branch.
5. Verify each URL, not the render:
   `curl -s "https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg?branch=main" | head -c 200`
   and the same for the release badge. A 200 plus the workflow name (or the
   latest tag) in the SVG is the pass condition.
6. Re-read `README.md` and confirm every pre-existing badge, heading, and
   relative link survived.

## Acceptance

- [ ] Exactly one badge block, directly under the H1.
- [ ] The CI badge points at a workflow file that exists in `.github/workflows/`
  and at the real default branch.
- [ ] The release badge points at `OWNER/REPO` and reports the latest semver tag
  (or `no releases` with the reason recorded).
- [ ] Both badge URLs return HTTP 200.
- [ ] A second run adds nothing and reports `[UNTOUCHED]`.
- [ ] No version number and no commit SHA is hardcoded in the URLs.

## Notes

- Badge text is the workflow's `name:` field, not the file name. Keep that name
  short (`CI`, not `Release Please & CI Validation`) so the badge stays legible;
  override the label only with the shields.io form.
- Private repositories break both badges: GitHub serves badge images to
  unauthenticated requests, so a private repo's Actions badge renders "unknown"
  and shields returns "repo not found". Record `[BLOCKED]` and name the
  visibility, or ship the badges only after the repo goes public.
- Zero releases is not a defect. The release badge reads
  `no releases or pre-releases` until the first Release Please PR merges; do not
  invent a tag to make it green.
- shields.io is a third-party image service that sees every reader's IP. If that
  is unacceptable, keep the native Actions badge and drop the release badge
  rather than self-hosting a fork without being asked.
- A repository rename bakes a dead URL into the README. Re-run this feature after
  a rename; find stale ones with `git grep 'img.shields.io/github\|actions/workflows'`.
- Release tags themselves belong to F8; this feature only displays them.
- Full reference: [github-repository-setup.md](../github-repository-setup.md).
