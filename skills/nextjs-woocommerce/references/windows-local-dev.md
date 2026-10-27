# Windows / Docker Local Development Reference

Verified on Windows 11 + Docker Desktop (WSL2 backend), October 2026. Adapt paths and domain names to the project.

---

## 1. Preflight

```powershell
docker version
docker network inspect my_network
Get-NetTCPConnection -State Listen -LocalPort 80,443,3000,3001,4000 -ErrorAction SilentlyContinue
```

- Create the shared network once: `docker network create my_network`.
- Check whether WSL is healthy before relying on `make` or bash scripts: `wsl --status`. A broken `ext4.vhdx` makes WSL-based setup unusable; use PowerShell + `docker compose` instead.
- Hosts edits require an elevated shell.

---

## 2. Port Selection (Windows Excluded Ranges)

Hyper-V / WinNAT reserves TCP ranges. Binding `0.0.0.0:3000` can fail with `EACCES` even when nothing is listening.

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
```

Typical reserved range: **2929–3028**, which blocks 3000 and 3001. Choose a free port such as **4000**, then update all four places together:

| File | Change |
| :--- | :--- |
| `package.json` | `"dev": "next dev -p 4000"` |
| `playwright.config.ts` | `const PORT = process.env.PORT || 4000;` |
| `next.config.ts` | add `localhost:4000` and `127.0.0.1:4000` to `serverActions.allowedOrigins` |
| `docker-compose.dev.yml` | `caddy reverse-proxy --from :80 --to host.docker.internal:4000` |

Do not start the dev server with `pnpm dev -- -p 4000`; pnpm passes the literal `--` to Next.js. Use a script flag or `pnpm exec next dev -p 4000`.

---

## 3. Local Edge: Traefik Without ACME

Let's Encrypt cannot issue certificates for `.local`. Run Traefik with `tls=true` and **no cert resolver**; Traefik serves its built-in self-signed certificate.

`dev/traefik/traefik.yml`:

```yaml
log:
  level: INFO

api:
  dashboard: false

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: my_network
```

`dev/traefik/docker-compose.yml`:

```yaml
services:
  traefik:
    image: traefik:v3
    container_name: project-traefik
    restart: unless-stopped
    command:
      - "--configFile=/etc/traefik/traefik.yml"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/etc/traefik/traefik.yml:ro
    networks:
      - my_network

networks:
  my_network:
    external: true
```

### Dev override for production compose labels

Production routers carry `tls.certresolver=myresolver`. Locally there is no resolver, so remove that label. Compose `!override` (v2.24+) replaces the whole list; otherwise duplicate the label list without the resolver.

```yaml
services:
  wordpress:
    labels: !override
      - "traefik.enable=true"
      - "traefik.docker.network=my_network"
      - "traefik.http.routers.wordpress-secure.entrypoints=websecure"
      - "traefik.http.routers.wordpress-secure.rule=Host(`shop.local`) && (PathPrefix(`/checkout`) || PathPrefix(`/my-account`) || PathPrefix(`/wp-admin`) || PathPrefix(`/wp-login.php`) || PathPrefix(`/wp-content`) || PathPrefix(`/wp-includes`) || PathPrefix(`/wp-json`) || PathPrefix(`/graphql`) || QueryRegexp(`wc-ajax`, `.+`) || QueryRegexp(`wc-api`, `.+`))"
      - "traefik.http.routers.wordpress-secure.priority=100"
      - "traefik.http.routers.wordpress-secure.tls=true"
      - "traefik.http.routers.wordpress-secure.service=wordpress-service"
      - "traefik.http.services.wordpress-service.loadbalancer.server.port=80"
```

Note the WordPress rule does **not** include `PathPrefix('/wc-api')`; Next.js middleware owns legacy callback URLs.

### Next.js dev proxy

`docker-compose.dev.yml` runs Caddy on `my_network`, forwarding to the host dev server. It also carries the Next.js Traefik labels (priority `10`, `tls=true`, no resolver).

```yaml
services:
  nextjs-dev-proxy:
    image: caddy:alpine
    container_name: nextjs-dev-proxy
    restart: unless-stopped
    command: caddy reverse-proxy --from :80 --to host.docker.internal:4000
    extra_hosts:
      - "host.docker.internal:host-gateway"
    networks:
      - my_network
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=my_network"
      - "traefik.http.routers.nextjs-secure.entrypoints=websecure"
      - "traefik.http.routers.nextjs-secure.rule=Host(`shop.local`)"
      - "traefik.http.routers.nextjs-secure.priority=10"
      - "traefik.http.routers.nextjs-secure.tls=true"
      - "traefik.http.routers.nextjs-secure.service=nextjs-service"
      - "traefik.http.services.nextjs-service.loadbalancer.server.port=80"

