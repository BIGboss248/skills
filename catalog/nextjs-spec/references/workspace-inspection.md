# Workspace Inspection Reference Guide

This guide details the automated, zero-interruption inspection protocol to extract
project facts before the interview.

---

## Zero-Interruption Rule

> [!IMPORTANT]
> **Inspect first, ask later.** Never ask for configuration details, dependencies,
> or architectural choices that can be determined from workspace files.

The same rule applies in reverse: **inspect what you must not touch.** A plan that
proposes changes to another project's stack is worse than no plan.

---

## Inspection Checklist & Discovery Matrix

### 1. Package Manager & Tooling

- **`package.json`**: `packageManager`, engines, scripts.
- **Lockfiles**: `pnpm-lock.yaml`, `bun.lockb`/`bun.lock`, `yarn.lock`,
  `package-lock.json`.
- **Versions**: `next`, `react`/`react-dom`, `typescript`, Node engine range.

Record the **exact** versions; they change API behavior between majors.

### 2. Directory Layout & Routing Architecture

- `src/app/` vs `app/`; component directories; `public/` assets.
- Existing `page.tsx`, `route.ts`, `proxy.ts`/`middleware.ts`, `layout.tsx`.
- Whether the convention is `middleware` (older) or `proxy` (newer) — record
  which one this Next.js version expects.

### 3. Styling & Design Token System

- Global stylesheet location.
- Tailwind v3 config vs v4 `@theme` / `@import "tailwindcss"`.
- Semantic tokens already present (`--background`, `--primary`, ...); note any
  raw palette usage that the plan must not copy.

### 4. UI Primitives, Animation & Icons

- `components.json` (shadcn/ui), Radix/Headless/Base UI.
- Animation libraries and icon packages.

### 5. Internationalization

- `next-intl` presence, root `messages/` (never `app/dictionaries`).
- `app/[locale]/`; routing helper or proxy negotiation.
- RTL support and font configuration.

### 6. Existing Routes & Handlers

- All `page.tsx` → information architecture.
- All `route.ts` → APIs, redirects, webhooks, callbacks.
- `'use server'` actions.

### 7. Testing, Containers & Tooling

- Jest/Vitest/Playwright configs and the scripts that run them.
- Dockerfiles, compose files, `.dockerignore`.
- `AGENTS.md`, `opencode.json`, `.agents/`, `docs/`.

### 8. External Resources (do not touch)

- Sibling repositories and reference implementations (read-only).
- Shared Docker networks, edge proxies, and platform stacks.
- Global config (`~/.config`, host MCP config, shell profiles).
- Databases or volumes owned by other projects.

Record a **must_not_touch** list in `project.json` → `constraints`.

### 9. Port & Resource Contention

- What already binds 80/443/3000/5432/3306 on this machine.
- OS-reserved ranges (Windows reserves blocks of dynamic ports).
- Running containers that own a shared network or a hostname.
- For each conflict: stop / reuse / re-map — and the restore command for anything
  stopped.

### 10. Current-State Delta (brownfield)

Before planning changes to a live system, write four lists:

| Exists | Reused | Replaced | Retired |
| :--- | :--- | :--- | :--- |
| [files, routes, services] | [kept as-is] | [rewritten] | [removed] |

This prevents a plan from re-deriving a working configuration incorrectly, and it
makes the blast radius of the change explicit.

### 11. Destructive Actions

- Identify anything that deletes data, recreates volumes, rotates secrets, or
  migrates a database.
- Require an explicit confirmation flag in the plan.
- Record the **restore command** before the destructive step is approved.

---

### 12. Feature Pack Signals

Detect the optional capability tracks before the interview asks about them:

| Pack | Look for |
| :--- | :--- |
| `health-monitoring` | `app/api/health/route.ts`, compose files, `Dockerfile`, ORM/Redis clients, existing `healthcheck:` blocks |
| `opentelemetry` | `@vercel/otel`, `@opentelemetry/*`, `instrumentation.ts`, `OTEL_*` env keys, a collector endpoint/port |
| `woocommerce` | `graphql` client, WordPress/WooCommerce env keys, Traefik/Caddy config, `mu-plugins/`, cart/session cookies |

Record each as **enabled candidate**, **explicitly absent**, or **conflicting**
(an existing third-party probe/collector the plan must reuse). Composition rules
are in [feature-packs.md](./feature-packs.md).

---

## Outputs of inspection

Feed these directly into `01-strategy-brief.md`, `04-architecture-contracts.md`,
and `docs/project.json` — never re-ask the user for them.
