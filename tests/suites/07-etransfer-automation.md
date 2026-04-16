# Test Suite: e-Transfer Automation

## Prerequisites
- WordPress running at http://sportspress-test with auto-login enabled
- SportsPress core plugin activated
- SPAT e-Transfer Automation child plugin activated
- WooCommerce plugin installed and activated
- WP-CLI available via `docker exec` or direct shell
- At least one WooCommerce order exists for matching tests

## Test Cases

### TC-07-01: e-Transfer Tab on SPAT Settings
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to http://sportspress-test/wp-admin/admin.php?page=spat-settings
2. Look for an "e-Transfer" tab on the settings page
3. Click the e-Transfer tab

**Expected Result:**
- The SPAT settings page loads without errors
- An "e-Transfer" tab is visible and clickable
- Clicking the tab reveals e-Transfer Automation settings fields

**Verification:**
- Confirm the tab element exists in the DOM
- Confirm no PHP errors or warnings appear on the page

### TC-07-02: Webhook Secret Configuration Saves
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to SPAT settings > e-Transfer tab
2. Locate the "Webhook Secret" field
3. Enter a test secret value: `test_webhook_secret_abc123`
4. Save settings

**Expected Result:**
- The webhook secret saves without error
- A success notice appears

**Verification:**
- Reload the page and confirm the secret field retains the value (may be masked)
- Verify via WP-CLI: `wp option get spat_etransfer_settings` includes the webhook secret

### TC-07-03: Service Provider Selection Saves
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to SPAT settings > e-Transfer tab
2. Locate the "Service Provider" dropdown or radio buttons
3. Select "Generic" and save settings
4. Reload and confirm "Generic" is selected
5. Change to "Deliverhook" and save settings
6. Reload and confirm "Deliverhook" is selected
7. Change to "Cloudflare" and save settings
8. Reload and confirm "Cloudflare" is selected

**Expected Result:**
- Each provider option (generic, deliverhook, cloudflare) saves and persists correctly
- No errors on save for any option

**Verification:**
- After each save/reload cycle, confirm the selected provider matches what was chosen
- Verify via WP-CLI: `wp option get spat_etransfer_settings` reflects the current provider

### TC-07-04: Equivalent Names Configuration
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to SPAT settings > e-Transfer tab
2. Locate the "Equivalent Names" configuration section
3. Add an equivalent name mapping (e.g., "Bob" = "Robert")
4. Save settings
5. Reload the page

**Expected Result:**
- The equivalent names field accepts and saves the mapping
- After reload, the saved mappings display correctly

**Verification:**
- Confirm the equivalent names section shows "Bob" = "Robert" after reload
- Verify via WP-CLI: `wp option get spat_etransfer_settings` includes the equivalent names data

### TC-07-05: WooCommerce e-Transfer Webhooks Page Loads
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to http://sportspress-test/wp-admin/admin.php?page=spet-webhooks (or locate via WooCommerce menu)
2. If the exact URL differs, look for "e-Transfer Webhooks" under the WooCommerce menu

**Expected Result:**
- The e-Transfer Webhooks page loads without errors
- The page displays a list/table of webhook entries (may be empty initially)

**Verification:**
- Confirm the page renders with a proper heading
- Confirm a table or list structure is present on the page

### TC-07-06: Pending Count Badge in WooCommerce Menu
**Priority:** Medium
**Type:** UI

**Steps:**
1. Navigate to http://sportspress-test/wp-admin/
2. Look at the WooCommerce menu item in the admin sidebar
3. Check for a pending count badge (bubble) next to the e-Transfer Webhooks submenu

**Expected Result:**
- If there are pending/unmatched webhooks, a count badge appears
- The badge number reflects the actual count of pending items

**Verification:**
- Inspect the menu item for a `.awaiting-mod` or `.update-plugins` count bubble
- If no pending items exist, the badge may not appear (which is correct)

### TC-07-07: REST API Webhook Endpoint Exists
**Priority:** Critical
**Type:** API

**Steps:**
1. Run via WP-CLI: `wp eval "echo rest_url('spet/v1/etransfer-webhook');"`
2. Test the endpoint with curl: `curl -s -o /dev/null -w '%{http_code}' http://sportspress-test/wp-json/spet/v1/etransfer-webhook`
3. Send a GET request to verify the endpoint is registered (may return 405 Method Not Allowed for GET if it only accepts POST)

**Expected Result:**
- The REST API route `spet/v1/etransfer-webhook` is registered
- The endpoint responds (not 404) — a 405 or 401 response confirms the route exists

**Verification:**
- Confirm the HTTP response code is not 404
- Verify via WP-CLI: `wp eval "echo json_encode(rest_get_server()->get_routes()['spet/v1'] ?? 'not found');"` shows the route

### TC-07-08: Webhook Security — HMAC Signature Verification
**Priority:** Critical
**Type:** API

**Steps:**
1. Ensure a webhook secret is configured (from TC-07-02)
2. Send a POST request to the webhook endpoint without an HMAC signature:
   `curl -X POST http://sportspress-test/wp-json/spet/v1/etransfer-webhook -H "Content-Type: application/json" -d '{"test": true}'`
