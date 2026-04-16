# Test Suite: Events Manager

## Prerequisites
- Smoke tests (00-smoke.md) have passed.
- Admin Tools Core tests (01-admin-tools-core.md) have passed.
- SportsPress Admin Tools and Events Manager child plugin are active.
- SportsPress has at least one league and one season configured.
- Database is at baseline state. Restore if needed: `docker exec sportspress-test wp db import /tmp/baseline.sql --allow-root`
- Verify prerequisite data: `docker exec sportspress-test wp post list --post_type=sp_league --format=table --allow-root`
- Verify seasons exist: `docker exec sportspress-test wp post list --post_type=sp_season --format=table --allow-root`

## Test Cases

### TC-02-01: Events Manager Tab Appears on Settings Page
**Priority:** Critical
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Use `browser_snapshot` to capture the page structure.
3. Look for an "Events Manager" tab in the tab navigation.

**Expected Result:**
- An "Events Manager" tab is visible alongside General, Notifications, and System Status tabs.

**Verification:**
- `browser_snapshot` shows a tab element with text "Events Manager".

### TC-02-02: Calendar Management Settings Save
**Priority:** Critical
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Click the "Events Manager" tab using `browser_click`.
3. Use `browser_snapshot` to identify calendar management settings (auto-create toggle, naming convention field).
4. Toggle the auto-create calendars setting using `browser_click`.
5. If there is a naming convention field, clear it and type a new pattern using `browser_type` (e.g., `{league} - {season} Calendar`).
6. Click "Save Changes" using `browser_click`.
7. Wait for the page to reload.
8. Click the "Events Manager" tab again.
9. Use `browser_snapshot` to confirm the settings persisted.

**Expected Result:**
- Auto-create toggle state is saved.
- Naming convention value persists after reload.

**Verification:**
- `browser_snapshot` confirms saved values on the Events Manager tab.
- WP-CLI: `docker exec sportspress-test wp option get spat_settings --format=json --allow-root`

### TC-02-03: Calendar Naming Preview Updates
**Priority:** Medium
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Click the "Events Manager" tab using `browser_click`.
3. Use `browser_snapshot` to locate the naming convention field and any preview element.
4. Clear the naming convention field and type a new pattern using `browser_type` (e.g., `{league} {season} Games`).
5. Use `browser_snapshot` to check if a preview element updated to show the resolved name.

**Expected Result:**
- A preview area shows what the calendar name will look like with actual league/season names substituted.
- The preview updates dynamically as the naming pattern changes.

**Verification:**
- `browser_snapshot` shows a preview element with resolved placeholder values.

### TC-02-04: Create Missing Calendars Button
**Priority:** Critical
**Type:** Hybrid

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Click the "Events Manager" tab using `browser_click`.
3. Use `browser_snapshot` to locate the "Create Missing Calendars" button.
4. Count existing calendars before: `docker exec sportspress-test wp post list --post_type=sp_calendar --format=count --allow-root`
5. Click the "Create Missing Calendars" button using `browser_click`.
6. Wait for the AJAX operation to complete (watch for a spinner to disappear or success message).
7. Use `browser_snapshot` to check for a success message.
8. Count calendars after: `docker exec sportspress-test wp post list --post_type=sp_calendar --format=count --allow-root`

**Expected Result:**
- The button triggers calendar creation for any league/season combinations missing calendars.
- A success message appears indicating how many calendars were created.

**Verification:**
- WP-CLI calendar count increased (or stayed the same if none were missing).
- `browser_snapshot` shows success feedback.
- List calendars: `docker exec sportspress-test wp post list --post_type=sp_calendar --format=table --allow-root`

### TC-02-05: Reset Calendars Button
**Priority:** High
**Type:** Hybrid

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Click the "Events Manager" tab using `browser_click`.
3. Use `browser_snapshot` to locate the "Reset Calendars" button.
4. Count existing calendars: `docker exec sportspress-test wp post list --post_type=sp_calendar --format=count --allow-root`
5. Click the "Reset Calendars" button using `browser_click`.
6. Use `browser_snapshot` to check if a confirmation dialog appears.
7. If a confirmation dialog appears, confirm it by clicking the appropriate button.
8. Wait for the operation to complete.
9. Use `browser_snapshot` to check for a success message.
10. Count calendars after: `docker exec sportspress-test wp post list --post_type=sp_calendar --format=count --allow-root`

