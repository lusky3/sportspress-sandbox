#!/usr/bin/env bash
set -euo pipefail

# Creates the known player scenario the FreeScout SPAT bridge's end-to-end test
# asserts against: a shared email on two players (Jordan Smith / Riley Smith), a
# captain, a future-dated next game, one processed registration order and one
# completed-but-unprocessed registration order (the "needs attention" case); both
# hold a product from the "Registration" category. Idempotent: every
# insert is guarded and a re-run prints the same ids. A re-run also restores what a
# test may have changed: the e-Transfer rows and the on-hold order (seed state
# after a match), the next game's date (7 days ahead again), the waitlist rows
# and the change-email player, user and order. Any failed DB write exits non-zero.
#
# Usage (from the host):
#   docker exec sportspress-test bash /usr/local/bin/fixtures-freescout-bridge.sh <secret> [events-url]
#
# With an events URL, also sets spat_freescout_events_url and enables events
# (spat_freescout_events_enabled=1). Without one, events are disabled and the
# URL option is deleted.
#
# Also seeds e-Transfer rows (matched, unmatched, mismatch), an on-hold order
# totalling 325.00 and two WP users (admin@example.test administrator,
# nocap@example.test subscriber).
#
# Also seeds waitlist rows (a queued player entry and an expired goalie entry
# for the fixture email, target = a "S2026 Player Registration" product), a
# "Casey Change" player + WP user (change-me@example.test) with one completed
# order for the change-email action, enables league_waitlist, and installs the
# spb-mail-capture mu-plugin (ALL wp_mail() in the sandbox is then captured to
# option spb_captured_mail instead of sent, from the next request on).
#
# Prints one line of JSON: {"email":"...","player_ids":[...],"team":"Ducks",
# "etransfer_log_id":..,"possible_match_log_id":..,"mismatch_log_id":..,
# "matched_log_id":..,"on_hold_order_id":..,"agent_email":"..","nocap_email":"..",
# "events_enabled":true|false,"waitlist_queued_id":..,"waitlist_expired_id":..,
# "change_email_player_id":..,"change_email":"change-me@example.test"}

