<?php
/**
 * Plugin Name: Auto Login Admin
 * Description: Automatically logs in as admin for testing purposes.
 */

add_action('init', function() {
    // 1. Skip if CLI
    if (defined('WP_CLI') && WP_CLI) {
        return;
    }

    // 2. Skip if trying to log out
    if (isset($_GET['action']) && $_GET['action'] === 'logout') {
        return;
    }

    // 3. Get Admin User
    $user = get_user_by('login', 'admin');
    if (!$user) {
        return;
    }

    // 4. Log in if not already
    if (!is_user_logged_in()) {
        wp_set_current_user($user->ID, $user->user_login);
        wp_set_auth_cookie($user->ID);
        do_action('wp_login', $user->user_login, $user);
    }

    // 5. Redirect if on login page
    $request_uri = $_SERVER['REQUEST_URI'] ?? '';
    if (strpos($request_uri, 'wp-login.php') !== false && !isset($_GET['action'])) {
        wp_redirect(admin_url());
        exit;
    }
});
