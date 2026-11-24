# F5 — Production Docker

## Enable when

The project ships as a container. Skip for libraries or host-only deployments.

## Questions

1. App image only, or app + compose stack?
2. HTTP port the app listens on.
3. Runtime user: dedicated non-root user (recommended) or image default?
4. Does the platform need a writable cache directory at runtime?

## Steps

1. Create `.dockerignore` covering `node_modules/`, `.env*`, `.git/`, build
   output, tests, reports, and `.codebase-memory/`.
2. Deploy [Dockerfile.template](../../resources/templates/Dockerfile.template)
   with dependency, build, and runtime stages; add `STOPSIGNAL SIGTERM`.
3. If compose was selected, deploy
   [docker-compose.yml.template](../../resources/templates/docker-compose.yml.template)
   and/or
   [docker-compose.prod.yml.template](../../resources/templates/docker-compose.prod.yml.template).
4. Build: `docker build -f Dockerfile -t <name>:local .`.
5. Run it and probe the documented health endpoint (or `/`) for HTTP 200.
6. Confirm the process user with `docker exec <container> id`.

## Acceptance

- [ ] `docker build` succeeds from a clean context.
- [ ] The container answers its health probe.
- [ ] The process runs as the intended (non-root) user.
- [ ] `docker compose config` is valid when compose was selected.

## Notes

- Standalone builds need the lockfile copied before the install layer.
- Never bake secrets into build args; pass runtime values through the environment.
- Details: [docker-and-cicd-guide.md](../docker-and-cicd-guide.md).
