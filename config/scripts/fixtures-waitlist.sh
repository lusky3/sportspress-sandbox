#!/usr/bin/env bash
set -euo pipefail

# Creates the waitlist scenario (target product + waitlist product + a queued
# entry) so a human driving the sandbox can offer/claim/complete it manually
# through the League Dashboard UI or REST, matching what
# bin/live-env/smoke-waitlist.php in SportsPress-Admin-Tools proves in CI.
#
# Usage (from the host): docker exec sportspress-test bash /usr/local/bin/fixtures-waitlist.sh

wp eval '
if ( ! class_exists( "SPLM_Waitlist_Database" ) ) {
	echo "league_waitlist module is not enabled -- run setup-test-data.sh first.\n";
	exit( 1 );
}

$reg_cat         = get_term_by( "name", "Registration", "product_cat" );
$reg_cat_id      = $reg_cat ? $reg_cat->term_id : wp_insert_term( "Registration", "product_cat" )["term_id"];
$player_tag      = get_term_by( "name", "Player", "product_tag" );
$player_tag_id   = $player_tag ? $player_tag->term_id : wp_insert_term( "Player", "product_tag" )["term_id"];
$waitlist_tag    = get_term_by( "name", "Waitlist", "product_tag" );
$waitlist_tag_id = $waitlist_tag ? $waitlist_tag->term_id : wp_insert_term( "Waitlist", "product_tag" )["term_id"];

$target = new WC_Product_Simple();
$target->set_name( "Player Registration (S2027)" );
$target->set_regular_price( "575" );
$target->set_price( "575" );
$target->set_status( "publish" );
$target->set_category_ids( array( $reg_cat_id ) );
$target->set_tag_ids( array( $player_tag_id ) );
$target_id = $target->save();

$waitlist = new WC_Product_Simple();
$waitlist->set_name( "Player Waitlist (S2027)" );
$waitlist->set_regular_price( "0" );
$waitlist->set_price( "0" );
$waitlist->set_virtual( true );
$waitlist->set_status( "publish" );
$waitlist->set_category_ids( array( $reg_cat_id ) );
$waitlist->set_tag_ids( array( $player_tag_id, $waitlist_tag_id ) );
$waitlist_id = $waitlist->save();

$order = wc_create_order();
$order->add_product( wc_get_product( $waitlist_id ), 1 );
$order->set_billing_email( "fixture-waitlist@example.test" );
$order->calculate_totals();
$order->save();
$order->update_status( "completed" );

global $wpdb;
$row = $wpdb->get_row( $wpdb->prepare( "SELECT id FROM {$wpdb->prefix}splm_waitlist WHERE email=%s", "fixture-waitlist@example.test" ) );

printf(
	"Target product: %d\nWaitlist product: %d\nWaitlist row: %s\n\nOpen the League Dashboard -> Waitlist tab to offer this entry a spot.\n",
	$target_id,
	$waitlist_id,
	$row ? $row->id : "NOT CREATED -- check league_waitlist is enabled"
);
' --allow-root
