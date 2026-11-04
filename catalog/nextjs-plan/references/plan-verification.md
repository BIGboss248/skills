# Plan Verification Reference

A checklist item is only real when a command can prove it. This reference defines
the acceptance archetypes every plan item should use, plus the self-audit the
agent runs on the finished plan.

---

## 1. The four acceptance archetypes

Reuse these instead of inventing bespoke criteria.

### A. Command gate (code quality)

```md
- **Acceptance:** `pnpm lint` → 0, `pnpm exec tsc --noEmit` → 0, `pnpm test` → 0
- **Evidence:** suite count, coverage %
```

Use for: tooling, config, pure functions, components, refactors.

### B. Live probe (runtime contract)

```md
- **Acceptance:** `curl -sf https://<host>/api/health` → 200 with
  `{ status: "ok", version, commit, timestamp }`
- **Negative:** removing a required env var makes the endpoint return 503
```

Use for: health checks, routing ownership, proxies, headers, auth handoff.

### C. Negative gate (must fail)

```md
- **Negative case:** a deliberately broken PR fails at the unit-test job; a
  foreign billing country is rejected at checkout; `//evil.com` is not accepted
  as a redirect target
```

At least one negative case is mandatory for: auth, permissions, redirects,
validation, payments, and any path with a silent fallback (for example "guest"
when a session is missing). A plan with no negative cases cannot distinguish
"works" from "fails open".

### D. Resilience gate (idempotency & recreation)

```md
- **Idempotency:** running setup twice reports zero drift in products, options,
  plugins, and zones.
- **Recreation:** destroy and rebuild the container five times; the image
  contract still passes every time.
```

Use for: seeders, installers, migrations, container images, infrastructure,
release automation.

---

## 2. UI item acceptance

Every page or component item additionally needs:

- **Rendering states**: loading skeleton, empty state, error boundary, not-found.
- **Accessibility**: automated `axe` scan is clean; keyboard path reaches every
  control.
- **Localization**: all visible copy comes from the dictionary; no hard-coded
  strings.
- **Directionality**: RTL layout has no clipped or reordered content (use
  `dir="auto"` for mixed-direction values such as prices).
- **Responsive**: smallest and largest breakpoint both render without overflow.

Keep these as a reusable block in Phase 5 so no page omits them.

---

## 3. Cross-artifact drift checks

Whenever the same fact is written twice, the plan must include an item that
fails loudly when the copies diverge:

- Manifest ↔ Dockerfile build args ↔ installer script.
- `docs/project.json` ↔ `lib/routes.ts` ↔ the Phase 5 route inventory.
- Design tokens ↔ `globals.css` ↔ component usage.
- Environment variable list ↔ `.env.example` ↔ `.env.development` ↔ deployment
  config.
- `project.json` → `feature_packs` ↔ strategy brief ↔ labeled `(pack: …)` items in
  the mapped phases.

Shape:

```md
- [ ] **P5.2** Pin verification
  - **Acceptance:** `scripts/fetch-plugins.ps1` reports `8/8 OK`; changing one
    version in the manifest without the Dockerfile fails the check
```

A plan that duplicates a fact without a drift check is a future inconsistency.

---

## 4. Evidence rules

- Paste **observed output**, not a summary: `32/32`, `93 unit + 3 browser`,
  `30 passed / 1 skipped`, `sha256:56d5…`, `200`.
- Record the **date** for gate-level evidence.
- Record **deviations**: what changed from the plan and why.
- Never write "tests pass" without the command and the count.
- When something was verified manually, say so and name the steps.

---

## 5. Plan self-audit (run before presenting the plan)

- [ ] Every item is small enough for one commit.
- [ ] Every item has an acceptance check with a command or an observable.
- [ ] Auth, routing, validation, payments, and fallbacks have a negative case.
- [ ] Setup, seed, and migration items have an idempotency check.
- [ ] Every phase ends with a gate that names commands and evidence.
- [ ] Every external dependency is version-pinned; sources that allow it are
      hash-pinned.
- [ ] Every route in `02-sitemap-and-routes.md` appears in Phase 5 and in
      `lib/routes.ts`.
- [ ] Every page in Phase 5 has `page.tsx`, `loading.tsx`, `error.tsx`,
      metadata, and JSON-LD; dynamic routes add `generateStaticParams()`.
- [ ] Every locked decision appears in `project.json` → `decisions`.
- [ ] Every enabled pack has labeled items in its mapped phases and pack-specific
      gate evidence; every disabled pack has a reason and a `revisit_if`.
- [ ] Pack negative cases exist where the pack can fail silently: kill switch
      (OTel), stopped dependency (health), empty/expired session (commerce).
- [ ] Every skipped or deferred scope has a reason and a revisit trigger.
- [ ] Every duplicated fact has a drift check.
- [ ] No item depends on a file that the plan never creates.

If an audit line fails, fix the plan before showing it to the user.

---

## 6. Anti-patterns

| Anti-pattern | Why it fails | Replace with |
| :--- | :--- | :--- |
| "Verify it works" | No executor, no expected value | A command + expected output |
| One giant phase item | Unreviewable, unrevertable | One item per commit |
| "Tests pass" with no output | Unfalsifiable | Command + count + date |
| Happy-path-only criteria | Fails open silently | Add a negative case |
| "Run setup again if needed" | Hides drift | Idempotency check |
| Manual checklist with no evidence | Untraceable | `manual` + recorded steps |
| Duplicated fact, no check | Silent divergence | Drift-check item |
