<?php
/**
 * Seed a small catalog for local development.
 *
 * Run with:
 *   docker cp wp-seed-products.php wordpress:/tmp/wp-seed-products.php
 *   docker exec -u www-data wordpress wp eval-file /tmp/wp-seed-products.php --path=/var/www/html
 *
 * Keep seed files outside the repository. Adjust names/prices for the project.
 */

if (!defined('ABSPATH')) {
    exit(1);
}

function seed_category(string $name, string $slug): int
{
    $term = term_exists($slug, 'product_cat');
    if ($term) {
        return (int) (is_array($term) ? $term['term_id'] : $term);
    }

    $created = wp_insert_term($name, 'product_cat', ['slug' => $slug]);
    if (is_wp_error($created)) {
        fwrite(STDERR, 'category error: ' . $created->get_error_message() . "\n");
        return 0;
    }

    return (int) $created['term_id'];
}

function seed_simple(string $name, string $slug, string $price, int $categoryId, string $description): int
{
    $product = new WC_Product_Simple();
    $product->set_name($name);
    $product->set_slug($slug);
    $product->set_status('publish');
    $product->set_catalog_visibility('visible');
    $product->set_description($description);
    $product->set_short_description($description);
    $product->set_regular_price($price);
    $product->set_price($price);
    $product->set_manage_stock(false);
    $product->set_stock_status('instock');
    $product->set_sku('seed-' . $slug);
    $product->set_category_ids([$categoryId]);

    return (int) $product->save();
}

$electronics = seed_category('Electronics', 'electronics');
$home = seed_category('Home', 'home');
$apparel = seed_category('Apparel', 'apparel');

$simple = [
    ['Sample Headphones', 'sample-headphones', '2450000', $electronics, 'Over-ear wireless headphones.'],
    ['Sample Keyboard', 'sample-keyboard', '3200000', $electronics, 'Hot-swappable mechanical keyboard.'],
    ['Sample Mug', 'sample-mug', '320000', $home, 'Ceramic mug, 350 ml.'],
    ['Sample Lamp', 'sample-lamp', '890000', $home, 'Adjustable LED desk lamp.'],
];

$ids = [];
foreach ($simple as [$name, $slug, $price, $category, $description]) {
    $ids[$slug] = seed_simple($name, $slug, $price, $category, $description);
}

$variable = new WC_Product_Variable();
$variable->set_name('Sample T-Shirt');
$variable->set_slug('sample-t-shirt');
$variable->set_status('publish');
$variable->set_catalog_visibility('visible');
$variable->set_description('Cotton t-shirt with a relaxed fit.');
$variable->set_short_description('Cotton t-shirt.');
$variable->set_category_ids([$apparel]);

$attribute = new WC_Product_Attribute();
$attribute->set_id(0);
$attribute->set_name('Size');
$attribute->set_options(['S', 'M']);
$attribute->set_position(0);
$attribute->set_visible(true);
$attribute->set_variation(true);
$variable->set_attributes([$attribute]);

$parentId = (int) $variable->save();

foreach (['S' => '450000', 'M' => '470000'] as $size => $price) {
    $variation = new WC_Product_Variation();
    $variation->set_parent_id($parentId);
    $variation->set_regular_price($price);
    $variation->set_sku('seed-tshirt-' . strtolower($size));
    $variation->set_attributes(['size' => $size]);
    $variation->save();
}

WC_Product_Variable::sync($parentId);

echo 'simple=' . wp_json_encode($ids) . "\n";
echo 'variable_parent=' . $parentId . "\n";
echo 'variations=' . wp_json_encode(wc_get_product($parentId)->get_children()) . "\n";
echo 'product_count=' . wp_count_posts('product')->publish . "\n";
