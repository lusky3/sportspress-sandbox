#!/usr/bin/env bash
set -euo pipefail

# Creates a registration product + a completed order for it, so a human
# driving the sandbox can inspect the exact flow bin/live-env/smoke-registration.php
# in SportsPress-Admin-Tools proves in CI, without re-deriving the fixture by hand.
#
# Usage (from the host): docker exec sportspress-test bash /usr/local/bin/fixtures-registration.sh

wp eval '
$reg_cat       = get_term_by( "name", "Registration", "product_cat" );
$reg_cat_id    = $reg_cat ? $reg_cat->term_id : wp_insert_term( "Registration", "product_cat" )["term_id"];
$player_tag    = get_term_by( "name", "Player", "product_tag" );
$player_tag_id = $player_tag ? $player_tag->term_id : wp_insert_term( "Player", "product_tag" )["term_id"];

$product = new WC_Product_Simple();
$product->set_name( "Player Registration (S2026)" );
$product->set_regular_price( "0" );
$product->set_price( "0" );
$product->set_virtual( true );
$product->set_status( "publish" );
$product->set_category_ids( array( $reg_cat_id ) );
$product->set_tag_ids( array( $player_tag_id ) );
$product_id = $product->save();

$order = wc_create_order();
$order->add_product( wc_get_product( $product_id ), 1 );
$order->set_billing_email( "fixture-player@example.test" );
$order->set_billing_first_name( "Fixture" );
$order->set_billing_last_name( "Player" );
$order->calculate_totals();
$order->save();
$order->update_status( "completed" );

printf( "Product: %d  Order: %d  Status: %s\n", $product_id, $order->get_id(), $order->get_status() );
' --allow-root
