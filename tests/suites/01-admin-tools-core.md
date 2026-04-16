# Test Suite: Admin Tools Core

## Prerequisites
- Smoke tests (00-smoke.md) have passed.
- SportsPress Admin Tools plugin is active.
- Database is at baseline state. Restore if needed: `docker exec sportspress-test wp db import /var/lib/baseline/baseline.sql --allow-root`

## Test Cases

### TC-01-01: Settings Page Loads
**Priority:** Critical
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Use `browser_snapshot` to capture the page structure.
3. Confirm the page contains the settings heading and form elements.

**Expected Result:**
- The page loads without errors.
- A settings form is visible with tabs and input fields.

**Verification:**
- `browser_snapshot` shows the settings page with "SportsPress Admin Tools" heading.
- `browser_screenshot` for visual confirmation.

### TC-01-02: Tab Navigation Works
**Priority:** Critical
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Use `browser_snapshot` to identify the tab elements.
3. Click the "General" tab using `browser_click`. Use `browser_snapshot` to confirm it is active.
4. Click the "Notifications" tab using `browser_click`. Use `browser_snapshot` to confirm it is active and shows notification-related fields.
5. Click the "System Status" tab using `browser_click`. Use `browser_snapshot` to confirm it is active and shows system status content.

**Expected Result:**
- Each tab click switches the visible content area.
- The active tab is visually highlighted.
- Each tab shows its own set of fields/content.

**Verification:**
- `browser_snapshot` after each tab click shows the correct content for that tab.
- `browser_screenshot` of each tab for visual confirmation.

### TC-01-03: Module Enable/Disable Toggles Save
**Priority:** Critical
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Use `browser_snapshot` to find module toggle checkboxes on the General tab.
3. Note the current state of a module toggle (checked or unchecked).
4. Click the toggle to change its state using `browser_click`.
5. Click the "Save Changes" button using `browser_click`.
6. Wait for the page to reload.
7. Use `browser_snapshot` to confirm the toggle is in the new state.
8. Toggle it back and save again to restore original state.

**Expected Result:**
- The toggle state changes when clicked.
- After saving and page reload, the new state persists.

**Verification:**
- `browser_snapshot` after reload shows the updated toggle state.
- Optionally verify via WP-CLI: `docker exec sportspress-test wp option get spat_settings --format=json --allow-root`

### TC-01-04: Notification Settings Save
**Priority:** High
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Click the "Notifications" tab using `browser_click`.
3. Use `browser_snapshot` to identify notification fields (email address, toggle switches).
4. Clear the email field and type a test email using `browser_type`: `test@example.com`.
5. Toggle any notification enable/disable checkboxes using `browser_click`.
6. Click "Save Changes" using `browser_click`.
7. Wait for the page to reload.
8. Click the "Notifications" tab again.
9. Use `browser_snapshot` to confirm the email and toggle values persisted.

**Expected Result:**
- The email field shows `test@example.com` after reload.
- Toggle states match what was set before saving.

**Verification:**
- `browser_snapshot` confirms saved values on the Notifications tab.
- WP-CLI: `docker exec sportspress-test wp option get spat_settings --format=json --allow-root` shows notification settings.

### TC-01-05: System Status Tab Shows Health Dashboard
**Priority:** High
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Click the "System Status" tab using `browser_click`.
3. Use `browser_snapshot` to capture the system status content.
4. Verify the following sections are present:
   - SportsPress status (version, active state)
   - Plugin status (list of SPAT child plugins and their states)
   - Cron health (scheduled tasks status)
   - Database health (table status, size)

**Expected Result:**
- The System Status tab displays a health dashboard.
- All four sections (SportsPress status, plugin status, cron health, database health) are visible.
- Status indicators (icons, colors, or text) show current health.

**Verification:**
- `browser_snapshot` contains text related to each health section.
- `browser_screenshot` for visual confirmation of the health dashboard layout.

### TC-01-06: Copy Debug Info Button Works
**Priority:** Medium
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Click the "System Status" tab using `browser_click`.
3. Use `browser_snapshot` to locate the "Copy Debug Info" button.
4. Click the "Copy Debug Info" button using `browser_click`.
5. Use `browser_evaluate` to read the clipboard content: `navigator.clipboard.readText()`. If clipboard API is unavailable, check for a success notification or textarea with debug info.
6. Use `browser_snapshot` to check for a success message or toast notification.

**Expected Result:**
- Clicking the button copies debug information to the clipboard or displays it in a textarea.
- A success notification appears (e.g., "Copied!" or similar feedback).

**Verification:**
- `browser_snapshot` shows a success message after clicking.
- If clipboard is accessible, the copied text contains system information.

### TC-01-07: Settings Persist After Page Reload
**Priority:** Critical
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Use `browser_snapshot` to note current settings values on the General tab.
3. Change at least one setting value (e.g., toggle a checkbox or change a text field).
4. Click "Save Changes" using `browser_click`.
5. Wait for the page to reload.
6. Use `browser_snapshot` to confirm the changed value persisted.
7. Use `browser_navigate` to go to a different page: `http://sportspress-test/wp-admin/`.
8. Use `browser_navigate` to return to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
9. Use `browser_snapshot` to confirm the setting still has the changed value.

**Expected Result:**
- Settings persist across page reloads and navigation away/back.

**Verification:**
- `browser_snapshot` on return visit shows the saved value.
- WP-CLI: `docker exec sportspress-test wp option get spat_settings --format=json --allow-root`

### TC-01-08: Unsaved Changes Warning
**Priority:** High
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Use `browser_snapshot` to identify a form field.
3. Change a setting value (e.g., toggle a checkbox or type in a text field) but do NOT save.
4. Use `browser_evaluate` to check if a `beforeunload` event handler is registered: `window.onbeforeunload !== null` or check for a dirty form flag.
5. Attempt to navigate away using `browser_click` on a sidebar menu link.
6. Use `browser_snapshot` to check if a browser confirmation dialog or custom warning appeared.

**Expected Result:**
- Modifying a setting without saving marks the form as dirty.
- Attempting to navigate away triggers a warning (browser `beforeunload` dialog or custom modal).

**Verification:**
- `browser_evaluate` confirms a `beforeunload` handler is set after form modification.
- `browser_snapshot` or `browser_screenshot` shows the warning dialog if a custom one is used.
