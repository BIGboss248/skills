# F1 — Project Metadata (`docs/project.json`)

## Enable when

Any other skill will read project facts (stack, commands, test tooling). This is
the cheapest feature and the usual source of truth.

## Questions

Usually none — confirm the detected values. Ask only when a lockfile or manifest
is missing or ambiguous:

- Test command and build command.
- Source directory (`src`, `app`, repo root).
- Publish target (`container`, `package`, `static`, `none`).

## Steps

1. Read the existing `docs/project.json` if present; preserve unknown keys.
2. Merge the detected metadata into `project_context_and_metadata`.
3. If Phase 1 recorded a selection and this feature is enabled, merge
   `setup_features` from `.agents/setup-features.json`.
4. Record `containerization`, `ci_cd_provider`, and `release_automation` so the
   F5/F8 runbooks can branch on them.
5. If F3 is enabled, merge `project_context_and_metadata.mcp_servers` with the
   accepted server list.

## Acceptance

- [ ] `node -e "JSON.parse(require('fs').readFileSync('docs/project.json','utf8'))"` passes (or the stack equivalent).
- [ ] `project_name`, `runtime`, `package_manager`, `test_command`, `build_command` are non-empty.
- [ ] `setup_features.enabled` matches the confirmed selection.
- [ ] When F3 is enabled, `mcp_servers` lists exactly the accepted servers.

## Notes

- Never invent commands: derive them from `package.json` scripts or the project
  manifest, and mark unknowns instead of guessing.
