---
name: seo-ops
description: >-
  Run SEO audits and gates with the seo CLI. Use when auditing a page or site,
  wiring a pre-push or CI SEO check, or reviewing Search Console opportunities.
---

# SEO Operations

How SEO evidence is gathered and enforced. This skill runs audits and gates only.

## Pre-flight

- Verify the `seo` CLI and MCP server are available in this session.
- If missing: `npm install -g seo`, register the server (MCP configuration is
  owned by `ag-customizer`), verify with `npx -y seo mcp serve --test`, then ask
  for a session reload.
- Do not inspect code statically or guess findings without an active tool. If the
  tool cannot be enabled, say so and stop.
- Reference: [MCP setup and tools](./references/mcp-setup-guide.md).

## Pathway A — CI and pre-push gate

- Node 22+.
- Deploy `scripts/seo-pre-push.ps1` / `.sh`, with dev-server probing and process
  cleanup.
- `.husky/pre-push` runs the test suite first, then the SEO gate, as separate
  commands.
- GitHub Actions workflow: [seo-ci template](./resources/templates/seo-ci.yml.template).
- Validate with `./scripts/verify-seo-setup.ps1 -Mode cicd` (or
  `./scripts/verify-seo-setup.sh -m cicd`).
- Guide: [CI/CD pipeline](./references/cicd-pipeline-guide.md).

## Pathway B — Technical and on-page audit

- Run against a production build (`build` then `start`), not the dev server.
- MCP: `seo_run_report` with `audit-page` or `site-crawl` and the target URL.
- CLI: `npx -y seo report --url <url> --actions-only --json`.
- Remediate in this order: metadata and canonical, JSON-LD, broken internal
  links, sitemap.
- Re-run until the report has zero findings; a fix is unverified until then.
- Guide: [ranking and remediation](./references/ranking-optimization-guide.md).

## Pathway C — Search Console opportunities

- Discover reports with `seo_list_reports` (`gsc`, `pseo`), then describe them
  with `seo_describe_report`.
- Run with the target property (`site: "sc-domain:example.com"`).
- Quick wins (positions 4–10): rewrite title and description for CTR.
- Second page (positions 10–20): add contextual internal links and deepen the
  page.
- pSEO patterns: scaffold dynamic routes with `generateStaticParams()`.
- Re-verify in a production SSR build.

## Definition of Done

- [ ] The tool was active; no finding was produced by static reading.
- [ ] The target was a production build for audits.
- [ ] Every finding maps to a changed file or a recorded decision.
- [ ] The audit was re-run and is clean, or residual findings are listed.
- [ ] Gate commands are separate and the pre-push gate exits non-zero on
      findings.
- [ ] Observed crawl evidence is kept separate from provider estimates.

## Edge Cases & Pitfalls

- **Unreloaded MCP** — tools added in-session are not callable until the window
  reloads.
- **Windows path lookup** — use `"command": "npx"` with
  `["-y", "seo", "mcp", "serve"]`, not a bare binary.
- **Dev-server audits** — hydration and dev overlays distort results.
- **Evidence mixing** — crawl observations and keyword estimates are different
  claims.
- **Remediation without re-run** — a change is not a fix.
- **Gate as a soft check** — a gate that always exits 0 is documentation, not a
  gate.

## References

- [MCP setup and tools](./references/mcp-setup-guide.md)
- [CI/CD and pre-push pipeline](./references/cicd-pipeline-guide.md)
- [Ranking and code remediation](./references/ranking-optimization-guide.md)
- [CI workflow template](./resources/templates/seo-ci.yml.template)
- [MCP config template](./resources/templates/mcp_config.template.json)