**Expected Result:**
- A confirmation dialog appears before resetting (destructive action).
- After confirmation, calendars are deleted and recreated.
- A success message appears.

**Verification:**
- WP-CLI shows calendars were reset.
- `browser_snapshot` shows success feedback.

### TC-02-06: League Table Generator Modal
**Priority:** Critical
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Click the "Events Manager" tab using `browser_click`.
3. Use `browser_snapshot` to locate the League Table Generator section or button.
4. Click the button to open the League Table Generator modal using `browser_click`.
5. Use `browser_snapshot` to capture the modal content.
6. Verify the modal contains:
   - A league dropdown that is populated with existing leagues.
   - A season dropdown that is populated with existing seasons.
7. Select a league from the dropdown using `browser_click`.
8. Select a season from the dropdown using `browser_click`.
9. Click the "Create Table" or "Generate" button using `browser_click`.
10. Wait for the operation to complete.
11. Use `browser_snapshot` to check for a success message.

**Expected Result:**
- The modal opens with populated league and season dropdowns.
- Selecting a league and season and clicking create generates a league table.
- A success message confirms table creation.

**Verification:**
- `browser_snapshot` shows the modal with populated dropdowns.
- After creation: `docker exec sportspress-test wp post list --post_type=sp_table --format=table --allow-root`
- `browser_screenshot` of the modal for visual confirmation.

### TC-02-07: Season Rollover Preview
**Priority:** Critical
**Type:** Hybrid

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/options-general.php?page=sportspress-admin-tools`.
2. Click the "Events Manager" tab using `browser_click`.
3. Use `browser_snapshot` to locate the Season Rollover section.
4. Click the "Preview" or "Season Rollover" button using `browser_click`.
5. Use `browser_snapshot` to capture the preview content.
6. Verify the preview shows:
   - Current season information.
   - What changes will be made (new season name, affected leagues).

**Expected Result:**
- The preview displays a summary of changes that will occur during rollover.
- Current and new season details are shown.

**Verification:**
- `browser_snapshot` shows preview content with season details.
- `browser_screenshot` for visual confirmation.

### TC-02-08: Season Rollover Execute
**Priority:** Critical
**Type:** Hybrid

**Steps:**
1. Continue from TC-02-07 or navigate to the Season Rollover section.
2. Use `browser_snapshot` to locate the "Execute" or "Rollover" button.
3. Count seasons before: `docker exec sportspress-test wp post list --post_type=sp_season --format=table --allow-root`
4. Click the execute button using `browser_click`.
5. If a confirmation dialog appears, confirm it.
6. Wait for the operation to complete.
7. Use `browser_snapshot` to check for a success message.
8. Count seasons after: `docker exec sportspress-test wp post list --post_type=sp_season --format=table --allow-root`

**Expected Result:**
- A new season is created.
- Success message confirms the rollover.

**Verification:**
- WP-CLI shows a new season post was created.
- `docker exec sportspress-test wp post list --post_type=sp_season --format=table --allow-root` shows the new season.

### TC-02-09: Verify Created Data via REST API and WP-CLI
**Priority:** High
**Type:** API

**Steps:**
1. Verify calendars exist: `docker exec sportspress-test wp post list --post_type=sp_calendar --fields=ID,post_title,post_status --format=table --allow-root`
2. Verify league tables exist: `docker exec sportspress-test wp post list --post_type=sp_table --fields=ID,post_title,post_status --format=table --allow-root`
3. Verify seasons exist: `docker exec sportspress-test wp post list --post_type=sp_season --fields=ID,post_title,post_status --format=table --allow-root`
4. Use `browser_navigate` to go to `http://sportspress-test/wp-json/wp/v2/sp_calendar` to check REST API access.
5. Use `browser_snapshot` to confirm JSON data is returned.

**Expected Result:**
- WP-CLI lists the created calendars, tables, and seasons.
- REST API returns JSON data for calendars.

**Verification:**
- WP-CLI output shows posts with "publish" status.
- REST API returns valid JSON arrays.
