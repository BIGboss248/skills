# Project Specifications Schema Reference (`docs/project.json`)

This reference documents the canonical JSON structure for `docs/project.json`.
The file is the machine-readable counterpart of the strategy brief, the design
contracts, and the plan: if a fact is needed by more than one document, it lives
here once.

---

## Canonical Schema Definition

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "NextJSProjectMetadata",
  "type": "object",
  "required": ["project_context_and_metadata"],
  "properties": {
    "project_context_and_metadata": {
      "type": "object",
      "required": [
        "package_manager",
        "new_component_dir",
        "style_file_dir",
        "component_library",
        "animation_library",
        "testing_library",
        "supported_languages",
        "dictionaries_dir",
        "dictionary_file_pattern"
      ],
      "properties": {
        "package_manager": {
          "type": "string",
          "enum": ["pnpm", "bun", "yarn", "npm"]
        },
        "new_component_dir": { "type": "string" },
        "style_file_dir": { "type": "string" },
        "component_library": { "type": "string" },
        "animation_library": { "type": "array", "items": { "type": "string" } },
        "testing_library": { "type": "array", "items": { "type": "string" } },
        "supported_languages": {
          "type": "array",
          "items": {
            "type": "object",
            "required": [
              "language_code",
              "country_code",
              "currency_code",
              "direction",
              "native_name",
              "calendar_type"
            ],
            "properties": {
              "language_code": { "type": "string" },
              "country_code": { "type": "string" },
              "currency_code": { "type": "string" },
              "direction": { "type": "string", "enum": ["ltr", "rtl"] },
              "native_name": { "type": "string" },
              "calendar_type": { "type": "string" }
            }
          }
        },
        "dictionaries_dir": { "type": "string", "const": "messages" },
        "dictionary_file_pattern": { "type": "string", "const": "[locale].json" }
      }
    },

    "deployment": {
      "type": "object",
      "properties": {
        "target": { "type": "string", "examples": ["vercel", "self-hosted-docker", "cloudflare"] },
        "edge": { "type": ["string", "null"] },
        "tls": { "type": ["string", "null"] },
        "registry": { "type": ["string", "null"] },
        "platforms": { "type": "array", "items": { "type": "string" } },
        "persistence": { "type": "string", "enum": ["bind-mounts", "named-volumes", "managed"] },
        "deploy_method": { "type": "string" }
      }
    },

    "runtime_topology": {
      "type": "object",
      "properties": {
        "services": { "type": "array", "items": { "type": "string" } },
        "ownership": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["path", "owner"],
            "properties": {
              "path": { "type": "string" },
              "owner": { "type": "string" },
              "priority": { "type": ["integer", "null"] }
            }
          }
        }
      }
    },

    "auth": {
      "type": "object",
      "properties": {
        "provider": { "type": "string" },
        "session_transport": { "type": "string", "enum": ["cookie", "token", "none"] },
        "cookie_prefixes": { "type": "array", "items": { "type": "string" } },
        "requires_single_hostname": { "type": "boolean" },
        "invariants": { "type": "array", "items": { "type": "string" } }
      }
    },

    "locale_policy": {
      "type": "object",
      "properties": {
        "default_locale": { "type": "string" },
        "timezone": { "type": "string" },
        "currency": { "type": "string" },
        "currency_display": { "type": "string" },
        "decimals": { "type": "integer" },
        "calendar": { "type": "string" },
        "direction": { "type": "string", "enum": ["ltr", "rtl"] }
      }
    },

    "integrations": {
      "type": "object",
      "properties": {
        "pinning": { "type": "string", "enum": ["exact", "range", "none"] },
        "integrity": { "type": ["string", "null"] },
        "activation_order_matters": { "type": "boolean" },
        "items": { "type": "array", "items": { "type": "object" } }
      }
    },

    "feature_packs": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "enabled", "rationale"],
        "properties": {
          "id": {
            "type": "string",
            "enum": ["health-monitoring", "opentelemetry", "woocommerce"]
          },
          "enabled": { "type": "boolean" },
          "rationale": { "type": "string" },
          "artifacts": { "type": "array", "items": { "type": "string" } },
          "gate": { "type": ["string", "null"] },
          "revisit_if": { "type": ["string", "null"] }
        }
      }
    },

    "quality_gates": {
      "type": "object",
      "properties": {
        "fast": { "type": "array", "items": { "type": "string" } },
        "build": { "type": "array", "items": { "type": "string" } },
        "full": { "type": "array", "items": { "type": "string" } },
        "edge": { "type": "array", "items": { "type": "string" } }
      }
    },

    "constraints": {
      "type": "object",
      "properties": {
        "platform": { "type": "string" },
        "tool_versions": { "type": "object" },
        "reserved_ports": { "type": "array", "items": { "type": "array" } },
        "must_not_touch": { "type": "array", "items": { "type": "string" } }
      }
    },

    "decisions": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "decision", "rationale", "locked_at"],
        "properties": {
          "id": { "type": "string" },
          "decision": { "type": "string" },
          "rationale": { "type": "string" },
          "locked_at": { "type": "string" },
          "supersedes": { "type": ["string", "null"] },
          "revisit_if": { "type": ["string", "null"] }
        }
      }
    },

    "pitfalls": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "rule"],
        "properties": {
          "id": { "type": "integer" },
          "rule": { "type": "string" },
          "symptom": { "type": "string" },
          "discovered_in": { "type": "string" }
        }
      }
    },

    "non_goals": { "type": "array", "items": { "type": "string" } }
  }
}
```

---

## Field Guidelines

1. **`package_manager`** — from the lockfile, never guessed.
2. **`new_component_dir`** — the directory new components are created in.
3. **`style_file_dir`** — the global stylesheet holding semantic tokens.
4. **`dictionaries_dir`** — always `messages` at the project root.
5. **`deployment`** — target, edge, TLS, registry, platforms, persistence. This
   is what makes the Phase 7 plan concrete instead of hypothetical.
6. **`runtime_topology.ownership`** — one row per path; the machine-readable copy
   of the routing ownership matrix. Every row must have a matching plan item.
7. **`auth`** — provider, transport, cookie prefixes, and invariants. Record
   *prefixes*, never full hashed cookie names.
8. **`locale_policy`** — locale, timezone, currency, display unit, decimals,
   calendar, direction. Required for any commerce or regional project; a mismatch
   here (e.g. decimals) corrupts every price assertion.
9. **`feature_packs`** — one row per pack (`health-monitoring`, `opentelemetry`,
   `woocommerce`) with `enabled`, `rationale`, `artifacts`, `gate`, and
   `revisit_if`. Disabled packs are recorded too: a missing row means "never
   considered", which is not the same as "decided against". Pack composition rules
   live in [feature-packs.md](./feature-packs.md); pack-level facts (endpoints,
   collectors, gateways) also belong in `integrations.items`.
10. **`quality_gates`** — the exact commands the plan will cite as acceptance and
    as phase gates. Never write a gate command that does not exist in
    `package.json`.
11. **`constraints`** — platform, tool versions, reserved ports, and the
    `must_not_touch` list. Prevents a plan from proposing work on another
    project's stack.
12. **`decisions`** — locked choices with rationale and a revisit trigger. Newer
    decisions win; mark what they supersede.
13. **`pitfalls`** — the growing failure register. Append during execution; never
    rewrite history. Seed it with the enabled packs' known pitfalls at plan time.
14. **`non_goals`** — explicit exclusions, mirrored in the strategy brief.

---

## Validation

- The file parses as JSON (`node -e "JSON.parse(require('fs').readFileSync('docs/project.json'))"`).
- Every `quality_gates` command exists in `package.json` scripts.
- Every `runtime_topology.ownership` path appears in `02-sitemap-and-routes.md`.
- Every `decisions` entry appears in `01-strategy-brief.md` §5.
- Every `feature_packs` entry appears in `01-strategy-brief.md` and owns items in
  its mapped phases; every disabled pack has a `revisit_if`.
- No secret, token, or credential value is stored — only names and prefixes.
