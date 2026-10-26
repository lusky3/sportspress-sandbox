<?php
/**
 * Plugin Name: SPB Mail Capture
 * Description: Sandbox only. Captures every wp_mail() call instead of sending it, so waitlist offers and similar emails "send" without SMTP.
 *
 * Installed by fixtures-freescout-bridge.sh. Appends {to, subject, time} to the
 * option spb_captured_mail (last 50) and short-circuits wp_mail() with true.
 */

add_filter(
	'pre_wp_mail',
	static function ( $short_circuit, $atts ) {
		$to = isset( $atts['to'] ) ? $atts['to'] : '';
		if ( is_array( $to ) ) {
			$to = implode( ', ', $to );
		}

		$captured   = (array) get_option( 'spb_captured_mail', array() );
		$captured[] = array(
			'to'      => (string) $to,
			'subject' => isset( $atts['subject'] ) ? (string) $atts['subject'] : '',
			'time'    => gmdate( 'Y-m-d H:i:s' ),
		);
		update_option( 'spb_captured_mail', array_slice( $captured, -50 ), false );

		return true;
	},
	10,
	2
);
