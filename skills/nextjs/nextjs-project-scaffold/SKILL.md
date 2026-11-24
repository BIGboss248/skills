---
name: nextjs-project-scaffold
description: >-
  Generate Next.js project registries and canonical config. Use when initializing
  docs/project.json, generating route or site-config registries, or checking
  registry parity.
---

# Project Scaffold Standards

How the canonical project files are generated and kept in sync. This skill writes
configuration and registries only.

## Artifacts

| File | Owns |
| :--- | :--- |
| `docs/project.json` | Deployment, locales, design system, integrations, quality gates, decisions, non-goals |
| `lib/routes.ts` | Every internal route as a typed constant |
| `lib/site-config.ts` | Site name, URL, author, social, defaults |

Schema and field rules: [project schema](./references/project-schema.md).

## Rules

- `docs/project.json` is the single source of truth. Other documents reference
  it; they do not restate it.
- Every route that exists in the router exists in the registry, and every
  registry entry resolves to a real route.
- Route helpers are typed and locale-aware; no string literals in components.
- `site-config.ts` holds no secrets and no environment-specific URLs.
- Generate from the templates, then fill in detected values; do not hand-write
  the shape.

## Parity checks

| Check | Failure means |
| :--- | :--- |
| Registry ↔ `app/` routes | A dead link or an unregistered page |
| Registry ↔ sitemap | A page that cannot be discovered |
| `docs/project.json` ↔ `package.json` scripts | A gate command that does not exist |
| Locales ↔ `messages/*.json` | A locale that renders untranslated |

## Inputs & fallbacks

1. Detect the layouts present: `app/` vs `src/app/`, existing component
   directory, `messages/`, `i18n/`, route folders.
2. Fill missing values from detection, not from guesses.
3. Leave unknown values explicit (`null` plus a decision entry), never invented.

## Definition of Done

- [ ] `docs/project.json` parses and every field is detected or decided.
- [ ] `lib/routes.ts` covers every route and compiles.
- [ ] `lib/site-config.ts` has no secret and no hardcoded environment URL.
- [ ] Every `quality_gates` command exists in `package.json`.
- [ ] Parity checks pass or their absence is reported.
- [ ] No component, page, or test file was written.

## Edge Cases & Pitfalls

- **Two sources of truth** — restating locales or tokens in a second file
  guarantees drift.
- **Registry invented ahead of routes** — an entry with no page is a dead link.
- **Duplicate route keys** — two names for one path break navigation.
- **Guessed locales** — a locale in config with no dictionary renders blanks.
- **Version drift** — a `quality_gates` command renamed in `package.json` but not
  in config.
- **Secrets in site config** — it is imported by client code.

## References

- [Project schema](./references/project-schema.md)
- [project.json template](./resources/templates/project.json.template)
- [routes template](./resources/templates/routes.ts.template)
- [site-config template](./resources/templates/site-config.ts.template)
