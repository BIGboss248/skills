# Grilling Interview Reference Guide

This guide details the interview methodology, question structuring, and inquiry
areas for Next.js App Router planning.

---

## Grilling Methodology & The Frontier

The interview is a **design tree**: high-level decisions branch into downstream
technical requirements.

### The Questioning Protocol

1. **Work the frontier in rounds**: group open decisions whose prerequisites are
   already met.
2. **Always number and recommend**: number each question and give a reasoned
   recommendation based on the inspected workspace.
3. **Wait for the user's answer**: do not execute later rounds on assumptions.
4. **Research facts yourself**: inspect the codebase instead of asking.
5. **Lock every answer**: confirmed answers go into `01-strategy-brief.md` §5 and
   `project.json` → `decisions` in the same turn.

### Question round format

```markdown
❓ **Q1** - **<Question Title>**: <clear question and options>

➡️ **Recommended**: <choice + rationale>

---

❓ **Q2** - **<Question Title>**: <clear question and options>

➡️ **Recommended**: <choice + rationale>
```

---

## Mandatory Step 1 Grilling Sequence (Pages ➔ Sections ➔ Components)

> [!IMPORTANT]
> **Strict hierarchy rule**: drill down three levels in order.
>
> 1. **Pages**: exact routes and URLs.
> 2. **Sections**: for each page, sections from top to bottom.
> 3. **Components**: for each section, the individual UI components.

---

## Core Areas of Inquiry

### 1. Page Inventory & Routes

- Which pages must exist, and at which URLs?
- Which are primary navigation vs footer vs utility/detail?
- Which routes are dynamic (`/projects/[slug]`)?
- Which **non-page** routes exist: redirects, webhooks, callbacks, health?

### 2. Page Sections

- For every page, which sections, in what order, and what is each one's job?

### 3. Component Inventory

- For every section, which components?
- Which are shared (`SiteHeader`, `Card`) vs page-specific?
- Which need client interactivity, and which stay server-rendered?

### 4. Product Purpose & Audience

- What problem does this solve?
- Who are the users, where are they, and what language/script do they read?

### 5. Authentication & Authorization

- Is auth required, and at which routes?
- Who owns credentials, registration, reset, and logout?
- Where does the session live — cookie, token, or provider-managed?
- Does the app ever mint a second session (it should not)?
- What renders when the session is missing or expired — and is that fail-open?

### 6. Data Layer & Content Management

- Storage: Postgres, SQLite, Supabase, Redis, files?
- Access: ORM, query builder, server functions?
- CMS: in-repo, headless, MDX, or none?
- What is the source of truth for prices, stock, or user state?

### 7. Internationalization & Locales

- Which languages and which locale is default?
- RTL requirements and font pairings?
- Timezone, currency, display unit, decimals, and calendar?
- Dictionaries always live in root `messages/`.

### 8. Visual Aesthetic & Tokens

- Emotional tone, brand colors, contrast, radius.
- Multi-font pairing (display + body) vs a single family.
- Any existing design system the project must reuse.

### 9. Runtime Topology & Ownership

- What services run in dev and in production (app, backend, database, edge)?
- Which service answers which path? Produce the ownership matrix together.
- Where does TLS terminate, and which resolver is used?
- Is there a callback/webhook path that must bypass bot protection?

### 10. Persistence & Data Lifecycle

- Named volumes or bind mounts, in dev and in prod?
- Where do uploads live?
- How is the database backed up, restored, and migrated to a new host?
- What must be stopped before copying state?

### 11. Integrations & Pinning

- Which third-party plugins/packages/APIs are required (vs optional)?
- Are versions pinned, and are hashes published upstream?
- Does activation order matter?
- Which integrations run at build time vs runtime?

### 12. Quality Gates & Verification

- What exact commands prove the work (lint, types, unit, e2e, build, smoke)?
- Which of them run offline, and which need the full stack up?
- What negative case proves a guard actually guards?
- What is the single command a new contributor runs?

### 13. Non-Goals, Deferrals & Revisit Triggers

- What is explicitly out of scope for this iteration?
- For each skip: why now, and what event would bring it back?
- What is deferred until a later phase (and which item is the trigger)?

### 14. Deployment & Operations

- Target platform (Docker/VPS, Vercel, Cloudflare)?
- Registry, image names, platforms (amd64/arm64)?
- Who updates what: automatic for the app, manual for stateful services?
- Health monitoring, tracing, and release automation?

### 15. Capability Pack Selection

- Which packs apply: `health-monitoring`, `opentelemetry`, `woocommerce`?
- For a **disabled** pack: why not now, and what event brings it back?
- Is an existing probe, collector, or store chain to be reused instead of added?
- Which pack items are the riskiest, and does the phase order expose them early?

One numbered question per pack, with a recommendation derived from the inspected
signals. Record the outcome in `project.json` → `feature_packs` (enabled and
disabled) in the same turn.

### 16. Platform & Safety Constraints

- OS limits (reserved ports, path length, line endings).
- Resources that must not be touched (other stacks, shared networks, global
  config).
- Destructive actions and their restore commands.

---

## Locking the answers

Before moving to plan generation:

1. Copy every confirmed answer into `01-strategy-brief.md` §5 as a table row
   (`ID | Decision | Rationale | Locked | Revisit if`).
2. Mirror it into `project.json` → `decisions` and `feature_packs`.
3. Record exclusions in `non_goals`.
4. Record known risks in the pitfall seed table, including the enabled packs'
   known pitfalls.

An answer that is not written down is not locked, and will be re-litigated by the
next agent.
