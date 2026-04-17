#!/bin/bash
# Setup complete SportsPress test environment

set -e

echo "🏗️ Setting up WordPress and SportsPress test data..."

# Skip setup if already completed (check DB state, not file — the baseline
# volume persists across container recreations but MySQL data does not).
if mysql --socket=/run/mysqld/mysqld.sock -e "SELECT 1 FROM wordpress.wp_options LIMIT 1" >/dev/null 2>&1; then
    echo "✅ WordPress tables exist. Skipping setup."
    # Re-export baseline in case DB was restored from a previous run
    mkdir -p /var/lib/baseline
    wp db export /var/lib/baseline/baseline.sql --allow-root 2>/dev/null || true
    exit 0
fi

DB_HOST=${WORDPRESS_DB_HOST:-localhost}

# Wait for database — check that MariaDB accepts connections via the
# same socket path WordPress uses, not just a TCP ping.
echo "Waiting for database..."
for i in {1..30}; do
    if mysql --socket=/run/mysqld/mysqld.sock -e "SELECT 1" >/dev/null 2>&1; then
        echo "Database is ready"
        break
    fi
    echo "Attempt $i/30: Database not ready yet..."
    if [ "$i" -eq 30 ]; then
        echo "❌ Database connection timed out after 60 seconds"
        exit 1
    fi
    sleep 2
done

# Initialize database (only for internal)
if [[ "$DB_HOST" == "localhost"* ]] || [[ "$DB_HOST" == "127.0.0.1"* ]]; then
    echo "Initializing internal database..."
    mysql -e "$(cat /docker-entrypoint-initdb.d/init-db.sql)" 2>/dev/null || echo "Database already initialized"
fi

# Install WordPress
WP_TITLE=${WORDPRESS_TITLE:-SportsPress Test Site}
WP_ADMIN_USER=${WORDPRESS_ADMIN_USER:-admin}
WP_ADMIN_PASSWORD=${WORDPRESS_ADMIN_PASSWORD:-admin}
WP_ADMIN_EMAIL=${WORDPRESS_ADMIN_EMAIL:-admin@test.com}

wp core install \
    --url="http://localhost" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --allow-root

# Configure WordPress options
wp option update users_can_register 0 --allow-root
wp option update default_comment_status closed --allow-root
wp option update default_ping_status closed --allow-root
wp option update uploads_use_yearmonth_folders 0 --allow-root

# Set URLs to localhost — wp-config.php dynamically overrides with
# $_SERVER['HTTP_HOST'] for browser requests, but this keeps WP-CLI
# and cron URLs valid.
wp option update home "http://localhost" --allow-root
wp option update siteurl "http://localhost" --allow-root

# Remove default WordPress plugins
echo "Removing default plugins..."
wp plugin delete akismet hello --allow-root 2>/dev/null || echo "Default plugins already removed"

# Activate SportsPress (already installed in Dockerfile; install as fallback)
echo "Activating SportsPress..."
if wp plugin is-installed sportspress --allow-root 2>/dev/null; then
    wp plugin activate sportspress --allow-root
else
    wp plugin install sportspress --activate --allow-root
fi

