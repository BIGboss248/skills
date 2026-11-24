# N1 — Project Metadata (`docs/project.json`)

**Category:** Foundation · **Default:** on · **Depends on:** —

## Enable when

Any other skill reads project facts (package manager, directories, test tooling,
locales). It is the cheapest feature and the source of truth for the rest of the
run.

## Questions

Usually none — confirm the detected values. Ask only when a manifest or lockfile
is missing or ambiguous:

- Test, lint, and build commands.
- Source directory (`app` or `src/app`) and component directory.
- Publish target (`container`, `package`, `static`, `none`).

## Steps

1. Read the existing `docs/project.json` if present and preserve unknown keys.
2. Merge the detected metadata into `project_context_and_metadata` using
   [project-json-schema.md](../project-json-schema.md) and
   [project.template.json](../../resources/templates/project.template.json).
3. Merge `nextjs_setup_features` from `.agents/nextjs-setup-features.json` (the
   confirmed selection) so later runs can diff the working tree against intent.
4. Record `containerization`, `ci_cd_provider`, and `release_automation` so N11
   and N12 can branch on them.
5. Add `dictionaries_dir` / `dictionary_file_pattern` only when N4 is enabled.
6. When N9 is enabled, merge `project_context_and_metadata.agents` (names, paths,
   model overrides, `enabled` flags).
7. When N10 is enabled, merge `project_context_and_metadata.mcp_servers` with the
   accepted server list.

## Acceptance

- [ ] `node -e "JSON.parse(require('fs').readFileSync('docs/project.json','utf8'))"` passes.
- [ ] `package_manager`, `new_component_dir`, `style_file_dir`,
      `component_library`, `animation_library`, `testing_library`, and
      `supported_languages` are present and non-empty.
- [ ] Every `supported_languages` entry carries `language_code`, `country_code`,
      `currency_code`, `direction`, `native_name`, and `calendar_type`.
- [ ] `nextjs_setup_features.enabled` matches the confirmed selection.
- [ ] Dictionary keys exist exactly when N4 is enabled; agent and MCP blocks
      exist exactly when N9 / N10 are enabled.

## Notes

- Never invent commands: derive them from `package.json` scripts and mark
  unknowns instead of guessing.
- Do not remove keys owned by a disabled feature if a previous run wrote them;
  leave them untouched and note the drift in the report.
