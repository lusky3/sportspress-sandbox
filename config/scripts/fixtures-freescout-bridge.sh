#!/usr/bin/env bash
set -euo pipefail

# Creates the known player scenario the FreeScout SPAT bridge's end-to-end test
# asserts against: a shared email on two players (Jordan Smith / Riley Smith), a
# captain, a future-dated next game, one processed registration order and one
# completed-but-unprocessed order (the "needs attention" case). Idempotent: every
# insert is guarded, so a re-run changes nothing and prints the same ids.
#
# Usage (from the host):
#   docker exec sportspress-test bash /usr/local/bin/fixtures-freescout-bridge.sh <secret>
#
# Prints one line of JSON: {"email":"...","player_ids":[...],"team":"Ducks"}

if [ $# -lt 1 ] || [ -z "$1" ]; then
	echo "usage: $0 <freescout-shared-secret>" >&2
	exit 1
fi

# wp eval chatter (notices, deprecations) must not pollute the single JSON line,
# so capture stdout and keep only its last line.
OUT=$(SPB_SECRET="$1" wp eval '
$email = "fixture-bridge@example.test";

update_option( "spat_freescout_secret", getenv( "SPB_SECRET" ) );
update_option(
	"spat_enabled_modules",
	array_values(
		array_unique(
			array_merge(
				(array) get_option( "spat_enabled_modules", array() ),
				array( "player_modifications", "player_registration" )
			)
		)
	)
);

function spb_term( $name, $taxonomy ) {
	$term = get_term_by( "name", $name, $taxonomy );
	if ( $term ) {
		return (int) $term->term_id;
	}
	$res = wp_insert_term( $name, $taxonomy );
	if ( is_wp_error( $res ) ) {
		fwrite( STDERR, $res->get_error_message() . "\n" );
		exit( 1 );
	}
	return (int) $res["term_id"];
}

// Find by exact title + post type, else insert.
function spb_post( $type, $title, $status = "publish", $extra = array() ) {
	$found = get_posts(
		array(
			"post_type"      => $type,
			"title"          => $title,
			"post_status"    => "any",
			"posts_per_page" => 1,
			"fields"         => "ids",
		)
	);
	if ( $found ) {
		return (int) $found[0];
	}
	$id = wp_insert_post(
		array_merge(
			array(
				"post_type"   => $type,
				"post_title"  => $title,
				"post_status" => $status,
			),
			$extra
		),
		true
	);
	if ( is_wp_error( $id ) ) {
		fwrite( STDERR, $id->get_error_message() . "\n" );
		exit( 1 );
	}
	return (int) $id;
}

// Season, division, position, venue, teams.
$season_id = spb_term( "S2026", "sp_season" );
$league_id = spb_term( "Div 3", "sp_league" );
$forward   = spb_term( "Forward", "sp_position" );
$venue_id  = spb_term( "Rink 2", "sp_venue" );
update_option( "sportspress_season", $season_id );

$ducks  = spb_post( "sp_team", "Ducks" );
$otters = spb_post( "sp_team", "Otters" );

// Players: both share one email (the shared-family-email case).
function spb_player( $name, $number, $email, $team_id, $league_id, $season_id, $forward ) {
	$id = spb_post( "sp_player", $name );
	update_post_meta( $id, "spt_email", $email );
	update_post_meta( $id, "sp_number", $number );
	update_post_meta( $id, "spt_skill_level", "B" );
	update_post_meta( $id, "sp_leagues", array( $league_id => array( $season_id => $team_id ) ) );
	update_post_meta( $id, "sp_current_team", $team_id );
	wp_set_object_terms( $id, array( $forward ), "sp_position" );
	wp_set_object_terms( $id, array( $league_id ), "sp_league" );
	wp_set_object_terms( $id, array( $season_id ), "sp_season" );
	return $id;
}

$jordan = spb_player( "Jordan Smith", 17, $email, $ducks, $league_id, $season_id, $forward );
$riley  = spb_player( "Riley Smith", 4, $email, $otters, $league_id, $season_id, $forward );

// Linked WP user for Jordan only.
$user    = get_user_by( "email", $email );
$user_id = $user ? (int) $user->ID : (int) wp_insert_user(
	array(
		"user_login"   => "fixture-bridge",
		"user_email"   => $email,
		"user_pass"    => wp_generate_password(),
		"display_name" => "Jordan Smith",
		"role"         => "subscriber",
	)
);
update_post_meta( $jordan, "sp_user", $user_id );

// Captaincy: the current-season captain is read from the team active list, i.e.
// the team post sp_list meta, whose list carries spt_captain.
$list_id = spb_post( "sp_list", "Ducks S2026" );
update_post_meta( $list_id, "sp_team", $ducks );
update_post_meta( $list_id, "spt_captain", $jordan );
wp_set_object_terms( $list_id, array( $season_id ), "sp_season" );
wp_set_object_terms( $list_id, array( $league_id ), "sp_league" );
update_post_meta( $ducks, "sp_list", $list_id );

// Next game: future-dated, 7 days ahead at 21:45 site time (set once, on insert).
$when = new DateTime( "now", wp_timezone() );
$when->modify( "+7 days" )->setTime( 21, 45, 0 );
$event_id = spb_post(
	"sp_event",
	"Ducks vs Otters",
	"future",
	array(
		"post_date"     => $when->format( "Y-m-d H:i:s" ),
		"post_date_gmt" => gmdate( "Y-m-d H:i:s", $when->getTimestamp() ),
	)
);
if ( ! get_post_meta( $event_id, "sp_team", false ) ) {
	add_post_meta( $event_id, "sp_team", $ducks );
	add_post_meta( $event_id, "sp_team", $otters );
}
wp_set_object_terms( $event_id, array( $venue_id ), "sp_venue" );
wp_set_object_terms( $event_id, array( $league_id ), "sp_league" );
wp_set_object_terms( $event_id, array( $season_id ), "sp_season" );

// Completed orders. The registration plugin processes completed orders on
// woocommerce_order_status_completed; letting it run would create/link players
// and write its own logs, corrupting the fixture. Detach the hook for the save.
function spb_order( $tag, $processed ) {
	$found = wc_get_orders(
		array(
			"limit"      => 1,
			"return"     => "ids",
			"meta_key"   => "_spb_fixture",
			"meta_value" => $tag,
		)
	);
	if ( $found ) {
		return (int) $found[0];
	}
	global $wp_filter;
	$hook  = "woocommerce_order_status_completed";
	$saved = isset( $wp_filter[ $hook ] ) ? $wp_filter[ $hook ] : null;
	unset( $wp_filter[ $hook ] );

	$order = wc_create_order();
	$order->set_billing_email( "fixture-bridge@example.test" );
	$order->set_billing_first_name( "Jordan" );
	$order->set_billing_last_name( "Smith" );
	$order->update_meta_data( "_spb_fixture", $tag );
	if ( $processed ) {
		$order->update_meta_data( "_spr_processed", "1" );
	}
	$order->set_status( "completed" );
	$order->save();

	if ( null !== $saved ) {
		$wp_filter[ $hook ] = $saved;
	}
	return (int) $order->get_id();
}

function spb_log( $order_id, $action, $player_id, $links, $ts ) {
	global $wpdb;
	$table  = $wpdb->prefix . "spat_registration_logs";
	$exists = $wpdb->get_var( $wpdb->prepare( "SELECT id FROM {$table} WHERE order_id=%d AND action=%s", $order_id, $action ) );
	if ( $exists ) {
		return;
	}
	$wpdb->insert(
		$table,
		array(
			"timestamp"      => $ts,
			"order_id"       => $order_id,
			"customer_name"  => "Jordan Smith",
			"player_id"      => $player_id,
			"season"         => "S2026",
			"position"       => "Player",
			"action"         => $action,
			"links_to_order" => $links,
		)
	);
}

$processed = spb_order( "processed", true );
spb_log( $processed, "player_created", $jordan, 1, "2026-09-03 14:02:00" );

$attention = spb_order( "attention", false );
spb_log( $attention, "name_rejected", null, 0, "2026-09-10 09:30:00" );

echo wp_json_encode( array( "email" => $email, "player_ids" => array( $jordan, $riley ), "team" => "Ducks" ) );
' --allow-root)

printf '%s\n' "$OUT" | tail -n 1