# Activate any available plugins in wp-content/plugins
echo "Checking for additional plugins to activate..."
for plugin_dir in /var/www/html/wp-content/plugins/*/; do
    if [ -d "$plugin_dir" ]; then
        plugin_name=$(basename "$plugin_dir")
        if [ "$plugin_name" != "sportspress" ] && [ "$plugin_name" != "index.php" ] && [ "$plugin_name" != "wordpress-mcp" ] && [ "$plugin_name" != "abilities-api" ]; then
            echo "Found plugin: $plugin_name"
            wp plugin activate "$plugin_name" --allow-root 2>/dev/null && echo "✅ Activated $plugin_name" || echo "⚠️ Could not activate $plugin_name"
        fi
    fi
done

# Install and activate Rookie theme
echo "Installing Rookie theme..."
if wp theme install https://downloads.wordpress.org/theme/rookie.1.5.4.zip --activate --allow-root; then
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
SPORT_VALID=0
for valid in "${VALID_SPORTS[@]}"; do
    if [[ "$SPORT" == "$valid" ]]; then
        SPORT_VALID=1
        break
    fi
done
if [[ $SPORT_VALID -eq 0 ]]; then
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
wp option update sportspress_sport "$SPORT" --allow-root
echo "✅ SportsPress sample data installation completed for $SPORT"

# Generate extra SportsPress data (Teams, Players, Leagues, Seasons, etc.)
echo "Generating extra SportsPress data..."
wp eval-file /usr/local/bin/generate-extra-data.php --allow-root
echo "✅ Extra SportsPress data generated"

# Complete SportsPress setup to skip onboarding
echo "Completing SportsPress setup..."
wp option delete _sp_needs_welcome --allow-root 2>/dev/null || echo "_sp_needs_welcome option didn't exist"
wp option update sportspress_installed 1 --allow-root
wp option update sportspress_completed_setup 1 --allow-root
wp transient delete _sp_activation_redirect --allow-root 2>/dev/null || echo "No activation redirect transient"

echo "✅ SportsPress $SPORT demo data installed!"
echo "Demo includes: Teams, Players, Events, Statistics, and proper configurations"

# Complete WooCommerce setup to skip onboarding wizard
if wp plugin is-installed woocommerce --allow-root 2>/dev/null; then
    echo "Completing WooCommerce setup..."
    wp option update woocommerce_onboarding_profile 'a:1:{s:9:"completed";b:1;}' --allow-root
    wp option update woocommerce_task_list_complete "yes" --allow-root 2>/dev/null || true
    wp transient delete _wc_activation_redirect --allow-root 2>/dev/null || true
    echo "✅ WooCommerce configured"

    # Create sample WooCommerce products matching production registration structure
    echo "Creating WooCommerce registration products..."
    wp eval '
        // Create product categories: Registration > Summer 2026
        $reg_cat = term_exists("Registration", "product_cat");
        if (!$reg_cat) {
            $reg_cat = wp_insert_term("Registration", "product_cat", ["slug" => "registration"]);
        }
        $reg_id = is_array($reg_cat) ? $reg_cat["term_id"] : $reg_cat;

        $season_cat = term_exists("Summer 2026", "product_cat");
        if (!$season_cat) {
            $season_cat = wp_insert_term("Summer 2026", "product_cat", ["slug" => "summer-2026", "parent" => $reg_id]);
        }
        $season_id = is_array($season_cat) ? $season_cat["term_id"] : $season_cat;

        $products = [
            [
                "title"    => "Player Registration (S2026)",
                "slug"     => "player-registration-s2026",
                "sku"      => "S2026-P",
                "price"    => "440",
                "sale"     => "415",
                "stock"    => 20,
                "manage"   => true,
            ],
            [
                "title"    => "Goalie Registration (S2026)",
                "slug"     => "goalie-registration-s2026",
                "sku"      => "S2026-G",
                "price"    => "125",
                "sale"     => "",
                "stock"    => 4,
                "manage"   => true,
            ],
            [
                "title"    => "Player Waitlist (S2026)",
                "slug"     => "player-waitlist-s2026",
                "sku"      => "S2026-WL",
                "price"    => "0",
                "sale"     => "",
                "stock"    => 0,
                "manage"   => false,
            ],
        ];

        foreach ($products as $p) {
            if (get_page_by_path($p["slug"], OBJECT, "product")) {
                echo "Skipped (exists): " . $p["title"] . "\n";
                continue;
            }
            $id = wp_insert_post([
                "post_title"   => $p["title"],
                "post_name"    => $p["slug"],
                "post_status"  => "publish",
                "post_type"    => "product",
            ]);
            if (is_wp_error($id)) { echo "Error: " . $id->get_error_message() . "\n"; continue; }

            wp_set_object_terms($id, "simple", "product_type");
            wp_set_object_terms($id, [$reg_id, $season_id], "product_cat");

            update_post_meta($id, "_regular_price", $p["price"]);
            update_post_meta($id, "_price", $p["sale"] ?: $p["price"]);
            if ($p["sale"]) update_post_meta($id, "_sale_price", $p["sale"]);
            update_post_meta($id, "_sku", $p["sku"]);
            update_post_meta($id, "_virtual", "yes");
            update_post_meta($id, "_sold_individually", "yes");
            update_post_meta($id, "_tax_status", "none");
            update_post_meta($id, "_manage_stock", $p["manage"] ? "yes" : "no");
            update_post_meta($id, "_stock", $p["stock"]);
            update_post_meta($id, "_stock_status", ($p["manage"] && $p["stock"] > 0) ? "instock" : ($p["manage"] ? "outofstock" : "instock"));
            update_post_meta($id, "_downloadable", "no");
            update_post_meta($id, "_visibility", "visible");

            echo "Created: " . $p["title"] . " (#$id) - \$" . $p["price"] . "\n";
        }
    ' --allow-root
    echo "✅ WooCommerce products created"
fi

# Export database baseline for test state reset
# Agents can restore this snapshot between test suites to ensure clean state.
echo "Exporting database baseline snapshot..."
mkdir -p /var/lib/baseline
wp db export /var/lib/baseline/baseline.sql --allow-root
echo "✅ Database baseline saved to /var/lib/baseline/baseline.sql"

# Setup complete — exit cleanly so supervisord marks this as EXITED
echo "Setup completed successfully."