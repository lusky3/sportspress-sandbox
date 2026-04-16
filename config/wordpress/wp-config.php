<?php
define('DB_NAME', getenv('WORDPRESS_DB_NAME') ?: 'wordpress');
define('DB_USER', getenv('WORDPRESS_DB_USER') ?: 'wordpress');
define('DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD') ?: 'wordpress');
define('DB_HOST', getenv('WORDPRESS_DB_HOST') ?: 'localhost:/run/mysqld/mysqld.sock');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// ⚠️  TEST ONLY — static salts. Do NOT use in production.
// These are intentionally weak for a disposable test environment.
define('AUTH_KEY',         'test-key');
define('SECURE_AUTH_KEY',  'test-key');
define('LOGGED_IN_KEY',    'test-key');
define('NONCE_KEY',        'test-key');
define('AUTH_SALT',        'test-salt');
define('SECURE_AUTH_SALT', 'test-salt');
define('LOGGED_IN_SALT',   'test-salt');
define('NONCE_SALT',       'test-salt');

$table_prefix = 'wp_';
define('WP_DEBUG', true);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', true);
define('DISABLE_WP_CRON', true);
define('AUTOMATIC_UPDATER_DISABLED', true);
define('WP_MEMORY_LIMIT', '128M');
ini_set('memory_limit', '256M');

// Dynamic URL configuration — only trust expected hosts
if (isset($_SERVER['HTTP_HOST'])) {
    $host = $_SERVER['HTTP_HOST'];
    if (preg_match('/^(localhost|sportspress-test)(:\d+)?$/', $host)) {
        define('WP_HOME', 'http://' . $host);
        define('WP_SITEURL', 'http://' . $host);
    }
}

// Disable file editing in admin; block file mods after initial setup
define('DISALLOW_FILE_EDIT', true);
if (file_exists('/var/lib/baseline/baseline.sql')) {
    define('DISALLOW_FILE_MODS', true);
}

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';

// Set WordPress options after WordPress is loaded
if (function_exists('get_option')) {
    add_action('init', function() {
        if (!get_option('users_can_register')) {
            update_option('users_can_register', 0);
            update_option('default_comment_status', 'closed');
            update_option('default_ping_status', 'closed');
        }
    });
}