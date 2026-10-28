# Store Configuration & Seeding (Iranian / Persian Stack)

Verified with WooCommerce 11.2.1, Persian WooCommerce 10.0.7, and ZarinPal for WooCommerce 5.1.1 (October 2026).

---

## 1. Registration & Accounts

```powershell
docker exec -u www-data wordpress wp option update users_can_register 1 --path=/var/www/html
docker exec -u www-data wordpress wp option update default_role customer --path=/var/www/html
docker exec -u www-data wordpress wp option update woocommerce_enable_myaccount_registration yes --path=/var/www/html
docker exec -u www-data wordpress wp option update woocommerce_registration_generate_password no --path=/var/www/html
docker exec -u www-data wordpress wp option update woocommerce_registration_generate_username no --path=/var/www/html
```

Leave "automatically generate an account password" **off**; otherwise the password submitted by the storefront is replaced by an emailed random string.

Verify a customer:

```powershell
docker exec -u www-data wordpress wp user list --fields=ID,user_login,user_email,roles --path=/var/www/html
```

---

## 2. Currency, Locale, and Selling Rules

`IRT` (Toman) is registered by Persian WooCommerce. Install/activate it first, then:

```powershell
docker exec -u www-data wordpress wp option update woocommerce_currency IRT --path=/var/www/html
docker exec -u www-data wordpress wp option update woocommerce_default_country IR:THR --path=/var/www/html
docker exec -u www-data wordpress wp option update woocommerce_price_num_decimals 0 --path=/var/www/html
docker exec -u www-data wordpress wp option update timezone_string Asia/Tehran --path=/var/www/html
docker exec -u www-data wordpress wp option update woocommerce_allowed_countries specific --path=/var/www/html
```

`woocommerce_specific_allowed_countries` is an array; set it with `wp eval` or the WooCommerce settings UI.

Confirm:

```powershell
docker exec -u www-data wordpress wp eval "echo get_option('woocommerce_currency') . '|' . get_woocommerce_currency_symbol('IRT');" --path=/var/www/html
```

---

## 3. `pdo_mysql` Before Persian WooCommerce

The official image ships `mysqli`/`mysqlnd` but not `pdo_mysql`. Persian WooCommerce uses Illuminate/PDO and crashes on `admin_init` without it:

```
Uncaught Illuminate\Database\QueryException: could not find driver
```

Patch after **every** container creation/recreation:

```powershell
docker exec -u 0 wordpress docker-php-ext-install pdo_mysql
docker exec wordpress apache2ctl graceful
docker exec wordpress php -m | Select-String pdo_mysql
```

See [patch-wordpress.ps1](../examples/patch-wordpress.ps1).

---

## 4. Payment Gateways

### COD (offline fallback)

```powershell
docker exec -u www-data wordpress wp wc payment_gateway update cod --enabled=true --user=1 --path=/var/www/html
```

`/usr/sbin/sendmail: not found` is harmless in local Docker.

### Zibal vs ZarinPal

- Persian WooCommerce bundles **Zibal** (`wc_zibal`), not ZarinPal.
- ZarinPal requires the separate `zarinpal-woocommerce-payment-gateway` plugin. Install and activate it, then discover the gateway id:

```powershell
docker exec -u www-data wordpress wp eval '$gws = WC()->payment_gateways()->payment_gateways(); foreach ($gws as $id => $g) { echo $id . "|" . $g->get_title() . "|" . $g->enabled . "\n"; }' --path=/var/www/html
```

Expect `WC_ZPal`. Persist defaults before patching settings:

```powershell
docker exec -u www-data wordpress wp wc payment_gateway update WC_ZPal --enabled=true --user=1 --path=/var/www/html
docker exec -u www-data wordpress wp option patch update woocommerce_WC_ZPal_settings sandbox yes --path=/var/www/html
```

`wp option patch update` fails with `No data exists for key` until the gateway settings option exists.

#### Activating the ZarinPal sandbox with a random UUID (no merchant contract)

Sandbox mode never validates the merchant ID — the plugin calls the ZarinPal **sandbox** endpoint, so any UUID-shaped `merchantcode` is accepted. Toggle sandbox and plant a generated UUID in one atomic write:

