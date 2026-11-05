# Project Configuration Schema Specification (`docs/project.json`)

The `docs/project.json` file is the mandatory single source of truth for component creation, package manager, styling rules, animation engines, testing suites, and internationalization across all agent skills (such as `nextjs-component-dev` / `nextjs-component-create`).

---

## 1. Complete Properties Specification (`project_context_and_metadata`)

| Property Name             | Type                  | Description                                                                 | Discovery / Example                                                                                      |
| :------------------------ | :-------------------- | :-------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------- |
| `package_manager`         | `string`              | Package manager used in the project (`"pnpm"`, `"npm"`, `"yarn"`, `"bun"`). | Auto-discovered from lockfiles or `package.json` `"packageManager"`.                                     |
| `new_component_dir`       | `string`              | Target directory where components, skeletons, and unit tests are created.   | Auto-discovered from `app/` or `src/` (e.g. `"app/components"` or `"src/components"`).                   |
| `style_file_dir`          | `string`              | Relative path to the global CSS / theme stylesheet.                         | Auto-discovered from stylesheet path (e.g. `"app/globals.css"` or `"src/app/globals.css"`).              |
| `component_library`       | `string`              | UI component library or design system adopted in the project.               | Discovered from `package.json` dependencies / `docs/` (e.g. `"shadcn/ui"`, `"radix-ui"`, `"none"`).      |
| `theme_strategy`          | `string?`             | Selector strategy used for light/dark switching.                            | Written by N13. One of `"class"`, `"data-theme"`, `"data-mode"`; must match the token stylesheet.         |
| `theme_storage_key`       | `string?`             | `localStorage` key that stores the user's theme choice.                     | Written by N13; defaults to `"theme"`.                                                                   |
| `theme_toggle_path`       | `string?`             | Path to the deployed theme toggle component.                                | Written by N13 (e.g. `"app/components/ThemeToggle.tsx"`).                                                |
| `animation_library`       | `Array<string>`       | Motion and animation libraries used for complex animations.                 | Discovered from `package.json` / `docs/adr/` (e.g. `["gsap"]`, `["framer-motion"]`, `["none"]`).         |
| `testing_library`         | `Array<string>`       | Testing frameworks and libraries configured in the project.                 | Discovered from `package.json` / config files (e.g. `["jest", "playwright", "@testing-library/react"]`). |
| `supported_languages`     | `Array<LocaleObject>` | List of supported locales with direction, currency, and calendar metadata.  | Discovered from `docs/adr/`, `docs/project-plan.md`, or `CONTEXT.md`.                                    |
| `dictionaries_dir`        | `string`              | Relative directory path for i18n translation message catalogs.              | Defaults to `"messages"` (or `"src/messages"` / `"dictionaries"`).                                       |
| `dictionary_file_pattern` | `string`              | Filename naming pattern for locale translation JSON files.                  | Defaults to `"[locale].json"`.                                                                           |
| `agents`                  | `object`              | Agent roster installed by feature N9 (orchestrator + three role agents).   | Written by `nextjs-dev-setup`; records paths, model overrides, and `enabled` flags.                      |
| `nextjs_setup_features`   | `object`              | Confirmed feature selection (preset, categories, enabled/disabled, notes).  | Written by `nextjs-dev-setup` Phase 1; mirrors `.agents/nextjs-setup-features.json`.                     |

Optional keys (`theme_strategy`, `theme_storage_key`, `theme_toggle_path`) are
written only when N13 is enabled. They record the detected strategy; they never
prescribe a CSS file structure, token vocabulary, or color space.

### 1.1 Agent Roster Object (`agents`)

```json
{
  "roster": "three-role",
  "orchestrator": {
    "agent": "nextjs-orchestrator",
    "path": ".opencode/agents/nextjs-orchestrator.md",
    "model": null,
    "enabled": true
  },
  "roles": [
    { "role": "implementation", "agent": "nextjs-dev", "path": ".opencode/agents/nextjs-dev.md", "model": null, "enabled": true },
    { "role": "test-author", "agent": "nextjs-test-author", "path": ".opencode/agents/nextjs-test-author.md", "model": null, "enabled": true },
    { "role": "qa-auditor", "agent": "nextjs-qa-auditor", "path": ".opencode/agents/nextjs-qa-auditor.md", "model": null, "enabled": true }
  ],
  "boundaries_rule": ".agents/rules/agent-boundaries.md",
  "worktree_isolation": {
    "enabled": true,
    "helper": "scripts/agent-worktree.ps1",
    "branch_prefix": "agent/",
    "base_branch": "main",
    "merge_requires_approval": true,
    "on_conflict": "ask_user"
  },
  "test_tiers": {
    "development": "fast",
    "prepush": "full",
    "prepush_script": "test:prepush"
  },
  "commands": [
    ".opencode/commands/create-nextjs-component.md",
    ".opencode/commands/create-nextjs-page.md"
  ]
}
```

- `roster`: `"three-role"` only. A two-role repository is out of contract because it loses the independent auditor.
- `model`: `null` inherits the primary agent's model; otherwise a `provider/model` string.
- `enabled: false` means the file stays on disk but the orchestrator must not delegate to it.
- `worktree_isolation.merge_requires_approval` must stay `true`: the agent branch
  merges into `base_branch` only after the user approves the review summary.
