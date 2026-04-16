# Test Suite: Smoke Tests

## Prerequisites
- Docker container `sportspress-test` is running
- WordPress is installed and accessible at http://sportspress-test
- Auto-login is enabled (no credentials needed)
- SportsPress and all SPAT plugins are installed

## Test Cases

### TC-00-01: REST API Health Endpoint
**Priority:** Critical
**Type:** API

**Steps:**
1. Run: `docker exec sportspress-test wp eval "echo rest_url('test/v1/health');" --allow-root` to confirm the endpoint is registered.
2. Use `browser_navigate` to go to `http://sportspress-test/wp-json/test/v1/health`.
3. Use `browser_snapshot` to read the page content.

**Expected Result:**
- The endpoint returns a JSON response with a success/healthy status.
- HTTP status code is 200.

**Verification:**
- `browser_snapshot` shows JSON with a health status field indicating success.

### TC-00-02: WordPress Admin Dashboard Loads
**Priority:** Critical
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/`.
2. Use `browser_snapshot` to capture the page structure.
3. Confirm the page contains the WordPress dashboard heading (e.g., "Dashboard" or "Welcome to WordPress").

**Expected Result:**
- The admin dashboard loads without a login redirect.
- The page title or heading contains "Dashboard".

**Verification:**
- `browser_snapshot` shows dashboard elements (admin menu, welcome panel, or "Dashboard" heading).
- `browser_screenshot` for visual confirmation.

### TC-00-03: SportsPress Menu Visible in Admin Sidebar
**Priority:** Critical
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/`.
2. Use `browser_snapshot` to capture the page structure.
3. Look for a sidebar menu item containing "SportsPress".

**Expected Result:**
- The admin sidebar contains a "SportsPress" top-level menu item.

**Verification:**
- `browser_snapshot` includes a menu element with text "SportsPress".

### TC-00-04: SportsPress Admin Tools Settings Page Loads
**Priority:** Critical
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Use `browser_snapshot` to capture the page structure.
3. Confirm the page contains the SportsPress Admin Tools settings heading.

**Expected Result:**
- The settings page loads without errors.
- The page contains "SportsPress Admin Tools" heading or settings form.

**Verification:**
- `browser_snapshot` shows settings page content with tabs or form fields.
- No PHP errors or white screen.

### TC-00-05: All Child Plugins Are Active
**Priority:** Critical
**Type:** API

**Steps:**
1. Run: `docker exec sportspress-test wp plugin list --status=active --format=table --allow-root`
2. Check the output for these plugins:
   - `sportspress` (core dependency)
   - `sportspress-admin-tools` (parent plugin)
   - `spat-events-manager` (child plugin)
   - `spat-schedule-generator` (child plugin)

**Expected Result:**
- All listed plugins appear with status "active".

**Verification:**
- WP-CLI output shows each plugin as active.
- Alternatively run: `docker exec sportspress-test wp plugin is-active sportspress --allow-root` (exit code 0 = active) for each plugin.

### TC-00-06: Database Baseline Exists
**Priority:** Critical
**Type:** API

**Steps:**
1. Run: `docker exec sportspress-test ls -la /tmp/baseline.sql`
2. Confirm the file exists and has a non-zero size.

**Expected Result:**
- `/tmp/baseline.sql` exists inside the container.
- File size is greater than 0 bytes.

**Verification:**
- The `ls -la` command returns file details without "No such file or directory" error.

### TC-00-07: Dashboard Screenshot for Visual Verification
**Priority:** Medium
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/`.
2. Wait for the page to fully load.
3. Use `browser_screenshot` to capture the full dashboard.

**Expected Result:**
- Screenshot shows a fully rendered WordPress admin dashboard.
- No broken layout, missing styles, or PHP error notices.

**Verification:**
- Review the screenshot visually for correct layout and branding.
