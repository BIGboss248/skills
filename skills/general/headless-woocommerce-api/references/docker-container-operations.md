# Docker Container Operations

Operational notes for running WordPress + MySQL in Docker on Windows/macOS/Linux, derived from a verified Windows 11 + Docker Desktop setup.

---

## 1. Volume Layout

```yaml
services:
  wordpress:
    image: wordpress:latest
    volumes:
      - wp_core:/var/www/html
      - ./mu-plugins:/var/www/html/wp-content/mu-plugins
      - ./uploads.ini:/usr/local/etc/php/conf.d/uploads.ini:ro
  wordpress_db:
    image: mysql:8.0
    volumes:
      - wp_db_data:/var/lib/mysql

volumes:
  wp_core:
  wp_db_data:
```

- Named volumes for core and MySQL avoid the 9P/virtiofs penalty on Windows.
- Bind only code you edit (`mu-plugins`, custom plugins, themes).
- **Never mount a named volume onto a file path.** `- WP_uploads:/usr/local/etc/php/conf.d/uploads.ini` silently shadows the file. Bind `./uploads.ini` instead.
- If you need the WordPress files on the host, use a bind mount or copy them out; named volumes are opaque.

---

## 2. `WORDPRESS_CONFIG_EXTRA` Is Runtime, Not Bootstrap-Only

The official image generates `wp-config-docker.php` with:

```php
if ($configExtra = getenv_docker('WORDPRESS_CONFIG_EXTRA', '')) {
    eval($configExtra);
}
```

Consequences:

- Constant changes apply after a container **restart/recreate**, not only on the first boot.
- The image does **not** auto-define arbitrary env vars. Anything beyond `WORDPRESS_*` (e.g. `GRAPHQL_JWT_AUTH_SECRET_KEY`) must be defined here.
- Use a secret without `$`, quotes, or backslashes: it is interpolated into a PHP single-quoted string by Compose.
- Prefer `docker compose up -d` (recreate) over `restart` when the env mapping changes.

Recommended local constants:

```php
define('WP_HOME', 'https://shop.local');
define('WP_SITEURL', 'https://shop.local');
define('WP_ENVIRONMENT_TYPE', 'local');
define('DISABLE_WP_CRON', true);
define('WP_POST_REVISIONS', false);
define('FS_METHOD', 'direct');
define('FORCE_SSL_ADMIN', true);
define('GRAPHQL_JWT_AUTH_SECRET_KEY', '...');
```

---

## 3. Container-Layer Patches Are Lost on Recreation

`docker-php-ext-install pdo_mysql` writes to `/usr/local/lib/php/extensions/...` and WP-CLI lives at `/usr/local/bin/wp`. Both are in the container's writable layer, **not** the named volume.

Symptom:

```
Uncaught Illuminate\Database\QueryException: could not find driver
```

on `/wp-admin/` after a `docker compose down/up` or a compose label change.

Fix after every creation:

```powershell
pwsh ./patch-wordpress.ps1
```

The script installs `pdo_mysql` if missing, reloads Apache, installs WP-CLI if missing, and prints the loaded module.

Do **not** solve this with a custom image if the project convention is "standard `wordpress:latest` + post-deploy patch"; the patch script is the supported path.

---

## 4. Logs and Debugging

- PHP fatals go to the container's stderr: `docker logs --since 10m wordpress`.
- **Do not** `tail /var/log/apache2/error.log`. In the official image it is symlinked to stderr and `tail` hangs. Use `docker logs`.
- Access logs show routing evidence:
  - `GET /graphql ... 200` proves Traefik reached WordPress.
  - `GET /wp-includes/version.php ... 200` is the healthcheck.
- If a plugin causes a fatal on activation, WordPress auto-deactivates it. Re-activate after fixing and verify `wp plugin list`.
- `AH00558: Could not reliably determine the server's fully qualified domain name` is cosmetic.

---

## 5. Healthchecks

```yaml
healthcheck:
  test: ["CMD", "curl", "--fail", "http://localhost:80/wp-includes/version.php"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 30s
```

Testing `/` can time out during first boot and cause Traefik to evict the backend. `version.php` is a static file and responds immediately.

MySQL:

```yaml
healthcheck:
  test: ["CMD-SHELL", "mysqladmin ping -h localhost -u root -p$${MYSQL_ROOT_PASSWORD} || exit 1"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
```

Use `depends_on: wordpress_db: condition: service_healthy`.

---

## 6. WP-CLI Permissions

```powershell
docker exec -u www-data wordpress wp plugin list --path=/var/www/html
```

- Run as `www-data`, not root, to avoid root-owned files in the volume.
- If the phar is missing after recreation, reinstall it (see [wordpress-bootstrap-and-plugins.md](./wordpress-bootstrap-and-plugins.md)).
- `Failed to create directory '/var/www/.wp-cli/cache/'` is harmless; WP-CLI continues without the cache.

---

## 7. Reset and Backup

```powershell
# Stop without deleting data
docker compose down

# Destructive reset (drops WordPress + MySQL volumes)
docker compose down -v

# Backup the database
docker exec wordpress_db sh -c 'exec mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' > backup.sql
```

After a reset, re-run core install, plugin activation, store configuration, and the patch script.

---

## 8. Network Notes

- Compose may warn: `a network with name my_network exists but was not created by compose`. This is harmless when the network was pre-created; add `external: true` to silence it.
- Traefik needs the Docker socket and `--providers.docker.exposedByDefault=false`.
- On Windows, ports 80/443 may be held by another proxy. Check `Get-NetTCPConnection -State Listen -LocalPort 80,443`.
- Keep MySQL off the host network; expose it only to the Compose network.
