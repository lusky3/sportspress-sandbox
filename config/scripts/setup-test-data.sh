#!/bin/bash
# Setup complete SportsPress test environment

set -e

echo "🏗️ Setting up WordPress and SportsPress test data..."

# Wait for MariaDB to start via supervisord
echo "Waiting for database to be ready..."
for i in {1..30}; do
    if mysqladmin ping -h"localhost" --silent 2>/dev/null; then
        echo "Database is ready"
        break
    fi
    echo "Attempt $i/30: Database not ready yet..."
    sleep 2
done

# Initialize database
echo "Initializing database..."
mysql -e "$(cat /docker-entrypoint-initdb.d/init-db.sql)" 2>/dev/null || echo "Database already initialized"

# Install WordPress
wp core install \
    --url="http://localhost" \
    --title="SportsPress Test Site" \
    --admin_user="admin" \
    --admin_password="admin" \
    --admin_email="admin@test.com" \
    --allow-root

# Configure WordPress options
wp option update users_can_register 0 --allow-root
wp option update default_comment_status closed --allow-root
wp option update default_ping_status closed --allow-root
wp option update uploads_use_yearmonth_folders 0 --allow-root

# Clear any hardcoded URLs to prevent redirects
wp option update home "" --allow-root
wp option update siteurl "" --allow-root

# Remove default WordPress plugins
echo "Removing default plugins..."
wp plugin delete akismet hello --allow-root 2>/dev/null || echo "Default plugins already removed"

# Install and activate plugins
echo "Installing SportsPress..."
wp plugin install sportspress --activate --allow-root

# Activate any available plugins in wp-content/plugins
echo "Checking for additional plugins to activate..."
for plugin_dir in /var/www/html/wp-content/plugins/*/; do
    if [ -d "$plugin_dir" ]; then
        plugin_name=$(basename "$plugin_dir")
        if [ "$plugin_name" != "sportspress" ] && [ "$plugin_name" != "index.php" ]; then
            echo "Found plugin: $plugin_name"
            wp plugin activate "$plugin_name" --allow-root 2>/dev/null && echo "✅ Activated $plugin_name" || echo "⚠️ Could not activate $plugin_name"
        fi
    fi
done

# Install and activate Rookie theme
echo "Installing Rookie theme..."
if wp theme install https://downloads.wordpress.org/theme/rookie.zip --activate --allow-root; then
    echo "✅ Rookie theme activated successfully"
    echo "Removing all default themes..."
    wp theme delete twentytwentyfive twentytwentyfour twentytwentythree --allow-root 2>/dev/null || echo "Some default themes already removed"
else
    echo "⚠️ Rookie theme activation failed"
    echo "Removing older default themes only..."
    wp theme delete twentytwentyfour twentytwentythree --allow-root 2>/dev/null || echo "Some default themes already removed"
fi

# Install SportsPress demo data based on sport selection
SPORT=${SPORTSPRESS_SPORT:-ice-hockey}

# Validate sport selection
VALID_SPORTS=("soccer" "american-football" "australian-football" "baseball" "basketball" "cricket" "floorball" "football" "handball" "ice-hockey" "netball" "rugby-league" "rugby-union" "volleyball")
if [[ ! " ${VALID_SPORTS[@]} " =~ " ${SPORT} " ]]; then
    echo "❌ Invalid sport: $SPORT"
    echo "Valid sports: ${VALID_SPORTS[*]}"
    echo "Defaulting to ice-hockey"
    SPORT="ice-hockey"
fi

echo "Installing SportsPress sample data for sport: $SPORT"
wp eval "
if (class_exists('SP_Admin_Sports')) {
    SP_Admin_Sports::apply_preset('$SPORT');
}

if (class_exists('SP_Admin_Sample_Data')) {
    SP_Admin_Sample_Data::delete_posts();
    SP_Admin_Sample_Data::insert_posts();
    echo 'Sample data installed successfully';
} else {
    echo 'SP_Admin_Sample_Data class not found';
}
" --allow-root
echo "✅ SportsPress sample data installation completed for $SPORT"

# Complete SportsPress setup to skip onboarding
echo "Completing SportsPress setup..."
wp option delete _sp_needs_welcome --allow-root 2>/dev/null || echo "_sp_needs_welcome option didn't exist"
wp option update sportspress_installed 1 --allow-root
wp option update sportspress_completed_setup 1 --allow-root
wp transient delete _sp_activation_redirect --allow-root 2>/dev/null || echo "No activation redirect transient"

echo "✅ SportsPress $SPORT demo data installed!"
echo "Demo includes: Teams, Players, Events, Statistics, and proper configurations"

# Keep the setup process running to prevent container exit
echo "Setup completed, keeping process alive..."
tail -f /dev/null