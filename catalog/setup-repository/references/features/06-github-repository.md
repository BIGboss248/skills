# F6 — GitHub Repository Provisioning

## Enable when

The repository needs a remote, metadata, topics, or its baseline documents.

## Questions

1. Create a new repository, or attach the existing local one?
2. Visibility: private or public.
3. Confirm the description.
4. Confirm the suggested topics (derive them from the detected stack; ask before
   finalizing).
5. Mark as a template repository? Enable issues? Disable the wiki?
6. Which documents should be generated: `CONTRIBUTING.md`, `SECURITY.md`,
   `CODE_OF_CONDUCT.md`, or only `README.md`?

## Steps

1. Preflight: `gh auth status` and `gh api user --jq .login`.
2. Create or attach:
   `gh repo create <owner>/<repo> --private --description "<purpose>" --source=. --remote=origin --push`.
   Omit `--license` / `--gitignore` when those files already exist.
3. Apply metadata and topics:
   `gh repo edit <owner>/<repo> --enable-issues --enable-projects=false --enable-wiki=false --delete-branch-on-merge --template --add-topic ...`.
4. Write the selected documents and fix their relative links.
5. Verify with `gh repo view --json visibility,isTemplate,hasIssuesEnabled,hasWikiEnabled,deleteBranchOnMerge,repositoryTopics`.

## Acceptance

- [ ] `gh repo view --json` reports the confirmed visibility, template flag, issues/wiki state, delete-branch-on-merge, and topics.
- [ ] Every relative link in `README.md` resolves.
- [ ] The plan file is the root commit (recommended) or at least present before code.

## Notes

- Repository topics are not release tags. Tags come from F8.
- GitHub only reads issue/PR templates from the default branch; verify after the
  first push to `main`.
- Full command reference: [github-repository-setup.md](../github-repository-setup.md).
