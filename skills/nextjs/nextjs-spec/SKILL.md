---
name: nextjs-spec
description: >-
  Define the Next.js project specification. Use when a project needs routes,
  locales, tokens, architecture contracts, or capability decisions recorded
  before work is planned.
---

# Next.js Specification

Produces the stack specification a planner needs. This skill does not plan,
decompose, or implement: work specs and tickets belong to `to-spec` and
`to-tickets`, and registries to `nextjs-project-scaffold`.

## Scope

| Owns | Does not own |
| :--- | :--- |
| Stack facts and constraints | Requirement elicitation (`grilling`) |
| Route, locale, token, and architecture decisions | Work spec (`to-spec`) |
| `docs/design/01`–`04` contracts | Ticket breakdown (`to-tickets`) |
| Capability detection (health, OTel, commerce) | Registries (`nextjs-project-scaffold`) |

## Inputs & fallbacks

1. The workspace: manifests, `app/` vs `src/app/`, component directory,
   `globals.css`, `next-intl`, existing pages and routes, test and container
   config.
2. `docs/project.json` when it exists; otherwise derive and record decisions.
3. Missing user decisions are supplied by `grilling`; this skill lists what must
   be decided, not how to ask.

## 1. Inspect

- Stack facts: package manager, App Router layout, component directory, styling,
  UI and icon libraries, i18n, tests, container, CI.
- Constraints: OS limits, occupied ports, shared networks, sibling repos,
  destructive actions and their restore commands.
- Capability signals: health route or compose stacks, OTel packages,
  commerce/GraphQL markers.
- Brownfield delta: exists / reused / replaced / retired.
- Reference: [workspace inspection](./references/workspace-inspection.md).

## 2. Decide

Every row must be answered or explicitly deferred with a revisit trigger.

| Decision | Recorded in |
| :--- | :--- |
| Routes, rendering mode, non-page routes | `02-sitemap-and-routes` |
| Locales, default locale, RTL | `docs/project.json → locale_policy` |
| Semantic tokens, typography, primitives | `03-ui-design-tokens` |
| Auth, session, persistence, topology | `04-architecture-contracts` |
| Data sources and caching strategy | `04-architecture-contracts` |
| Quality gates and their commands | `docs/project.json → quality_gates` |
| Non-goals and constraints | `01-strategy-brief` |

Elicitation is `grilling` / `grill-with-docs`. This skill supplies the questions'
subject matter and persists the answers.

## 3. Write the contracts

| Document | Template |
| :--- | :--- |
| `01-strategy-brief` | [template](./resources/templates/01-strategy-brief.md.template) |
| `02-sitemap-and-routes` | [template](./resources/templates/02-sitemap-and-routes.md.template) |
| `03-ui-design-tokens` | [template](./resources/templates/03-ui-design-tokens.md.template) |
| `04-architecture-contracts` | [template](./resources/templates/04-architecture-contracts.md.template) |

- Routes in the sitemap, the registry, and the rendering matrix must agree.
- Every token named must exist in the theme.
- Detail: [architecture contracts](./references/architecture-contracts.md).

## 4. Detect capability tracks

| Track | Signal | Owner |
| :--- | :--- | :--- |
| Health probe | Health route, compose healthcheck | `nextjs-health-probe` |
| OpenTelemetry | `@vercel/otel`, `instrumentation.ts`, `OTEL_*` | `nextjs-opentelemetry` |
| Commerce | WooCommerce, WPGraphQL, JWT markers | `headless-woocommerce-api` |

Record enabled and disabled tracks with a revisit trigger. A track adds
specification items, never a phase list. Protocol:
[capability tracks](./references/feature-packs.md).

## 5. Hand off

- State the specification paths and the decisions still open.
- Hand to `to-spec` for the work spec, then `to-tickets` for decomposition.
- Do not generate tickets, a ledger, a roadmap, or `docs/plan/` here.
- Do not invoke downstream skills.

## Definition of Done

- [ ] Stack facts are recorded, not assumed.
- [ ] Every decision row is answered or deferred with a trigger.
- [ ] Contracts 01–04 exist and agree with `docs/project.json`.
- [ ] Capability tracks are recorded with owners.
- [ ] No ledger, roadmap, ticket, or code file was written.

## Edge Cases & Pitfalls

- **Static blueprint** — a specification without decisions is a wish list.
- **Duplicated facts** — restating locales or tokens outside
  `docs/project.json` guarantees drift.
- **Asking before inspecting** — never ask what the workspace answers.
- **Token drift** — a planned color absent from the theme becomes a hardcoded
  hex.
- **Track creep** — a track adds specification items, never phases.
- **Planning here** — producing a ledger or roadmap recreates the conflict this
  split removed.
- **Premature implementation** — a specification is not authorization to build.

## References

- [Workspace inspection](./references/workspace-inspection.md)
- [Architecture contracts](./references/architecture-contracts.md)
- [Capability tracks](./references/feature-packs.md)
- [Templates](./resources/templates/)
