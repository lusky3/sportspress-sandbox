<?php
/**
 * Plugin Name: REST API Health Endpoint
 * Description: Provides a /wp-json/test/v1/health endpoint for container
 *              healthchecks and LLM agent readiness verification.
 *
 * Returns JSON with WordPress version, SportsPress status, active plugins,
 * and current sport configuration. Used by docker compose healthcheck and
 * by agents before starting test suites.
 */

add_action('rest_api_init', function () {
    // GET /wp-json/test/v1/health — public, no auth required
    register_rest_route('test/v1', '/health', [
        'methods'             => 'GET',
        'callback'            => 'sp_test_health_callback',
        'permission_callback' => '__return_true',
    ]);
});

/**
 * Health endpoint callback.
 *
 * @return WP_REST_Response Environment status for agent consumption.
 */
function sp_test_health_callback() {
    // Gather active plugin slugs
    $active_plugins = get_option('active_plugins', []);
    $plugin_slugs   = array_map(function ($p) {
        return dirname($p);
    }, $active_plugins);

    return new WP_REST_Response([
        'status'          => 'ready',
        'wordpress'       => get_bloginfo('version'),
        'sportspress'     => defined('SP_VERSION') ? SP_VERSION : 'not-active',
        'sport'           => get_option('sportspress_sport', 'unknown'),
        'plugins'         => array_values($plugin_slugs),
        'theme'           => get_stylesheet(),
        'auto_login'      => file_exists(WPMU_PLUGIN_DIR . '/auto-login.php'),
        'baseline_exists' => file_exists('/var/lib/baseline/baseline.sql'),
        'timestamp'       => gmdate('c'),
    ], 200);
}
