# F8 — Release Please

## Enable when

The repository releases versions and should get changelogs and tags from
Conventional Commits.

## Questions

1. Release type (`node`, `python`, `go`, `simple`, …).
2. Package name and changelog path (`CHANGELOG.md`).
3. Initial version (for example `0.1.0` when starting from `0.0.0`).
4. Separate pull requests per package, or one combined PR?
5. Should the workflow only tag releases (skeleton), or also publish images?
   Image publishing belongs to the CI phase; default to skeleton.

## Steps

1. Commit `release-please-config.json` with `bootstrap-sha` set to the first
   commit after the tooling exists, plus the answers above.
2. Commit `.release-please-manifest.json` with the current version (`0.0.0` for a
   new project).
3. Deploy the workflow from
   [release-please.yml.template](../../resources/templates/release-please.yml.template)
   with `concurrency.cancel-in-progress: false`.
4. Validate the JSON files and the workflow YAML.
5. Push to `main` and confirm Release Please opens a release PR.

## Acceptance

- [ ] Both JSON files parse and agree on the package path.
- [ ] `bootstrap-sha` is a real commit that predates the first feature commit.
- [ ] Workflow YAML parses and triggers on `push` to the default branch.
- [ ] After the first push, a release PR exists (or the reason it cannot is recorded).

## Notes

- Do not enable image publishing here before the CI matrix exists; it produces
  failing runs.
- With manifest `0.0.0`, `initial-version: 0.1.0`, and `bump-minor-pre-major`, the
  first `feat:` yields `v0.1.0`.
- The README release-version badge is F15's job. It reads the latest tag at render
  time, so this runbook never writes a version number into `README.md`.
- When F15 is enabled, confirm the badge switches from `no releases` to `vX.Y.Z`
  after the release PR merges.
- Full reference: [github-repository-setup.md](../github-repository-setup.md).
