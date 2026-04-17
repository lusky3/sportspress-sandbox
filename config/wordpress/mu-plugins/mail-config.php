<?php
/**
 * Plugin Name: Mail Configuration
 * Description: Routes WordPress email through Mailpit SMTP for testing.
 */

add_filter('wp_mail_from', function () {
    return 'wordpress@sportspress.test';
});

add_filter('wp_mail_from_name', function () {
    return 'SportsPress Test';
});

add_action('phpmailer_init', function ($phpmailer) {
    $phpmailer->isSMTP();
    $phpmailer->Host       = 'mailpit';
    $phpmailer->Port       = 1025;
    $phpmailer->SMTPAuth   = false;
    $phpmailer->SMTPAutoTLS = false;
});
