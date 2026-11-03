# Implementation Plan Architecture (`docs/plan/`)

This guide explains the modular 7-phase roadmap, the execution-ledger grammar,
the page/component checklist rules, and the amendment protocol.

---

## Modular Plan Directory Structure

```text
docs/plan/
├── README.md                           # Status, gates, amendments, definition of done
├── 01-discovery-and-architecture.md   # Strategy, contracts, route registry
├── 02-environment-and-cicd.md          # Tooling, tests, container, CI
├── 03-system-health-probe.md           # /api/health liveness/readiness
├── 04-core-foundations.md              # Env, i18n, theme, layout, OTel, boundaries
├── 05-pages-and-components.md          # Canonical page/component inventory
├── 06-server-functions-and-metadata.md # Actions, route handlers, global SEO
└── 07-integrations-and-release.md      # Integrations, production, ops, audit
```

The plan is split so an agent can load one phase at a time. `README.md` stays a
thin dashboard; never duplicate checklists into it.

### Template → deployed filename

| Template (`resources/templates/plan/`) | Deploy as (`docs/plan/`) |
| :--- | :--- |
| `README.md.template` | `README.md` |
| `01-discovery.md.template` | `01-discovery-and-architecture.md` |
| `02-environment.md.template` | `02-environment-and-cicd.md` |
| `03-health-probe.md.template` | `03-system-health-probe.md` |
| `04-foundations.md.template` | `04-core-foundations.md` |
| `05-pages.md.template` | `05-pages-and-components.md` |
| `06-apis-metadata.md.template` | `06-server-functions-and-metadata.md` |
| `07-integrations.md.template` | `07-integrations-and-release.md` |

---

## Feature pack slots

Packs compose into these files; they never create new phase files.

| Pack | Home |
| :--- | :--- |
| `health-monitoring` | 3 (probe + metrics), 2 (contract test script), 7 (container probe) |
| `opentelemetry` | 4 (init + kill switch), 2 (harness), 7 (collector destination) |
| `woocommerce` | 1 (ownership/auth), 2 (backend orchestration), 5 (catalog/account pages), 6 (queries, actions, callbacks), 7 (production stack + order proof) |

Pack items carry a `(pack: <id>)` label, keep the standard item grammar, and are
proven under the phase gate they live in. Selection and composition rules:
[feature-packs.md](./feature-packs.md).

---

## Two layers: blueprint + ledger

| Layer | Answers | Lives in |
| :--- | :--- | :--- |
| **Blueprint** | what to build, in what order | phase files |
| **Ledger** | what is done, by which commit, proven how | item fields, gates, `README.md` |

Both are required. A plan without the ledger layer cannot be resumed; a plan
without the blueprint layer cannot be started. See
[execution-ledger.md](./execution-ledger.md) for the full grammar.

---

## Item sizing and shape

- **One item = one commit.** Split anything larger.
- Every item carries: `Depends on`, `Acceptance`, `Evidence`, `Result`, plus
  `Negative case` and `Idempotency` where they apply (see
  [plan-verification.md](./plan-verification.md)).
- Use stable IDs (`1.1`, `4.2`) so commits and review notes can reference them.
- Non-code work is still an item; mark it `manual` on completion.

---

## Chronological ordering and its rationale

The default order optimizes for **early proof of the riskiest integration**:

1. **Discovery** — settle scope, contracts, and names before code exists.
2. **Environment** — a reproducible build and a gate to protect it.
3. **Health probe** — every later phase needs a liveness signal.
4. **Foundations** — env, locale, theme, shell, telemetry, boundaries.
5. **Pages/components** — the visible product.
6. **Server functions & SEO** — mutations, non-page routes, global metadata.
7. **Integrations & release** — production stack, automation, audit.

If the project's highest risk is not the UI (for example a third-party API, a
payment gateway, or a legacy backend), **reorder deliberately** and record the
reason in `## Amendments`. The phases are a default, not a law; what must survive
is the gate-before-next-phase rule.

---

## Phase 5 rules (pages & components)

- **Single canonical source**: only `05-pages-and-components.md` tracks pages and
  components.
- **Mandatory page tasks**: `page.tsx`, `loading.tsx`, `error.tsx`,
  `generateMetadata`, JSON-LD, and `generateStaticParams()` (dynamic/localized).
- **Mandatory component checks**: states, keyboard + `axe`, dictionary-only copy,
  RTL, responsive overflow, a test or story, semantic tokens only.
- **Page completion rule**: tick a page only when every child component and every
  page-level task is complete and verified.
- **Non-page routes** (redirect handlers, webhooks, callback bridges) belong to
  Phase 6 and must appear in `02-sitemap-and-routes.md` §4.

---

## Phase gates

Every phase ends with a gate that names the commands and the observed evidence:

```md
**Phase 3 gate:** `/api/health` answers 200 locally and inside the container.

> **Gate verified 2026-11-03 (3.1–3.3):** 200 local, container `healthy`,
> 3/3 unit tests.
```

A phase with unchecked items may not be marked verified. A verified gate with a
later regression must be re-opened and re-recorded, not edited in place.

---

## Amendments and supersession

Real plans change. Handle it explicitly:

1. Never renumber completed items; add a letter suffix (`4b`, `4c`).
2. Announce the change in `README.md` → `## Amendments` (date, trigger, items,
   downstream impact).
3. Supersede in place: keep the old text and add
   `**Superseded by P4.7:** <reason>`.
4. Re-run affected gates and append a new evidence line.

---

## Deferrals

A skipped item must record a **reason** and a **revisit trigger**. "Not done" and
"deliberately not done" are different states and must look different in the file.

---

## Cross-document consistency

The plan is accepted only when these agree:

- `01-strategy-brief.md` decisions ↔ `project.json` → `decisions`
- `02-sitemap-and-routes.md` routes ↔ `lib/routes.ts` ↔ Phase 5/6 items
- `04-architecture-contracts.md` ownership ↔ `project.json` → `runtime_topology`
- `project.json` → `quality_gates` ↔ commands actually present in `package.json`

Where a fact is necessarily duplicated, add a **drift check** item that fails
loudly when the copies diverge.
