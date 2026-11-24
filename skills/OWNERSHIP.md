# Skill Ownership

One owner per job. A local skill defines what a correct artifact is; the
planning skills decide what to build, in what order, and whether it is done.

## Folder categories

#agent #skills #organization

Skills live in `skills/<category>/<skill>/SKILL.md`. Three categories, listed in
`.claude-plugin/marketplace.json` so `npx skills add` shows them as group
headings: `flutter`, `nextjs`, and `general`. The manifest supplies the headings
because the CLI never derives them from folder names, and installed skills land
flat in `.agents/skills/<skill>`. See [[AI Skills and MCP Servers]] for the
skills hub note.

| Category | Skills |
| :--- | :--- |
| `flutter` | `flutter-app-arch`, `flutter-component-dev`, `flutter-dev-setup`, `flutter-observability`, `flutter-setup-localization`, `flutter-spec`, `flutter-theme`, `flutter-windows-desktop` |
| `nextjs` | `nextjs-api`, `nextjs-component-dev`, `nextjs-dev-setup`, `nextjs-health-probe`, `nextjs-i18n-usage`, `nextjs-opentelemetry`, `nextjs-page-dev`, `nextjs-project-scaffold`, `nextjs-spec`, `nextjs-storybook-story` |
| `general` | `ag-customizer`, `git-worktree-isolation`, `headless-woocommerce-api`, `plain-output`, `rest-api-design`, `self-repair`, `seo-ops`, `setup-repository`, `skill-creator`, `stitch-design` |

## Who owns what

| Job | Owner | Kind |
| :--- | :--- | :--- |
| Elicit requirements and decisions | `grilling`, `grill-with-docs` | planning set |
| Write the work spec | `to-spec` | planning set |
| Decompose into tickets | `to-tickets` | planning set |
| Track issues and triage | `triage` | planning set |
| Diagnose a defect | `diagnosing-bugs` | planning set |
| Write and drive tests | `tdd` | planning set |
| Review a change | `code-review` | planning set |
| Next.js stack specification | `nextjs-spec` | local |
| Flutter stack specification | `flutter-spec` | local |
| Next.js construction | `nextjs-component-dev`, `nextjs-page-dev`, `nextjs-api`, `nextjs-i18n-usage`, `nextjs-storybook-story` | local |
| Flutter construction | `flutter-component-dev`, `flutter-app-arch`, `flutter-theme`, `flutter-observability`, `flutter-setup-localization` | local |
| Platform and operations | `flutter-windows-desktop`, `headless-woocommerce-api`, `seo-ops`, `codeql`, `nextjs-health-probe`, `nextjs-opentelemetry`, `nextjs-project-scaffold` | local |
| Environment setup | `setup-repository`, `nextjs-dev-setup`, `flutter-dev-setup`, `ag-customizer` | local |
| Branch, worktree, approval, merge | `git-worktree-isolation` | local |
| Durable project rules | `self-repair` | local |
| Skill authoring | `skill-creator` | local |
| Reply style | `plain-output` | local |
| Visual prototyping | `stitch-design` | local |
| Cross-stack API contract | `rest-api-design` | local |

## What proves a change is done

| Claim | Proven by |
| :--- | :--- |
| The behavior is correct | `tdd` — red, green, refactor |
| The code follows standards and the spec | `code-review` — two axes |
| The full tier passes | The repository's own hook or CI job |
| Configuration exists | The setup skill's acceptance check |
| A defect is understood | `diagnosing-bugs` — a tight failing loop |

A build is not evidence of behavior. A deferred check is reported as not run, not
as passing.

## Boundaries to keep

- A construction skill writes implementation and never authors tests; `tdd` does.
- `implement` sequences work but does not override `git-worktree-isolation`.
- Stack specifications live in `docs/project.json` and `docs/design/`; work specs
  and tickets live wherever `to-spec` and `to-tickets` publish them.
- A skill that cannot resolve its inputs states the assumption instead of
  blocking.

## Files

- `docs/project.json` — canonical stack specification.
- `docs/design/01`–`04` — strategy, routes, tokens, architecture contracts.
- `docs/design/components/<page>/<component>/` — design spec and Stitch assets.
- `messages/`, `lib/routes.ts`, `lib/site-config.ts` — generated or maintained
  registries.
