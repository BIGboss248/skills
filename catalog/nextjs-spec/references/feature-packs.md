# Capability Tracks

Optional capability tracks that compose into the 7-phase ledger. A track **adds
items to existing phases** — never a new phase, never a second page list, never a
second gate.

Each track is implemented by its own skill; this file only defines how to plan it.

## Track matrix

| Track | Detection signals | Planned in | Owner |
| :--- | :--- | :--- | :--- |
| `health-monitoring` | Health route, compose healthcheck, DB drivers | Phase 3, wired in Phase 7 | `nextjs-health-probe` |
| `opentelemetry` | `@vercel/otel`, `@opentelemetry/*`, `instrumentation.ts`, `OTEL_*` | Phase 4, exporter in Phase 7 | `nextjs-opentelemetry` |
| `woocommerce` | WooCommerce, WPGraphQL, Traefik, JWT markers | Phases 1–2, 5–7 | `headless-woocommerce-api` |

## Planning rules

1. **Detect before asking.** Record the signal that enabled or disabled the track.
2. **One question per track**, with a recommendation derived from the signals.
3. **Disabled tracks keep a revisit trigger.** Never delete them silently.
4. **Label every item** `(track: <id>)` so the ledger can be filtered.
5. **Prove the track under the phase gate it lives in.** A track that only has
   items but no gate evidence is unfinished.
6. **No track creep.** If a track seems to need a new phase, the phase model is
   wrong — re-decide it, do not special-case.

## Cross-track interactions

| Interaction | Requirement |
| :--- | :--- |
| Health + database | The readiness probe reflects the store used by the app |
| OTel + health | The probe must not be traced as a user request or inflate metrics |
| OTel + commerce | Cart and checkout spans carry no tokens or PII |
| Health + container | The compose healthcheck uses Node `fetch`, not `curl` |
| Commerce + i18n | Product and checkout copy lives in dictionaries |

## Recorded state

`docs/project.json → feature_packs` holds the enabled and disabled set:

- `enabled`: track id, planned phase items, gate evidence location.
- `disabled`: track id, signal that ruled it out, revisit trigger.

A track enabled after plan lock-in is an **amendment** (`4b`, `5b`), never a
renumbering of completed items.