```powershell
docker exec -u www-data wordpress wp eval '
$s = get_option("woocommerce_WC_ZPal_settings", []);
$s["enabled"]      = "yes";
$s["sandbox"]      = "yes";
$s["merchantcode"] = wp_generate_uuid4();
update_option("woocommerce_WC_ZPal_settings", $s);
printf("%s|%s|%s\n", $s["enabled"], $s["sandbox"], $s["merchantcode"]);
' --path=/var/www/html
```

- `wp_generate_uuid4()` returns a canonical 36-character UUID; a literal `00000000-0000-0000-0000-000000000000` works just as well.
- Re-running the command rotates the value (the DB volume keeps it, but each run writes a new UUID). Use a fixed UUID literal when you want a stable, documented ID.
- Run the `wp wc payment_gateway update WC_ZPal` call first so the option exists; the `wp eval` above also creates it when missing, but the gateway must still be enabled for it to render at `/checkout/`.

With `sandbox=yes` + UUID `merchantcode`, a sandbox order is created, redirects to the ZarinPal sandbox page, and returns through `/checkout/?wc-api=WC_ZPal`, which exercises the whole native checkout bridge without a live terminal. Live Mode (and a real merchant ID from the ZarinPal dashboard) is only needed for real money.

### Dormant gateways

Iranian PSPs remain dormant (راکد) until the terminal is activated and switched to Live Mode. Use sandbox mode or COD for local checkout verification.

---

## 5. Shipping Zone (PHP, not `wp wc`)

`wp wc shipping_zone update` does not accept `--locations`. Use the WooCommerce API:

```php
<?php
$zone = new WC_Shipping_Zone(1); // 1 = zone created with wp wc shipping_zone create
$zone->set_zone_name('Iran');
$zone->set_locations([
    ['code' => 'IR', 'type' => 'country'],
]);
$zone->save();

$methods = $zone->get_shipping_methods();
$instance = 0;
foreach ($methods as $method) {
    if ($method->id === 'flat_rate') {
        $instance = (int) $method->instance_id;
    }
}
if ($instance === 0) {
    $instance = (int) $zone->add_shipping_method('flat_rate');
}

$key = 'woocommerce_flat_rate_' . $instance . '_settings';
$settings = get_option($key, []);
$settings['title'] = 'ارسال با پست';
$settings['cost'] = '50000';
update_option($key, $settings);
```

Run with `wp eval-file /tmp/wp-shipping.php`. See [wp-seed-products.php](../examples/wp-seed-products.php) for the same pattern applied to products.

---

## 6. Seeding Products

Keep seed scripts **outside** the repository (temporary directory) and run them with `wp eval-file`.

- Create categories with `wp_insert_term($name, 'product_cat')`.
- Create simple products with `WC_Product_Simple`.
- Create a variable product with a local attribute, then variations:

```php
$attribute = new WC_Product_Attribute();
$attribute->set_id(0);
$attribute->set_name('Size');
$attribute->set_options(['S', 'M']);
$attribute->set_visible(true);
$attribute->set_variation(true);
$variable->set_attributes([$attribute]);
$parent_id = (int) $variable->save();

$variation = new WC_Product_Variation();
$variation->set_parent_id($parent_id);
$variation->set_regular_price('450000');
$variation->set_attributes(['size' => 'S']);
$variation->save();

WC_Product_Variable::sync($parent_id);
```

Verify with GraphQL: `... on VariableProduct { variations { nodes { databaseId name price } } }`.

Prices are display-formatted strings and may contain `&nbsp;` plus the currency symbol; decode before rendering.

---

## 7. Quick Verification

```powershell
docker exec -u www-data wordpress wp option get woocommerce_currency --path=/var/www/html
docker exec -u www-data wordpress wp plugin list --fields=name,status --format=csv --path=/var/www/html
docker exec -u www-data wordpress wp eval '$z = get_option("woocommerce_WC_ZPal_settings"); echo ($z["sandbox"] ?? "unset") . "|" . ($z["enabled"] ?? "unset") . "\n";' --path=/var/www/html
```
