<?php
/**
 * Plugin Name: SportsPress Season Fix
 * Description: Ensures the sp_season taxonomy is always registered in the test
 *              environment. SportsPress gates registration behind the
 *              sportspress_has_seasons filter (default true), but this guard
 *              makes it unconditional so no plugin or timing issue can suppress it.
 */

// Force the filter true early — before SportsPress's init hook (priority 10)
// registers taxonomies so it's resolved correctly on every WP-CLI invocation.
add_filter('sportspress_has_seasons', '__return_true', 1);