if [ $# -lt 1 ] || [ -z "$1" ]; then
	echo "usage: $0 <freescout-shared-secret> [events-url]" >&2
	exit 1
fi

# Install the mail-capture mu-plugin (active from the next request on) and make
# sure league-manager, which owns the waitlist, is active.
MU_DIR=/var/www/html/wp-content/mu-plugins
mkdir -p "$MU_DIR"
cp /usr/local/bin/spb-mail-capture.php "$MU_DIR/spb-mail-capture.php"
wp plugin is-active sportspress-league-manager --allow-root >/dev/null 2>&1 \
	|| wp plugin activate sportspress-league-manager --allow-root >/dev/null 2>&1 || true

# wp eval chatter (notices, deprecations) must not pollute the single JSON line,
# so capture stdout and keep only its last line.
OUT=$(SPB_SECRET="$1" SPB_EVENTS_URL="${2:-}" wp eval '
$email = "fixture-bridge@example.test";

update_option( "spat_freescout_secret", getenv( "SPB_SECRET" ) );

// Events are on only when an events URL is given. Without one, the URL option
// is deleted too, so the state is the same as on a fresh install.
$events_url = (string) getenv( "SPB_EVENTS_URL" );
if ( "" !== $events_url ) {
	update_option( "spat_freescout_events_url", esc_url_raw( $events_url ) );
	update_option( "spat_freescout_events_enabled", "1" );
} else {
	delete_option( "spat_freescout_events_url" );
	update_option( "spat_freescout_events_enabled", "0" );
}
$events_enabled = "" !== $events_url;

update_option(
	"spat_enabled_modules",
	array_values(
		array_unique(
			array_merge(
				(array) get_option( "spat_enabled_modules", array() ),
				array( "player_modifications", "player_registration", "etransfer_automation", "league_waitlist" )
			)
		)
	)
);

function spb_fail( $message ) {
	fwrite( STDERR, $message . "\n" );
	exit( 1 );
}

// Fail fast on a failed $wpdb write ($res === false), like spb_term/spb_post.
function spb_db_check( $res, $what ) {
	global $wpdb;
	if ( false === $res ) {
		fwrite( STDERR, $what . " failed: " . $wpdb->last_error . "\n" );
		exit( 1 );
	}
	return $res;
}

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

// Next game: future-dated, 7 days ahead at 21:45 site time. The post is found by
// title, so it is re-dated on every run: a re-run after the first date has
// passed must not leave it in the past.
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
$res = wp_update_post(
	array(
		"ID"            => $event_id,
		"post_status"   => "future",
		"post_date"     => $when->format( "Y-m-d H:i:s" ),
		"post_date_gmt" => gmdate( "Y-m-d H:i:s", $when->getTimestamp() ),
		"edit_date"     => true,
	),
	true
);
if ( is_wp_error( $res ) ) {
	fwrite( STDERR, $res->get_error_message() . "\n" );
	exit( 1 );
}
if ( ! get_post_meta( $event_id, "sp_team", false ) ) {
	add_post_meta( $event_id, "sp_team", $ducks );
	add_post_meta( $event_id, "sp_team", $otters );
}
wp_set_object_terms( $event_id, array( $venue_id ), "sp_venue" );
wp_set_object_terms( $event_id, array( $league_id ), "sp_league" );
wp_set_object_terms( $event_id, array( $season_id ), "sp_season" );

// A registration product: SPAT counts an order as a registration only when a
// line item is in a product category whose name holds the registration keyword
// (default "registration"), the same way fixtures-registration.sh sets it up.
$reg_cat    = spb_term( "Registration", "product_cat" );
$player_tag = spb_term( "Player", "product_tag" );
$found      = get_posts(
	array(
		"post_type"      => "product",
		"title"          => "FreeScout Bridge Registration (S2026)",
		"post_status"    => "any",
		"posts_per_page" => 1,
		"fields"         => "ids",
	)
);
if ( $found ) {
	$reg_product = (int) $found[0];
} else {
	$product = new WC_Product_Simple();
	$product->set_name( "FreeScout Bridge Registration (S2026)" );
	$product->set_regular_price( "0" );
	$product->set_price( "0" );
	$product->set_virtual( true );
	$product->set_status( "publish" );
	$product->set_category_ids( array( $reg_cat ) );
	$product->set_tag_ids( array( $player_tag ) );
	$reg_product = (int) $product->save();
}

// Completed registration orders. The registration plugin processes completed
// orders on woocommerce_order_status_completed; letting it run would
// create/link players and write its own logs, corrupting the fixture. Detach
// the hook for the save.
function spb_order( $tag, $processed, $product_id, $bill_email = "fixture-bridge@example.test", $first = "Jordan", $last = "Smith" ) {
	$found = wc_get_orders(
		array(
			"limit"      => 1,
			"return"     => "ids",
			"meta_key"   => "_spb_fixture",
			"meta_value" => $tag,
		)
	);
	if ( $found ) {
		// Orders from an older run of this script have no line items. Adding
		// one changes no status, so the completed hook does not fire.
		$order = wc_get_order( (int) $found[0] );
		if ( ! $order->get_items() ) {
			$order->add_product( wc_get_product( $product_id ), 1 );
		}
		// A re-run restores the billing name too (a real SPAT re-run, or an
		// older script version, may have left another one).
		$order->set_billing_first_name( $first );
		$order->set_billing_last_name( $last );
		$order->save();
		return (int) $found[0];
	}
	global $wp_filter;
	$hook  = "woocommerce_order_status_completed";
	$saved = isset( $wp_filter[ $hook ] ) ? $wp_filter[ $hook ] : null;
	unset( $wp_filter[ $hook ] );

	try {
		$order = wc_create_order();
		$order->add_product( wc_get_product( $product_id ), 1 );
		$order->set_billing_email( $bill_email );
		$order->set_billing_first_name( $first );
		$order->set_billing_last_name( $last );
		$order->update_meta_data( "_spb_fixture", $tag );
		if ( $processed ) {
			$order->update_meta_data( "_spr_processed", "1" );
		}
		$order->calculate_totals();
		$order->set_status( "completed" );
		$order->save();
	} finally {
		if ( null !== $saved ) {
			$wp_filter[ $hook ] = $saved;
		}
	}
	return (int) $order->get_id();
}

function spb_log( $order_id, $action, $player_id, $links, $ts, $name = "Jordan Smith" ) {
	global $wpdb;
	$table  = $wpdb->prefix . "spat_registration_logs";
	$exists = $wpdb->get_var( $wpdb->prepare( "SELECT id FROM {$table} WHERE order_id=%d AND action=%s", $order_id, $action ) );
	if ( $exists ) {
		return;
	}
	$ok = $wpdb->insert(
		$table,
		array(
			"timestamp"      => $ts,
			"order_id"       => $order_id,
			"customer_name"  => $name,
			"player_id"      => $player_id,
			"season"         => "S2026",
			"position"       => "Player",
			"action"         => $action,
			"links_to_order" => $links,
		)
	);
	spb_db_check( $ok, "registration log insert" );
}

$processed = spb_order( "processed", true, $reg_product );
spb_log( $processed, "player_created", $jordan, 1, "2026-09-03 14:02:00" );

// The attention order has a digit in its billing name, which the registration
// name validation rejects (letters, spaces and a few punctuation marks only),
// so a real re-run of it (SPPR_Admin::rerun) stays "name rejected", as its log
// row says.
$attention = spb_order( "attention", false, $reg_product, "fixture-bridge@example.test", "Jordan", "Sm1th" );
spb_log( $attention, "name_rejected", null, 0, "2026-09-10 09:30:00", "Jordan Sm1th" );

// Agent accounts: the FreeScout e2e admin (administrator) and an agent with no
// WooCommerce capability, for the forbidden path. Passwords are random and
// never printed; the bridge authenticates with the shared secret, not them.
function spb_user( $login, $user_email, $role ) {
	$existing = get_user_by( "email", $user_email );
	if ( ! $existing ) {
		// The login may survive with another email (a change-email run changed it):
		// restore the expected one, without WordPress sending an email-changed notice.
		$existing = get_user_by( "login", $login );
		if ( $existing ) {
			add_filter( "send_email_change_email", "__return_false" );
			$res = wp_update_user( array( "ID" => $existing->ID, "user_email" => $user_email ) );
			remove_filter( "send_email_change_email", "__return_false" );
			if ( is_wp_error( $res ) ) {
				fwrite( STDERR, $res->get_error_message() . "\n" );
				exit( 1 );
			}
			$existing = get_user_by( "id", $existing->ID );
		}
	}
	if ( $existing ) {
		// Correct the role of an account left over with a different one.
		if ( array( $role ) !== array_values( $existing->roles ) ) {
			$existing->set_role( $role );
		}
		return (int) $existing->ID;
	}
	$id = wp_insert_user(
		array(
			"user_login"   => $login,
			"user_email"   => $user_email,
			"user_pass"    => wp_generate_password( 24 ),
			"display_name" => $login,
			"role"         => $role,
		)
	);
	if ( is_wp_error( $id ) ) {
		fwrite( STDERR, $id->get_error_message() . "\n" );
		exit( 1 );
	}
	return (int) $id;
}

$agent_email = "admin@example.test";
$nocap_email = "nocap@example.test";
spb_user( "fixture-agent", $agent_email, "administrator" );
spb_user( "fixture-nocap", $nocap_email, "subscriber" );

// e-Transfer fixtures. A plain item (not a registration product) priced 325,
// so the on-hold order totals the amount of the unmatched transfer.
$found = get_posts(
	array(
		"post_type"      => "product",
		"title"          => "FreeScout Bridge e-Transfer Test Item",
		"post_status"    => "any",
		"posts_per_page" => 1,
		"fields"         => "ids",
	)
);
if ( $found ) {
	$et_product = (int) $found[0];
} else {
	$product = new WC_Product_Simple();
	$product->set_name( "FreeScout Bridge e-Transfer Test Item" );
	$product->set_regular_price( "325" );
	$product->set_price( "325" );
	$product->set_virtual( true );
	$product->set_status( "publish" );
	$et_product = (int) $product->save();
}

// The on-hold order is created without firing status-transition handlers
// (emails, stock, e-Transfer automation), like the completed orders above.
function spb_on_hold_order( $product_id ) {
	$found = wc_get_orders(
		array(
			"limit"      => 1,
			"return"     => "ids",
			"meta_key"   => "_spb_fixture",
			"meta_value" => "on-hold",
		)
	);
	global $wp_filter;
	$hooks = array(
		"woocommerce_order_status_changed",
		"woocommerce_order_status_on-hold",
		"woocommerce_order_status_pending_to_on-hold",
		"woocommerce_order_status_completed_to_on-hold",
		"woocommerce_new_order",
	);
	$saved = array();
	foreach ( $hooks as $hook ) {
		if ( isset( $wp_filter[ $hook ] ) ) {
			$saved[ $hook ] = $wp_filter[ $hook ];
			unset( $wp_filter[ $hook ] );
		}
	}

	try {
		if ( $found ) {
			// A re-run puts an order that a match completed back to its seed state
			// (on-hold, unpaid, no transaction id), keeping its id.
			$order = wc_get_order( (int) $found[0] );
			if ( ! $order->has_status( "on-hold" ) ) {
				$order->set_status( "on-hold" );
			}
			$order->set_transaction_id( "" );
			$order->set_date_paid( null );
			$order->set_date_completed( null );
			$order->save();
		} else {
			$order = wc_create_order();
			$order->add_product( wc_get_product( $product_id ), 1, array( "subtotal" => 325, "total" => 325 ) );
			$order->set_billing_email( "fixture-bridge@example.test" );
			$order->set_billing_first_name( "Jordan" );
			$order->set_billing_last_name( "Smith" );
			$order->update_meta_data( "_spb_fixture", "on-hold" );
			$order->calculate_totals();
			$order->set_status( "on-hold" );
			$order->save();
		}
		// Seed state has no notes (a match and the status change each add one).
		foreach ( wc_get_order_notes( array( "order_id" => $order->get_id() ) ) as $note ) {
			if ( false === wc_delete_order_note( $note->id ) ) {
				spb_fail( "order note delete failed: " . $note->id );
			}
		}
	} finally {
		foreach ( $saved as $hook => $callbacks ) {
			$wp_filter[ $hook ] = $callbacks;
		}
	}
	return (int) $order->get_id();
}

function spb_etransfer( $reference, $from_email, $from_name, $amount, $ts, $order_id, $result ) {
	global $wpdb;
	$table = $wpdb->prefix . "spat_etransfer_logs";
	$id    = $wpdb->get_var( $wpdb->prepare( "SELECT id FROM {$table} WHERE reference_number=%s", $reference ) );
	$row   = array(
		"timestamp"        => $ts,
		"from_email"       => $from_email,
		"from_name"        => $from_name,
		"amount"           => $amount,
		"reference_number" => $reference,
		"match_criteria"   => "fixture",
		"order_id"         => $order_id,
		"result"           => $result,
	);
	if ( $id ) {
		// A re-run restores the seed state (id stays), whatever a match, a mismatch
		// confirmation or a hide wrote: order_id, result and match_criteria
		// (SPET_ETransfer_Admin::manual_match sets "Manual Match"), plus the rest.
		// A null order_id is written as NULL by $wpdb->update().
		spb_db_check( $wpdb->update( $table, $row, array( "id" => (int) $id ) ), "e-Transfer reset" );
		return (int) $id;
	}
	spb_db_check( $wpdb->insert( $table, $row ), "e-Transfer insert" );
	return (int) $wpdb->insert_id;
}

$on_hold    = spb_on_hold_order( $et_product );
$on_hold_ts = (int) wc_get_order( $on_hold )->get_date_created()->getTimestamp();
$no_match   = "No matching order found";
$utc        = "Y-m-d H:i:s";

// Matched: points at the processed order, with the result the manual match writes.
$matched_log = spb_etransfer( "FIXTURE-MATCHED", $email, "Jordan Smith", 325.00, gmdate( $utc, $on_hold_ts - 5 * DAY_IN_SECONDS ), $processed, "Manually matched and processed successfully" );
// Unmatched from another payer, one day after the on-hold order: the possible
// match for it (same amount, inside its window).
$unmatched_log = spb_etransfer( "FIXTURE-UNMATCHED", "payer-other@example.test", "Pat Smith", 325.00, gmdate( $utc, $on_hold_ts + DAY_IN_SECONDS ), null, $no_match );
// Unmatched from the customer, amount that differs from the on-hold order.
$mismatch_log = spb_etransfer( "FIXTURE-MISMATCH", $email, "Jordan Smith", 300.00, gmdate( $utc, $on_hold_ts + 2 * DAY_IN_SECONDS ), null, $no_match );

// Waitlist target: the product waitlist offers send the player to.
$found = get_posts(
	array(
		"post_type"      => "product",
		"title"          => "S2026 Player Registration",
		"post_status"    => "any",
		"posts_per_page" => 1,
		"fields"         => "ids",
	)
);
if ( $found ) {
	$wl_product = (int) $found[0];
} else {
	$product = new WC_Product_Simple();
	$product->set_name( "S2026 Player Registration" );
	$product->set_regular_price( "0" );
	$product->set_price( "0" );
	$product->set_virtual( true );
	$product->set_status( "publish" );
	$product->set_category_ids( array( $reg_cat ) );
	$product->set_tag_ids( array( $player_tag ) );
	$wl_product = (int) $product->save();
}

// Waitlist rows, guarded by email + season + position (one fixture row each).
// The table is created on plugins_loaded once the module is on, which is after
// this process started, so create it here when missing.
if ( class_exists( "SPLM_Waitlist_Database" ) && ! SPLM_Waitlist_Database::table_exists() ) {
	SPLM_Waitlist_Database::create_table();
}
function spb_waitlist( $position, $status, $target, $name, $wl_email, $offered_at, $expires_at ) {
	global $wpdb;
	$table = SPLM_Waitlist_Database::table_name();
	$id    = $wpdb->get_var( $wpdb->prepare( "SELECT id FROM {$table} WHERE email=%s AND season=%s AND position=%s ORDER BY id LIMIT 1", strtolower( $wl_email ), "S2026", $position ) );
	if ( $id ) {
		return (int) $id;
	}
	$id = SPLM_Waitlist_Database::insert(
		array(
			"season"              => "S2026",
			"position"            => $position,
			"waitlist_product_id" => 0,
			"target_product_id"   => $target,
			"name"                => $name,
			"email"               => strtolower( $wl_email ),
			"status"              => $status,
			"offered_at"          => $offered_at,
			"expires_at"          => $expires_at,
		)
	);
	if ( ! $id ) {
		fwrite( STDERR, "waitlist insert failed: " . $wpdb->last_error . "\n" );
		exit( 1 );
	}
	return (int) $id;
}
$wl_queued  = spb_waitlist( "player", "queued", $wl_product, "Jordan Smith", $email, null, null );
$wl_expired = spb_waitlist( "goalie", "expired", $wl_product, "Jordan Smith", $email, gmdate( "Y-m-d H:i:s", time() - 3 * DAY_IN_SECONDS ), gmdate( "Y-m-d H:i:s", time() - DAY_IN_SECONDS ) );

// Change-email fixture: a player, a linked WP user and one completed order, all
// on change-me@example.test. The order is created without registration firing.
$change_email = "change-me@example.test";
global $wpdb;
$casey        = spb_player( "Casey Change", 9, $change_email, $ducks, $league_id, $season_id, $forward );
$casey_user   = spb_user( "fixture-casey", $change_email, "subscriber" );
update_post_meta( $casey, "sp_user", $casey_user );
// Last, after the user update: profile hooks may have rewritten it.
update_post_meta( $casey, "spt_email", $change_email );
$change_order = spb_order( "change-email", true, $reg_product, $change_email, "Casey", "Change" );
// A change-email run alters these; put them back on every run.
$co = wc_get_order( $change_order );
if ( strtolower( (string) $co->get_billing_email() ) !== $change_email ) {
	$co->set_billing_email( $change_email );
	$co->save();
}
// The action adds an order note; the order is seeded without any.
foreach ( wc_get_order_notes( array( "order_id" => $change_order ) ) as $note ) {
	if ( false === wc_delete_order_note( $note->id ) ) {
		spb_fail( "change-email order note delete failed: " . $note->id );
	}
}

// Reset the waitlist rows to their seed state (ids stay), whatever an offer,
// claim or resolution did: every column the lifecycle writes goes back.
$wl_table = SPLM_Waitlist_Database::table_name();
$wl_base  = array(
	"target_product_id" => $wl_product,
	"claim_token"       => null,
	"resolved_order_id" => null,
	"dispatched_by"     => 0,
	"offer_message"     => "",
);
spb_db_check(
	$wpdb->update(
		$wl_table,
		array_merge( $wl_base, array( "status" => "queued", "offered_at" => null, "expires_at" => null ) ),
		array( "id" => $wl_queued )
	),
	"waitlist queued reset"
);
spb_db_check(
	$wpdb->update(
		$wl_table,
		array_merge(
			$wl_base,
			array(
				"status"     => "expired",
				"offered_at" => gmdate( "Y-m-d H:i:s", time() - 3 * DAY_IN_SECONDS ),
				"expires_at" => gmdate( "Y-m-d H:i:s", time() - DAY_IN_SECONDS ),
			)
		),
		array( "id" => $wl_expired )
	),
	"waitlist expired reset"
);
if ( false === wp_clear_scheduled_hook( SPLM_Waitlist_Expiry::EXPIRE_HOOK, array( $wl_queued ) ) ) {
	spb_fail( "waitlist queued hook clear failed" );
}
if ( false === wp_clear_scheduled_hook( SPLM_Waitlist_Expiry::EXPIRE_HOOK, array( $wl_expired ) ) ) {
	spb_fail( "waitlist expired hook clear failed" );
}

echo wp_json_encode(
	array(
		"email"                 => $email,
		"player_ids"            => array( $jordan, $riley ),
		"team"                  => "Ducks",
		"etransfer_log_id"      => $unmatched_log,
		"possible_match_log_id" => $unmatched_log,
		"mismatch_log_id"       => $mismatch_log,
		"matched_log_id"        => $matched_log,
		"on_hold_order_id"      => $on_hold,
		"agent_email"           => $agent_email,
		"nocap_email"           => $nocap_email,
		"events_enabled"        => $events_enabled,
		"waitlist_queued_id"    => $wl_queued,
		"waitlist_expired_id"   => $wl_expired,
		"change_email_player_id" => $casey,
		"change_email"          => $change_email,
	)
);
' --allow-root)

printf '%s\n' "$OUT" | tail -n 1
