<?php
/**
 * Local WordPress/WooCommerce configuration template.
 *
 * Run with:
 *   docker cp wp-configure.php wordpress:/tmp/wp-configure.php
 *   docker exec -u www-data wordpress wp eval-file /tmp/wp-configure.php --path=/var/www/html
 *
 * Adjust values for the project. Do not put credentials in this file.
 */

if (!defined('ABSPATH')) {
    fwrite(STDERR, "ABSPATH not defined\n");
    exit(1);
}

$options = [
    'blog_public'                                => 0,
    'timezone_string'                            => 'Asia/Tehran',
    'users_can_register'                         => 1,
    'default_role'                               => 'customer',
    'woocommerce_enable_myaccount_registration'  => 'yes',
    'woocommerce_registration_generate_password' => 'no',
    'woocommerce_registration_generate_username' => 'no',
    'woocommerce_currency'                       => 'IRT', // Requires Persian WooCommerce
    'woocommerce_default_country'                => 'IR:THR',
    'woocommerce_price_num_decimals'             => 0,
    'woocommerce_currency_pos'                   => 'right_space',
    'woocommerce_calc_taxes'                     => 'no',
    'woocommerce_enable_guest_checkout'          => 'yes',
    'woocommerce_enable_checkout_login_reminder' => 'yes',
    'woocommerce_allowed_countries'              => 'specific',
    'woocommerce_specific_allowed_countries'     => ['IR'],
    'woocommerce_ship_to_countries'              => '',
    'woocommerce_coming_soon'                    => 'no',
    'woocommerce_allow_tracking'                 => 'no',
    'woocommerce_store_city'                     => 'Tehran',
    'woocommerce_email_from_name'                => 'Headless Store',
    'woocommerce_email_from_address'             => 'shop@shop.local',
];

foreach ($options as $key => $value) {
    update_option($key, $value);
}

// Pretty permalinks are required for /graphql and gateway callbacks.
update_option('permalink_structure', '/%postname%/');
global $wp_rewrite;
$wp_rewrite->set_permalink_structure('/%postname%/');
$wp_rewrite->flush_rules(true);

// The official Apache image uses AllowOverride All; write the standard rules.
$htaccess = ABSPATH . '.htaccess';
$rules = <<<'HTACCESS'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress

HTACCESS;
file_put_contents($htaccess, $rules);

echo "configured\n";
echo 'currency=' . get_option('woocommerce_currency') . "\n";
echo 'country=' . get_option('woocommerce_default_country') . "\n";
echo 'registration=' . get_option('users_can_register') . "\n";
echo 'permalink=' . get_option('permalink_structure') . "\n";
