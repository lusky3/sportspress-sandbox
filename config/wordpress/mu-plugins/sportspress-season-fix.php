<?php
/**
 * Plugin Name: SportsPress Season Fix
 * Description: Ensures the sp_season taxonomy is always registered in the test
 *              environment. SportsPress gates registration behind the
 *              sportspress_has_seasons filter (default true), but this guard
 *              makes it unconditional so no plugin or timing issue can suppress it.
 */

// Force the filter true at maximum priority so it overrides any callback that
// returns false, regardless of when it was registered. SP_Post_Types::register_taxonomies()
// runs on init at priority 10; this runs last when apply_filters() evaluates.
add_filter( 'sportspress_has_seasons', '__return_true', PHP_INT_MAX );
