#!/usr/bin/env bash
# reset-state.sh — Reset WordPress database to baseline state between test suites.
# Works both from the host (via docker exec) and inside the container directly.
set -euo pipefail

CONTAINER="sportspress-test"
BASELINE="/tmp/baseline.sql"

# Run a WP-CLI command, routing through docker exec when on the host.
wp_cmd() {
  if [ -f /var/www/html/wp-config.php ]; then
    wp --allow-root --path=/var/www/html "$@"
  else
    docker exec "$CONTAINER" wp --allow-root --path=/var/www/html "$@"
  fi
}

# Verify baseline dump exists
if [ -f /var/www/html/wp-config.php ]; then
  [ -f "$BASELINE" ] || { echo "ERROR: $BASELINE not found inside container." >&2; exit 1; }
else
  docker exec "$CONTAINER" test -f "$BASELINE" || { echo "ERROR: $BASELINE not found in container $CONTAINER." >&2; exit 1; }
fi

echo "==> Importing baseline database..."
if [ -f /var/www/html/wp-config.php ]; then
  wp_cmd db import "$BASELINE"
else
  docker exec "$CONTAINER" wp --allow-root --path=/var/www/html db import "$BASELINE"
fi

echo "==> Flushing object cache..."
wp_cmd cache flush

echo "==> Flushing rewrite rules..."
wp_cmd rewrite flush

echo "==> State reset complete."