- `worktree_isolation.on_conflict` must stay `"ask_user"`: agents never resolve a
  merge conflict themselves.
- `test_tiers.development` must stay `"fast"`; `prepush` is the only local
  execution point for Playwright and the full Jest project.

### 1.2 Feature Selection Object (`nextjs_setup_features`)

```json
{
  "skill": "nextjs-dev-setup",
  "preset": "standard",
  "decided_at": "YYYY-MM-DD",
  "categories": ["foundation", "testing", "agents", "delivery"],
  "enabled": ["N1", "N2", "N3", "N4", "N5", "N6", "N8", "N9", "N10", "N12"],
  "disabled": ["N7", "N11"],
  "degraded": {},
  "notes": {}
}
```

- The canonical record is `.agents/nextjs-setup-features.json`; this block is the
  copy other skills read.
- `enabled` drives which audits `scripts/verify-project-config.*` runs; features
  outside the list are reported as `SKIPPED`.
- Dictionary keys (`dictionaries_dir`, `dictionary_file_pattern`) are required only
  when `N4` is enabled; agent metadata only when `N9` is enabled.

---

## 2. Locale Object Schema (`supported_languages[...]`)

Each entry in the `supported_languages` array contains:

- **`language_code`** (`string`): ISO 639-1 two-letter language code (e.g. `"en"`, `"fa"`, `"ar"`, `"de"`, `"fr"`).
- **`country_code`** (`string`): ISO 3166-1 alpha-2 country code (e.g. `"US"`, `"IR"`, `"GB"`, `"DE"`).
- **`currency_code`** (`string`): ISO 4217 three-letter currency code (e.g. `"USD"`, `"IRR"`, `"EUR"`, `"GBP"`).
- **`direction`** (`string`): Reading direction — strictly `"ltr"` (Left-to-Right) or `"rtl"` (Right-to-Left).
- **`native_name`** (`string`): Autonym / native display name of the language (e.g. `"English"`, `"فارسی"`, `"العربية"`).
- **`calendar_type`** (`string`): Primary calendar system (e.g. `"gregorian"`, `"persian"`, `"islamic"`).

---

## 3. Automated Discovery Protocol (Zero Interruption Rule)

> [!IMPORTANT]
> **DO NOT ASK THE USER IF INFORMATION IS FOUND IN `docs/` OR REPOSITORY FILES.**
> Scan the repository files and documentation in `docs/` first. Automatically extract all available configurations. Only prompt the user for fields that are genuinely missing, unresolvable, or ambiguous.

1. **Scan `docs/` and Root Documentation:**
   - Scan `docs/project-plan.md`, `docs/plan.md`, `docs/adr/*.md`, `docs/agents/*.md`, and `CONTEXT.md`.
   - Extract architectural choices:
     - **Languages & Directionality:** Check `docs/adr/0001-bilingual-i18n-and-directionality.md`, `docs/project-plan.md`, or `CONTEXT.md` for language list (e.g. `en` and `fa`, LTR and RTL).
     - **Animation & UI Stack:** Check `docs/adr/0002-local-mdx-and-gsap-interaction-stack.md` or `docs/project-plan.md` (e.g. GSAP, Tailwind CSS, shadcn/ui).
     - **Testing Frameworks:** Check `package.json` dependencies / config files (e.g. `jest.config.ts`, `playwright.config.ts`, `jest`, `@playwright/test`, `@testing-library/react`).

2. **Scan Package Manager (Automated Detection):**
   - Inspect `package.json` for `"packageManager"` field (e.g., `"packageManager": "pnpm@11.22.0"` -> `"pnpm"`).
   - Check lockfiles present in workspace:
     - `pnpm-lock.yaml` -> `"pnpm"`
     - `bun.lockb` / `bun.lock` -> `"bun"`
     - `yarn.lock` -> `"yarn"`
     - `package-lock.json` -> `"npm"`

3. **Scan Project Layout & Stylesheet Paths:**
   - Check whether the repository uses `src/app/` or `app/`:
     - If `app/` exists at root -> set `new_component_dir` to `"app/components"`.
     - If `src/app/` exists -> set `new_component_dir` to `"src/components"`.
   - Locate global stylesheet:
     - Check `app/globals.css`, `src/app/globals.css`, `app/global.css`, `src/styles/globals.css` -> set `style_file_dir`.

4. **Scan Installed Dependencies (`package.json`):**
   - Check `dependencies` and `devDependencies`:
     - Component libraries: `radix-ui`, `shadcn`, `@headlessui/react`, etc.
     - Styling & Design System Linters: `@shadcn/lint`, `eslint`, `eslint-config-next`, `eslint-plugin-storybook`.
     - Animation libraries: `gsap`, `@gsap/react`, `framer-motion`, `motion`, `tailwind-animate` (stored as an array of strings in `animation_library`).
     - Testing & Workshop libraries: `jest`, `jest-environment-jsdom`, `@testing-library/react`, `@testing-library/jest-dom`, `@playwright/test`, `playwright`, `storybook`, `@storybook/nextjs-vite` (stored as an array of strings in `testing_library`).
     - Git hooks & commit standards: `husky`, `@commitlint/cli`, `@commitlint/config-conventional`, `lint-staged`.