networks:
  my_network:
    external: true
```

Start order:

```powershell
docker compose -f dev/traefik/docker-compose.yml up -d
docker compose -f prod/WordPress/docker-compose.yml -f prod/WordPress/docker-compose.local.yml up -d
docker compose -f docker-compose.dev.yml up -d
pnpm dev
```

---

## 4. WordPress Stack on Windows

- Keep WordPress core and MySQL in **named volumes** (`wp_core`, `wp_db_data`) to avoid 15–45s NTFS round trips.
- Bind-mount only active code folders (`mu-plugins`) and `uploads.ini`.
- Never mount a named volume onto a file path; bind the `uploads.ini` file instead.
- Healthcheck `http://localhost:80/wp-includes/version.php` avoids boot-time false negatives.

### `WORDPRESS_CONFIG_EXTRA`

The official image's `wp-config-docker.php` evaluates `WORDPRESS_CONFIG_EXTRA` at runtime:

```php
if ($configExtra = getenv_docker('WORDPRESS_CONFIG_EXTRA', '')) {
    eval($configExtra);
}
```

That means constant changes take effect on a container restart/recreate without regenerating `wp-config.php`. Define the JWT secret here, because the image does not auto-define arbitrary env vars:

```yaml
environment:
  WORDPRESS_CONFIG_EXTRA: >-
    define('WP_HOME', 'https://shop.local');
    define('WP_SITEURL', 'https://shop.local');
    define('WP_ENVIRONMENT_TYPE', 'local');
    define('DISABLE_WP_CRON', true);
    define('WP_POST_REVISIONS', false);
    define('FS_METHOD', 'direct');
    define('FORCE_SSL_ADMIN', true);
    define('GRAPHQL_JWT_AUTH_SECRET_KEY', '${GRAPHQL_JWT_AUTH_SECRET_KEY}');
```

Use a secret without `$`, quotes, or backslashes: it is interpolated into a PHP single-quoted string by Compose.

---

## 5. Container-Layer Patches (`pdo_mysql`, WP-CLI)

`docker-php-ext-install` and `/usr/local/bin/wp` live in the container's writable layer, not the named volume. Recreating the container removes them. Persian WooCommerce then throws `could not find driver` and `/wp-admin/` returns HTTP 500.

Run `patch-wordpress.ps1` after every `docker compose up`, `down`, or image update:

```powershell
pwsh ./prod/WordPress/patch-wordpress.ps1
```

See [patch-wordpress.ps1](../../headless-woocommerce-api/examples/patch-wordpress.ps1) for a standalone template.

Verify:

```powershell
docker exec wordpress php -m | Select-String pdo_mysql
docker exec -u www-data wordpress wp --info
```

Run WP-CLI as `www-data`, not root, so files inside the volume keep the correct ownership.

---

## 6. Hosts and Certificates

Elevated PowerShell (one-time):

```powershell
$hosts = 'C:\Windows\System32\drivers\etc\hosts'
Add-Content -Path $hosts -Value "`r`n127.0.0.1 shop.local`r`n::1 shop.local"
```

Verify:

```powershell
Resolve-DnsName shop.local
```

Self-signed certificates trigger a browser warning; accept it once per browser profile. Node.js fetch calls need `NODE_TLS_REJECT_UNAUTHORIZED=0` in development and during local builds. Never set it in production.

For a warning-free local certificate, use mkcert and mount the generated certificate into Traefik as the default certificate.

---

## 7. Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `EACCES: permission denied 0.0.0.0:3000` | Port inside a Windows excluded range | Use 4000 and update proxy/config |
| `/wp-admin/` HTTP 500 after login | Missing `pdo_mysql` (container recreated) | Run `patch-wordpress.ps1` |
| `/.well-known/acme-challenge` timeouts for `shop.local` | ACME cannot validate `.local` | Remove `certresolver`, use `tls=true` |
| `502` from Caddy | Next.js not running or wrong port | Start `pnpm dev`, check the Caddy target |
| Traefik `404 page not found` | Router rule/host mismatch | Check labels and `Host()` value |
| `docker compose` warns `network exists but was not created by compose` | Network was pre-created | Harmless; or mark it `external: true` |
| `tail /var/log/apache2/error.log` hangs | Log is symlinked to stderr | Use `docker logs <container>` |
| `could not find driver` only in admin | `pdo_mysql` missing in the web SAPI | Rebuild extension and `apache2ctl graceful` |
