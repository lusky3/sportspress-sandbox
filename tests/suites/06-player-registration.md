# Test Suite: Player Registration

## Prerequisites
- WordPress running at http://sportspress-test with auto-login enabled
- SportsPress core plugin activated
- SPAT Player Registration child plugin activated
- WooCommerce plugin installed and activated (required for full order flow tests)
- WP-CLI available via `docker exec` or direct shell
- At least one team and season exist:
  - `wp term create sp_season "2026"`
  - `wp post create --post_type=sp_team --post_title="Registration Team" --post_status=publish`

## Test Cases

### TC-06-01: Player Registration Tab on SPAT Settings
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to http://sportspress-test/wp-admin/admin.php?page=spat-settings
2. Look for a "Player Registration" tab on the settings page
3. Click the Player Registration tab

**Expected Result:**
- The SPAT settings page loads without errors
- A "Player Registration" tab is visible and clickable
- Clicking the tab reveals Player Registration settings fields

**Verification:**
- Confirm the tab element exists in the DOM
- Confirm no PHP errors or warnings appear on the page

### TC-06-02: Settings Save — Auto-Create Player
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to SPAT settings > Player Registration tab
2. Locate the "Auto-Create Player" toggle/checkbox
3. Enable the toggle
4. Save settings

**Expected Result:**
- The auto-create setting saves without error
- A success notice appears

**Verification:**
- Reload the page and confirm the toggle remains enabled
- Verify via WP-CLI: `wp option get spat_registration_settings` includes auto-create as enabled

### TC-06-03: Settings Save — Auto-Update Player
**Priority:** High
**Type:** UI

**Steps:**
1. On the Player Registration settings tab, locate "Auto-Update Player" toggle
2. Enable the toggle
3. Save settings

**Expected Result:**
- The auto-update setting saves without error

**Verification:**
- Reload and confirm the toggle state persisted

### TC-06-04: Settings Save — Auto-Role and Player Role
**Priority:** High
**Type:** UI

**Steps:**
1. On the Player Registration settings tab, locate "Auto-Role" toggle and "Player Role" dropdown
2. Enable Auto-Role
3. Select a role from the Player Role dropdown (e.g., "Subscriber" or a custom player role)
4. Save settings

**Expected Result:**
- Both settings save without error
- The selected role is stored correctly

**Verification:**
- Reload and confirm Auto-Role is enabled and the correct role is selected
- Verify via WP-CLI: `wp option get spat_registration_settings` reflects both values

### TC-06-05: Settings Save — Auto-Season
**Priority:** High
**Type:** UI

**Steps:**
1. On the Player Registration settings tab, locate "Auto-Season" setting
2. Select "2026" or the current season
3. Save settings

**Expected Result:**
- The auto-season setting saves without error

**Verification:**
- Reload and confirm the season selection persisted
- Verify via WP-CLI: the option value includes the correct season

### TC-06-06: Settings Persist After Reload
**Priority:** Critical
**Type:** UI

**Steps:**
1. Configure all Player Registration settings (auto-create, auto-update, auto-role, player role, auto-season) to specific values
2. Save settings
3. Navigate away to a different admin page (e.g., Dashboard)
4. Navigate back to SPAT settings > Player Registration tab

**Expected Result:**
- All previously saved settings retain their values
- No settings have reverted to defaults

**Verification:**
- Compare each setting value against what was saved — all must match

### TC-06-07: Database Table spat_registration_logs Exists
**Priority:** Critical
**Type:** Hybrid

**Steps:**
1. Run WP-CLI: `wp db query "SHOW TABLES LIKE '%spat_registration_logs%'"`
2. Verify the table exists in the output

**Expected Result:**
- The query returns a row containing the `spat_registration_logs` table name (with the WordPress table prefix)

**Verification:**
- The output is not empty and contains `spat_registration_logs`
- Optionally describe the table: `wp db query "DESCRIBE $(wp db prefix)spat_registration_logs"`

### TC-06-08: WP-CLI — Simulate Order Completion and Player Creation
**Priority:** Critical
**Type:** Hybrid

**Steps:**
1. NOTE: This test requires WooCommerce to be active. Skip if WooCommerce is not installed.
2. Create a WooCommerce order via WP-CLI:
   `wp wc order create --customer_id=1 --status=pending --user=1`
3. Add order meta with player details:
   `wp post meta update {ORDER_ID} _billing_first_name "Auto"`
   `wp post meta update {ORDER_ID} _billing_last_name "Player"`
   `wp post meta update {ORDER_ID} _billing_email "autoplayer@example.com"`
4. Simulate order completion:
   `wp eval "do_action('woocommerce_order_status_completed', {ORDER_ID});"`
5. Check if a player was auto-created

**Expected Result:**
- The order completion hook triggers the player registration logic
- A new sp_player post is created with the name "Auto Player"

**Verification:**
- Verify via WP-CLI: `wp post list --post_type=sp_player --fields=ID,post_title` includes "Auto Player"
- Check the registration log: `wp db query "SELECT * FROM $(wp db prefix)spat_registration_logs ORDER BY id DESC LIMIT 1"`

### TC-06-09: Duplicate Detection Logic
**Priority:** High
**Type:** Hybrid

**Steps:**
1. NOTE: This test requires WooCommerce to be active. Skip if WooCommerce is not installed.
2. Ensure a player "Auto Player" already exists from TC-06-08
3. Create another WooCommerce order with the same player details:
   `wp wc order create --customer_id=1 --status=pending --user=1`
4. Set the same billing name and email on the new order
5. Simulate order completion:
   `wp eval "do_action('woocommerce_order_status_completed', {ORDER_ID});"`
6. Count sp_player posts with title "Auto Player"

**Expected Result:**
- The duplicate detection logic prevents creating a second player with the same name/email
- Only one "Auto Player" sp_player post exists (or the existing one is updated)

**Verification:**
- Verify via WP-CLI: `wp post list --post_type=sp_player --s="Auto Player" --fields=ID,post_title` returns exactly one result
- Check the registration log for a duplicate detection entry

### TC-06-10: Activity Logging in registration_logs Table
**Priority:** High
**Type:** Hybrid

**Steps:**
1. After running TC-06-08 and TC-06-09, query the registration logs table
2. Run: `wp db query "SELECT * FROM $(wp db prefix)spat_registration_logs ORDER BY id DESC LIMIT 5"`

**Expected Result:**
- The table contains log entries for the player creation and duplicate detection events
- Each log entry includes relevant details (order ID, player ID, action type, timestamp)

**Verification:**
- Confirm at least two log entries exist (one creation, one duplicate check)
- Confirm each entry has non-null values for key columns
