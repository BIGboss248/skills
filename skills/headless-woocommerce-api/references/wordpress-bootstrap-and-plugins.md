# WordPress Bootstrap & Plugin Reference

Verified against the official `wordpress:latest` image (PHP 8.3) with Docker Desktop, October 2026.

---

## 1. Install WP-CLI

The official image does **not** include WP-CLI. Container `curl` can fail behind corporate proxies or TLS inspection, so download the phar on the host and copy it in:

```powershell
curl.exe -L --retry 3 -o $env:TEMP\wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
docker cp $env:TEMP\wp-cli.phar wordpress:/usr/local/bin/wp
docker exec wordpress chmod +x /usr/local/bin/wp
docker exec -u www-data wordpress wp --info --path=/var/www/html
```

- Run WP-CLI as `www-data`, not root, so files created inside the named volume keep the correct ownership.
- Ignore `Failed to create directory '/var/www/.wp-cli/cache/'`; it is a harmless cache warning.

---

## 2. Core Install

With `WORDPRESS_DB_*` env vars and a reachable MySQL container:

```powershell
docker exec -u www-data wordpress wp core install `
  --url=https://shop.local `
  --title="Headless Store" `
  --admin_user=admin `
  --admin_password="<strong-password>" `
  --admin_email=admin@shop.local `
  --skip-email `
  --path=/var/www/html
```

Then:

```powershell
docker exec -u www-data wordpress wp rewrite structure "/%postname%/" --hard --path=/var/www/html
docker exec -u www-data wordpress wp option get home --path=/var/www/html
```

`wp rewrite ... --hard` may warn about regenerating `.htaccess` because CLI PHP cannot see Apache modules. The image already has `AllowOverride All`; verify `/graphql` returns 200 instead of relying on the warning.

Set `WP_HOME`/`WP_SITEURL` in `WORDPRESS_CONFIG_EXTRA` so they survive option changes.

---

## 3. Plugin Installation Order

| Order | Plugin | Source | Slug |
| :--- | :--- | :--- | :--- |
| 1 | WooCommerce | WP.org | `woocommerce` |
| 2 | WPGraphQL | WP.org | `wp-graphql` |
| 3 | WooGraphQL | GitHub release | `wp-graphql-woocommerce` |
| 4 | WPGraphQL JWT Auth | GitHub release | `wp-graphql-jwt-authentication` |
| 5 | Persian WooCommerce (optional) | WP.org | `persian-woocommerce` |
| 6 | ZarinPal (optional) | WP.org | `zarinpal-woocommerce-payment-gateway` |

```powershell
docker exec -u www-data wordpress wp plugin install woocommerce --activate --path=/var/www/html
docker exec -u www-data wordpress wp plugin install wp-graphql --activate --path=/var/www/html
```

GitHub releases:

```powershell
curl.exe -L --retry 3 -o $env:TEMP\wpgql-woo.zip https://github.com/wp-graphql/wp-graphql-woocommerce/releases/latest/download/wp-graphql-woocommerce.zip
docker cp $env:TEMP\wpgql-woo.zip wordpress:/tmp/wpgql-woo.zip
docker exec -u www-data wordpress wp plugin install /tmp/wpgql-woo.zip --activate --path=/var/www/html
```

Repeat for `https://github.com/wp-graphql/wp-graphql-jwt-authentication/releases/latest/download/wp-graphql-jwt-authentication.zip`.

- Install Persian WooCommerce only **after** patching `pdo_mysql`.
- Verify activation after the next frontend request; a plugin that fatals is auto-deactivated. `wp plugin list --fields=name,status,version` is the source of truth.
- Flush rewrites after activation: `wp rewrite flush --hard`.

---

## 4. JWT Secret

The image only auto-defines `WORDPRESS_*` constants. Define the JWT secret through `WORDPRESS_CONFIG_EXTRA`:

```yaml
environment:
  WORDPRESS_CONFIG_EXTRA: >-
    define('GRAPHQL_JWT_AUTH_SECRET_KEY', '${GRAPHQL_JWT_AUTH_SECRET_KEY}');
```

`wp-config-docker.php` evaluates this at runtime, so a container restart applies changes without regenerating the file.

Generate with at least 64 characters from a URL/PHP-safe alphabet (avoid `$`, quotes, backslashes):

```powershell
$chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_%+=@!'
-join (1..64 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
```

---

## 5. Known-Good Version Matrix (2026-10-27)

| Component | Version |
| :--- | :--- |
| WordPress | 6.x (`wordpress:latest`, PHP 8.3.36) |
| WooCommerce | 11.2.1 |
| WPGraphQL | 2.25.0 |
| WooGraphQL | 1.0.3 |
| WPGraphQL JWT Authentication | 0.7.x |
| Persian WooCommerce | 10.0.7 |
| ZarinPal for WooCommerce | 5.1.1 |
| MySQL | 8.0 |

Compatibility notes:

- WooGraphQL releases lag WooCommerce; if the schema fails to load after a WooCommerce major update, pin WooCommerce to the last supported major.
- `wp-graphql-jwt-authentication` 0.7.x works with WPGraphQL 2.x; verify the login mutation after upgrades.
- Persian WooCommerce requires `pdo_mysql` and PHP 8.x.

---

## 6. Schema Verification

```graphql
{
  __schema {
    types {
      name
    }
  }
}
```

Confirm `Product`, `SimpleProduct`, `VariableProduct`, `Cart`, `CartItem`, `Customer`, `Order` exist. Then query products with polymorphic fragments; a direct `price` on `Product` is a schema error, not an empty result.

```powershell
docker exec -u www-data wordpress wp plugin list --fields=name,status,version --path=/var/www/html
docker exec -u www-data wordpress wp eval "echo home_url() . '|' . site_url() . '|' . get_option('permalink_structure');" --path=/var/www/html
```
