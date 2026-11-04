# Feature Packs Reference

A **feature pack** is an optional capability track that the plan can compose into
the fixed 7-phase roadmap. Packs never add phases, never rename phases, and never
pre-empt the page/component inventory: they add **items inside existing phases**,
plus the gates and evidence needed to prove the capability works.

Available packs:

| Pack id | Capability | Runbook |
| :--- | :--- | :--- |
| `health-monitoring` | `/api/health` liveness/readiness probe, runtime metrics, container probes | [health-monitoring.md](./features/health-monitoring.md) |
| `opentelemetry` | OTel tracing, `instrumentation.ts`, kill switch, trace verification | [opentelemetry.md](./features/opentelemetry.md) |
| `woocommerce` | Headless WooCommerce storefront: catalog, JWT auth, cart, native checkout | [woocommerce.md](./features/woocommerce.md) |

---

## 1. Selection protocol

1. **Detect first** — scan for the signals below during workspace inspection; do
   not ask for what the files already answer.
2. **Ask once, per pack** — one numbered question with a recommendation, inside
   the interview's integrations round.
3. **Record the outcome** — `docs/project.json` → `feature_packs[]` with
   `id`, `enabled`, `rationale`, `artifacts`, `gate`, and `revisit_if`.
4. **Disabled is a decision** — a disabled pack is still written down with a
   revisit trigger; never quietly drop it.

### Detection signals

| Pack | Signals in the workspace |
| :--- | :--- |
| `health-monitoring` | `docker-compose*.yml`, `Dockerfile`, `/api/health` route, ORM dependencies (Prisma, Drizzle, `pg`, `mysql2`, Redis, Mongoose), orchestrator healthchecks |
| `opentelemetry` | `@vercel/otel`, `@opentelemetry/*`, `instrumentation.ts`, `OTEL_*` keys in env templates, existing collector endpoints |
| `woocommerce` | `graphql` client, `wordpress`/`woocommerce` env keys, `traefik`/`caddy` config, `mu-plugins/`, cart/session cookies, `@wordpress/*` packages |

### Pack question shape

```md
❓ **Q7** - **Capability packs**: this workspace already ships a compose stack and
an ORM, so health monitoring is a candidate. Do you want `health-monitoring`,
`opentelemetry`, and/or `woocommerce` planned as first-class tracks?

➡️ **Recommended**: enable `health-monitoring` (probe already implied by the
compose file), enable `opentelemetry` when a collector endpoint exists, and enable
`woocommerce` only if the storefront consumes a headless WooCommerce backend.
```

---

## 2. Pack → phase mapping

| Pack | Phases touched | Items | Gate |
| :--- | :--- | :--- | :--- |
| `health-monitoring` | 2, 3, 7 | 2.x test script, 3.1–3.4, 7.x compose probes | Phase 3 gate |
| `opentelemetry` | 2, 4, 7 | 2.x harness script, 4.5, 7.x collector/env | Phase 4 gate |
| `woocommerce` | 1, 2, 5, 6, 7 | 1.x ownership + auth contracts, 2.x backend orchestration, 5.x catalog pages, 6.x actions/queries/callbacks, 7.x production stack | Phase 7 gate |

Rules:

- **Phase 3 is the only home for the health probe.** Never duplicate it in
  Phase 4 or Phase 7; Phase 7 may only add container wiring.
- **Phase 4 owns telemetry initialization.** Phase 7 owns exporter destination
  and retention.
- **Phase 5 stays the single page/component checklist.** Commerce pages are pages
  like any other; the pack adds per-page acceptance lines, not a second list.
- **Phase 6 owns every non-page route** (GraphQL proxy, webhook, gateway
  callback).

---

## 3. Item composition grammar

Pack items use the same grammar as every other item
([execution-ledger.md](./execution-ledger.md)) with three extra obligations:

```md
- [ ] **3.4 Dependency probe (pack: health-monitoring)**
  - **Depends on:** 3.1
  - **Acceptance (command → expected):** `curl -s localhost:3000/api/health | jq -r .checks.db.status` → `healthy`; p95 latency < 500 ms
  - **Negative case:** stop the database container → `503` and `checks.db.status = "unhealthy"` within 2 s
  - **Idempotency:** repeated probes create no connections that outlive the request
  - **Evidence:** probe JSON before/after, latency samples
  - **Result:** —
```

1. **Label the pack** in the item title: `(pack: <id>)`.
2. **Name the pack file** in the item body when the implementer needs detail
   (`See references/features/<pack>.md §N`).
3. **Gate the pack** with a pack-specific evidence line, pasted under the phase
   gate — never as a separate gate section.

Amendments: adding a pack after the plan is locked is an amendment
(`Phase 4b`), announced in `docs/plan/README.md` with the trigger and downstream
impact.

---

## 4. Cross-pack interactions

| Combination | Interaction the plan must encode |
| :--- | :--- |
| `health-monitoring` + `opentelemetry` | the health route stays inside the traced server runtime; the kill switch must still silence exports when health is polled every 10 s |
| `health-monitoring` + `woocommerce` | the probe checks the GraphQL endpoint with a 2 s timeout and reports `degraded` (not `unhealthy`) on slow backend latency |
| `opentelemetry` + `woocommerce` | client/checkout spans must not carry tokens, cart cookies, or customer PII; gateway callbacks get their own span name |
| all three | Phase 7 gate proves: healthy container, exported trace, and a completed order/critical flow |

---

## 5. Verification hooks per pack

| Pack | Minimum commands the plan cites |
| :--- | :--- |
| `health-monitoring` | `curl -sf localhost:3000/api/health`, `docker compose ps`, targeted unit test for the route contract |
| `opentelemetry` | `node scripts/mock_collector.js`, `curl localhost:3000/`, kill-switch run with `OTEL_SDK_DISABLED=true`, `tsc --noEmit` |
| `woocommerce` | catalog query returns products, `login` returns `authToken`, cart query retains an item after `addToCart`, `/wc-api/<Gateway>/` → 307 to `/checkout/?wc-api=...`, `pnpm build` |

Every hook must be a real command in `package.json` or a documented one-liner; a
pack whose verification cannot be executed is a pack that cannot be planned.

---

## 6. Deferral and failure rules

- **Deferring a pack** is allowed: mark every generated item `Skipped on purpose`
  with a reason and a revisit trigger.
- **Partially enabling a pack** is not allowed. If `woocommerce` is enabled, the
  auth, cart, and callback items all exist; disabling one of them is a decision
  (`project.json` → `decisions`), not an omission.
- **A pack's known pitfalls are seeded into `project.json` → `pitfalls`** at plan
  time so the implementing agent inherits them instead of rediscovering them.
- **Pack failures do not silently downgrade gates.** If trace export works but
  the kill switch does not, Phase 4 is not verified.
