# N11 — Docker & Reverse Proxy

**Category:** Delivery & Operations · **Default:** off · **Depends on:** N2

## Enable when

The app ships as a container or runs behind Traefik / Nginx in production. Skip
for static exports, Vercel deployments, and host-only development.

## Questions

1. **Packaging** — image only, or image + compose stack?
2. **Reverse proxy** — Traefik via Compose labels, Nginx on the host, or none
   (direct port)?
3. **Networking** — production domain, container name, and internal port?
4. **Runtime** — dedicated non-root user (recommended) or the image default?
5. **Server Actions** — allowed origins (`example.com`, `*.example.com`,
   `localhost:3000`)?
6. **Secrets** — where does `NEXT_SERVER_ACTIONS_ENCRYPTION_KEY` come from in
   production?

## Steps

1. In `next.config.*`, preserve every key owned by N4/N6/N8 and add: Git commit
   hash and package version under `env`, `output: "standalone"`, `deploymentId`,
   anti-buffering headers (`X-Accel-Buffering: no`), and
   `experimental.serverActions.allowedOrigins`.
2. Document `NEXT_SERVER_ACTIONS_ENCRYPTION_KEY` in `.env.example` and pass it to
   the runtime environment; never bake it into the image.
3. Deploy [Dockerfile.template](../../resources/templates/Dockerfile.template)
   (with `STOPSIGNAL SIGTERM`) and
   [docker-compose.yml.template](../../resources/templates/docker-compose.yml.template)
   (with `stop_grace_period: 30s`) when compose was selected.
4. **Traefik**: deploy
   [docker-compose.prod.yml.template](../../resources/templates/docker-compose.prod.yml.template)
   with labels reading `${DOMAIN_NAME}`, `${TRAEFIK_ENTRYPOINT}`, and
   `${TRAEFIK_CERTRESOLVER}`.
   **Nginx**: deploy or output
   [nginx-site.conf.template](../../resources/templates/nginx-site.conf.template)
   to `/etc/nginx/sites-available/<domain>` with Certbot certificates.
5. Deploy [dockerignore.template](../../resources/templates/dockerignore.template)
   to `.dockerignore`.
6. Build and probe: `docker build -f Dockerfile -t <name>:local .`, then request
   `/` and confirm HTTP 200 and a non-root process user.

## Acceptance

- [ ] `next.config.*` keeps all prior keys and adds the standalone settings.
- [ ] `docker build` succeeds from a clean context and the container answers.
- [ ] `docker compose config` is valid when compose was selected.
- [ ] The process runs as the intended non-root user.
- [ ] Nginx configuration passes `nginx -t`; Traefik labels reference the three
      environment variables.
- [ ] No secret is baked into a build argument or the image.

## Notes

- Multi-container deployments can drift caches; pin `deploymentId` consistently.
- Docker image names must be lowercase (`IMAGE_NAME=$(echo ... | tr '[:upper:]' '[:lower:]')`).
- Details: [docker-containerization-guide.md](../docker-containerization-guide.md).