3. Send a POST request with an invalid HMAC signature:
   `curl -X POST http://sportspress-test/wp-json/spet/v1/etransfer-webhook -H "Content-Type: application/json" -H "X-Signature: invalid" -d '{"test": true}'`
4. Compute a valid HMAC-SHA256 signature and send with the correct header

**Expected Result:**
- Request without signature is rejected (401 or 403)
- Request with invalid signature is rejected (401 or 403)
- Request with valid signature is accepted (200 or appropriate success code)

**Verification:**
- Confirm each response code matches the expected behavior
- Check error messages in the response body for unsigned/invalid requests

### TC-07-09: Webhook Security — Replay Protection
**Priority:** High
**Type:** API

**Steps:**
1. Send a valid webhook request with a timestamp and valid HMAC signature
2. Record the request details (body, headers)
3. Wait a few seconds, then replay the exact same request

**Expected Result:**
- The replayed request is rejected with an appropriate error (e.g., "duplicate" or "replay detected")

**Verification:**
- Confirm the replay response code indicates rejection
- Confirm the error message references replay or duplicate detection

### TC-07-10: Webhook Security — Rate Limiting
**Priority:** High
**Type:** API

**Steps:**
1. Send multiple rapid POST requests to the webhook endpoint (e.g., 20 requests in quick succession):
   `for i in $(seq 1 20); do curl -s -o /dev/null -w '%{http_code}\n' -X POST http://sportspress-test/wp-json/spet/v1/etransfer-webhook -d '{}'; done`
2. Observe the response codes

**Expected Result:**
- After exceeding the rate limit, requests receive a 429 Too Many Requests response
- Earlier requests within the limit receive normal responses

**Verification:**
- Confirm at least one 429 response appears in the output
- Confirm the rate limit resets after the cooldown period

### TC-07-11: Manual Match Interface
**Priority:** High
**Type:** UI

**Steps:**
1. Ensure at least one unmatched webhook entry exists (from TC-07-08 or by inserting a test log entry)
2. Navigate to the e-Transfer Webhooks page
3. Locate an unmatched webhook entry
4. Click "Match" or "Manual Match" on the entry
5. Select a WooCommerce order to match it to
6. Confirm the match

**Expected Result:**
- The manual match interface opens (modal, inline form, or separate page)
- An order search/selection mechanism is available
- After matching, the webhook entry status updates to "matched"

**Verification:**
- Confirm the webhook entry now shows as matched with the order ID
- Verify via WP-CLI: `wp db query "SELECT * FROM $(wp db prefix)spet_etransfer_logs WHERE status='matched' ORDER BY id DESC LIMIT 1"`

### TC-07-12: Activity Log Displays Webhook History
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to the e-Transfer Webhooks page
2. Review the activity log or webhook history section

**Expected Result:**
- The page displays a chronological log of webhook events
- Each entry shows timestamp, status, sender info, and amount (if available)

**Verification:**
- Confirm log entries are visible and ordered by date
- Confirm entries from previous test cases appear in the log

### TC-07-13: Hide Log Entry Functionality
**Priority:** Medium
**Type:** UI

**Steps:**
1. Navigate to the e-Transfer Webhooks page
2. Locate a log entry
3. Click "Hide" or "Dismiss" on the entry
4. Confirm the action

**Expected Result:**
- The log entry is hidden from the default view
- The entry is not permanently deleted (may be viewable with a "show hidden" filter)

**Verification:**
- Confirm the hidden entry no longer appears in the default list
- Verify via WP-CLI: `wp db query "SELECT * FROM $(wp db prefix)spet_etransfer_logs WHERE hidden=1 ORDER BY id DESC LIMIT 1"` shows the hidden entry

### TC-07-14: Cron Job spet_cleanup_old_logs Scheduled
**Priority:** Medium
**Type:** Hybrid

**Steps:**
1. Run WP-CLI: `wp cron event list --fields=hook,next_run_relative,recurrence`
2. Search for `spet_cleanup_old_logs` in the output

**Expected Result:**
- The cron event `spet_cleanup_old_logs` is listed in the scheduled events
- It has a recurrence schedule (e.g., daily or weekly)

**Verification:**
- Confirm the hook name appears in the cron event list
- Confirm the recurrence is not "Non-repeating" (it should be a recurring schedule)

### TC-07-15: Database Table spet_etransfer_logs Exists
**Priority:** Critical
**Type:** Hybrid

**Steps:**
1. Run WP-CLI: `wp db query "SHOW TABLES LIKE '%spet_etransfer_logs%'"`
2. Verify the table exists in the output

**Expected Result:**
- The query returns a row containing the `spet_etransfer_logs` table name (with the WordPress table prefix)

**Verification:**
- The output is not empty and contains `spet_etransfer_logs`
- Optionally describe the table: `wp db query "DESCRIBE $(wp db prefix)spet_etransfer_logs"`
