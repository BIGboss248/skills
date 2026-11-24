# Architecture Contracts Reference (`docs/design/04-architecture-contracts.md`)

Strategy, sitemap, and design tokens describe the *experience*. They do not
describe **who owns a request, who holds the session, or where state lives**.
Those three questions cause the majority of integration defects, so the plan must
answer them in a contract document before pages are built.

Create `docs/design/04-architecture-contracts.md` in Phase 1 and update it when a
phase changes the topology.

---

## 1. Service topology

Two ASCII diagrams — development and production — with every hop named:

```text
Browser → https://<host>
  → Edge proxy (TLS, routers, priorities)
      ├─ priority 100 → backend service (:80)   /admin, /checkout, /graphql
      └─ priority 10  → app service (:3000)     catch-all
```

Rules:

- Every runtime hop has a name, a port, and an owner.
- Name the TLS termination point and the certificate resolver.
- Name what is *not* containerized (host dev server, external SaaS).

---

## 2. Routing ownership matrix

| Path | Owner | Priority | Notes |
| :--- | :--- | :---: | :--- |
| `/`, `/products`, `/_next/*` | app | 10 | catch-all storefront |
| `/api/health` | app | — | container healthcheck |
| `/login`, `/logout` | app | — | redirect-only route handlers |
| `/admin`, `/checkout` | backend | 100 | native forms own these |
| `/graphql` | backend | 100 | API surface |
| `/api/webhooks/*` | app | 110 | must bypass bot protection |

Rules:

- Exactly **one owner per path**. If two routers can match, priorities and path
  prefixes must make the winner unambiguous.
- Bot protection (WAF/CrowdSec) is applied **per router**; callback paths get
  their own higher-priority router that omits it.
- Redirect-only routes are owned by the app but linked with a plain `<a>`, never
  the client router.
- Document the paths that must **not** be proxied to the backend even though they
  look like backend paths.

---

## 3. Auth and session contract

| Concern | Owner | Detail |
| :--- | :--- | :--- |
| Credentials, registration, reset | backend | native account form |
| Session cookie | backend | `<prefix>_<hash>`, HttpOnly, host-only |
| Login state | backend | non-null authenticated principal — never cookie presence |
| Reads in the app | app | forwards a whitelisted cookie subset |
| Logout | backend | server mints the logout URL/nonce |

Invariants (write them as bold one-liners):

- **One hostname.** Host-only cookies break silently across `www.`/apex or a
  subdomain split.
- **Cookie names are hashed.** Match by prefix, never hardcode the full name.
- **Presence is not authentication.** Only a positive principal id counts.
- **One session store.** Never mint a second session next to the provider's.
- **Secrets stay server-side.** No session token in `localStorage`.

Also state the failure mode: what renders when the session is missing, expired, or
rejected — guest card, redirect, or 401 — and whether that is fail-open.

---

## 4. Persistence and migration

| Concern | Development | Production |
| :--- | :--- | :--- |
| Database state | named volume | bind mount (`./data/db`) |
| Uploads | named volume | bind mount (`./data/uploads`) |
| Ownership | container default | `999:999` / `33:33` |
| Backup | dump + archive | dump + archive + manifest |

Rules:

- Never copy a live database directory; stop the service or dump logically.
- Keep the same major version across hosts, or dump/restore.
- Record the **restore command** for every destructive migration step.
- State what is *not* persisted (built assets, caches) so nobody backs it up.

---

## 5. Integrations and pinning

| Integration | Version | Source | Integrity | Activation order |
| :--- | :--- | :--- | :--- | :--- |
| plugin/package A | 1.2.3 | registry | sha256 | 1 |
| plugin/package B | 4.5.6 | git tag | sha256 | 2 |

Rules:

- Every external dependency is pinned; unpinned "latest" is a defect.
- Where the upstream publishes a hash, record it and verify at install/build.
- **Activation order is load-bearing** when add-ons hook each other; state it and
  test it on a clean install, not an existing one.
- Updates are deliberate re-pins in one reviewed commit, never runtime downloads.

---

## 6. Platform and environment constraints

- OS-specific limits (reserved port ranges, path length, line endings).
- Required tool versions (Node, package manager, Docker, shell).
- Files and directories that **must not be touched** (other stacks, shared
  networks, sibling repositories, the user's global config).
- Destructive actions that require an explicit confirmation flag.

---

## 7. Consistency check

Before presenting the plan, confirm:

- [ ] Every route in `02-sitemap-and-routes.md` appears in the ownership matrix.
- [ ] Every path in the ownership matrix appears in a Phase 5/6 item.
- [ ] Every cookie/session claim in the auth table has a verification item.
- [ ] Every pinned integration has a drift-check item.
- [ ] Every "do not touch" resource is named in the plan.
