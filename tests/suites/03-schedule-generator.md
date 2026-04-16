# Test Suite: Schedule Generator

## Prerequisites
- Smoke tests (00-smoke.md) have passed.
- Admin Tools Core tests (01-admin-tools-core.md) have passed.
- Events Manager tests (02-events-manager.md) have passed.
- SportsPress Admin Tools and Schedule Generator child plugin are active.
- SportsPress has leagues, seasons, and teams configured.
- Database is at baseline state. Restore if needed: `docker exec sportspress-test wp db import /tmp/baseline.sql --allow-root`
- Verify teams exist: `docker exec sportspress-test wp post list --post_type=sp_team --format=table --allow-root`
- Verify leagues exist: `docker exec sportspress-test wp post list --post_type=sp_league --format=table --allow-root`
- Verify venues exist: `docker exec sportspress-test wp post list --post_type=sp_venue --format=table --allow-root`

## Test Cases

### TC-03-01: Schedule Generator Page Loads
**Priority:** Critical
**Type:** UI

**Steps:**
1. Use `browser_navigate` to go to `http://sportspress-test/wp-admin/`.
2. Use `browser_snapshot` to locate the "Schedule Generator" top-level menu item in the admin sidebar.
3. Click the "Schedule Generator" menu item using `browser_click`.
4. Use `browser_snapshot` to capture the page structure.

**Expected Result:**
- The Schedule Generator page loads from the top-level admin menu.
- The page contains the main interface with tabs or sections for configuration, generation, and preview.

**Verification:**
- `browser_snapshot` shows the Schedule Generator interface.
- `browser_screenshot` for visual confirmation.

### TC-03-02: Import League Structure
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to the Schedule Generator page.
2. Use `browser_snapshot` to locate the "Import League" button or dialog trigger.
3. Click the "Import League" button using `browser_click`.
4. Use `browser_snapshot` to capture the import dialog.
5. Verify the dialog shows available leagues from SportsPress.
6. Select a league to import using `browser_click`.
7. Click the "Import" or "Confirm" button using `browser_click`.
8. Wait for the import to complete.
9. Use `browser_snapshot` to verify the league structure was imported (divisions, teams populated).

**Expected Result:**
- The import dialog opens and shows available SportsPress leagues.
- After import, the configuration area shows the imported league structure with divisions and teams.

**Verification:**
- `browser_snapshot` shows imported league data in the configuration.
- `browser_screenshot` of the imported structure.

### TC-03-03: Create New Configuration
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to the Schedule Generator page.
2. Use `browser_snapshot` to locate the configuration management area.
3. Click "New Configuration" or similar button using `browser_click`.
4. Use `browser_type` to enter a configuration name (e.g., `Test Config 2026`).
5. Use `browser_snapshot` to confirm the new configuration form is active.

**Expected Result:**
- A new empty configuration is created with the given name.
- The configuration form is ready for editing.

**Verification:**
- `browser_snapshot` shows the new configuration name and empty form fields.

### TC-03-04: Add Divisions and Teams to Configuration
**Priority:** Critical
**Type:** UI

**Steps:**
1. Continue from TC-03-03 or create a new configuration.
2. Use `browser_snapshot` to locate the "Add Division" button.
3. Click "Add Division" using `browser_click`.
4. Use `browser_type` to name the division (e.g., `Division A`).
5. Use `browser_snapshot` to locate the "Add Team" button within the division.
6. Click "Add Team" using `browser_click`.
7. Select or type a team name. Repeat to add at least 4 teams.
8. Use `browser_snapshot` to confirm divisions and teams are listed.

**Expected Result:**
- Divisions can be added to the configuration.
- Teams can be added within each division.
- The UI shows the hierarchical structure (division > teams).

**Verification:**
- `browser_snapshot` shows the division with teams listed.
- `browser_screenshot` for visual confirmation.

### TC-03-05: Set Date Range and Time Slots
**Priority:** Critical
**Type:** UI

**Steps:**
1. Continue from TC-03-04 or load an existing configuration.
2. Use `browser_snapshot` to locate date range fields (start date, end date).
3. Clear the start date field and use `browser_type` to enter `2026-09-01`.
4. Clear the end date field and use `browser_type` to enter `2027-03-31`.
5. Use `browser_snapshot` to locate time slot settings.
6. Add a time slot (e.g., `19:00`) using the available UI controls.
7. Use `browser_snapshot` to confirm date range and time slots are set.

**Expected Result:**
- Date range fields accept and display the entered dates.
- Time slots can be added and are displayed in the configuration.

**Verification:**
- `browser_snapshot` shows the configured date range and time slots.

### TC-03-06: Save Configuration
**Priority:** Critical
**Type:** UI

**Steps:**
1. Continue from TC-03-05 with a configured schedule.
2. Use `browser_snapshot` to locate the "Save" button.
3. Click "Save" using `browser_click`.
4. Wait for the save operation to complete.
5. Use `browser_snapshot` to check for a success message.

**Expected Result:**
- The configuration is saved successfully.
- A success message or indicator appears.

**Verification:**
- `browser_snapshot` shows save confirmation.
- Reload the page and verify the configuration persists.

### TC-03-07: Load Configuration
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to the Schedule Generator page.
2. Use `browser_snapshot` to locate the configuration selector or load button.
3. Select the previously saved configuration (e.g., `Test Config 2026`) using `browser_click`.
4. Use `browser_snapshot` to confirm the configuration loaded with all previously saved data (divisions, teams, dates, time slots).

**Expected Result:**
- The saved configuration loads with all its data intact.
- Divisions, teams, date range, and time slots match what was saved.

**Verification:**
- `browser_snapshot` shows the loaded configuration data matching TC-03-03 through TC-03-05.

### TC-03-08: Clone Configuration
**Priority:** Medium
**Type:** UI

**Steps:**
1. Load an existing configuration.
2. Use `browser_snapshot` to locate the "Clone" button.
3. Click "Clone" using `browser_click`.
4. Use `browser_snapshot` to confirm a new configuration was created with copied data.
5. Verify the cloned configuration has a different name (e.g., `Test Config 2026 (Copy)`).

**Expected Result:**
- A new configuration is created as a copy of the original.
- All data (divisions, teams, dates, time slots) is duplicated.

**Verification:**
- `browser_snapshot` shows the cloned configuration with copied data and a new name.

### TC-03-09: Delete Configuration
**Priority:** High
**Type:** UI

**Steps:**
1. Load the cloned configuration from TC-03-08.
2. Use `browser_snapshot` to locate the "Delete" button.
3. Click "Delete" using `browser_click`.
4. Use `browser_snapshot` to check for a confirmation dialog.
5. Confirm the deletion.
6. Use `browser_snapshot` to verify the configuration is removed from the list.

**Expected Result:**
- A confirmation dialog appears before deletion.
- After confirmation, the configuration is removed.

**Verification:**
- `browser_snapshot` shows the configuration is no longer in the list.

### TC-03-10: Import Venues
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to the Schedule Generator page and load a configuration.
2. Use `browser_snapshot` to locate the Venue Management section.
3. Click "Import Venues" or similar button using `browser_click`.
4. Use `browser_snapshot` to capture the import dialog.
5. Verify existing SportsPress venues are listed.
6. Select venues to import and confirm.
7. Use `browser_snapshot` to verify venues appear in the configuration.

**Expected Result:**
- The import dialog shows available SportsPress venues.
- Selected venues are added to the configuration.

**Verification:**
- `browser_snapshot` shows imported venues in the venue management area.

### TC-03-11: Upload Venue CSV
**Priority:** Medium
**Type:** UI

**Steps:**
1. Navigate to the Venue Management section.
2. Use `browser_snapshot` to locate the CSV upload area.
3. Create a test CSV file via WP-CLI:
   ```
   docker exec sportspress-test bash -c 'echo "name,address,capacity\nTest Arena,123 Main St,5000\nTest Stadium,456 Oak Ave,10000" > /tmp/venues.csv'
   ```
4. Use the file upload control to upload the CSV (use `browser_evaluate` to set the file input if needed).
5. Use `browser_snapshot` to verify the uploaded venues appear.

**Expected Result:**
- The CSV file is accepted and parsed.
- Venues from the CSV appear in the venue list.

**Verification:**
- `browser_snapshot` shows the uploaded venues (Test Arena, Test Stadium).

### TC-03-12: Add Blackout Dates
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to the Schedule Generator page and load a configuration.
2. Use `browser_snapshot` to locate the Constraint System section or tab.
3. Click to open the blackout dates area.
4. Click "Add Blackout Date" using `browser_click`.
5. Use `browser_type` to enter a date (e.g., `2026-12-25`).
6. Optionally add a label (e.g., `Christmas`).
7. Add another blackout date: `2027-01-01` with label `New Year`.
8. Use `browser_snapshot` to confirm both blackout dates are listed.

**Expected Result:**
- Blackout dates can be added with dates and optional labels.
- Added dates appear in the constraint list.

**Verification:**
- `browser_snapshot` shows both blackout dates in the list.

### TC-03-13: Distribution Settings and Team Restrictions
**Priority:** High
**Type:** UI

**Steps:**
1. Continue in the Constraint System section.
2. Use `browser_snapshot` to locate distribution settings (e.g., home/away balance, rest days between games).
3. Adjust distribution settings using available controls.
4. Use `browser_snapshot` to locate team restriction controls.
5. Add a team restriction (e.g., a team cannot play on a specific day).
6. Use `browser_snapshot` to confirm the restriction is listed.

**Expected Result:**
- Distribution settings can be adjusted.
- Team-specific restrictions can be added and are displayed.

**Verification:**
- `browser_snapshot` shows updated distribution settings and team restrictions.

### TC-03-14: Generate Schedule
**Priority:** Critical
**Type:** UI

**Steps:**
1. Ensure a complete configuration is loaded (divisions, teams, dates, time slots from previous tests).
2. Save the configuration if not already saved.
3. Use `browser_snapshot` to locate the "Generate Schedule" button.
4. Click "Generate Schedule" using `browser_click`.
5. Use `browser_snapshot` to monitor progress (look for a progress bar, percentage, or status messages).
6. Wait for generation to complete (poll with `browser_snapshot` every few seconds).
7. Use `browser_snapshot` to confirm generation completed successfully.

**Expected Result:**
- Generation starts and shows progress feedback.
- Generation completes with a success message.
- The generated schedule is available for preview.

**Verification:**
- `browser_snapshot` shows completion message.
- `browser_screenshot` of the completed generation status.

### TC-03-15: Cancel Generation
**Priority:** Medium
**Type:** UI

**Steps:**
1. Start a new schedule generation (click "Generate Schedule").
2. Immediately use `browser_snapshot` to locate the "Cancel" button.
3. Click "Cancel" using `browser_click`.
4. Use `browser_snapshot` to confirm generation was cancelled.

**Expected Result:**
- The cancel button is available during generation.
- Clicking cancel stops the generation process.
- A cancellation message appears.

**Verification:**
- `browser_snapshot` shows cancellation confirmation.

### TC-03-16: Preview Generated Schedule
**Priority:** Critical
**Type:** UI

**Steps:**
1. After a successful generation (TC-03-14), navigate to the preview section.
2. Use `browser_snapshot` to capture the schedule preview.
3. Verify the preview shows:
   - Game dates and times.
   - Home and away teams.
   - Venues (if assigned).
4. Test sorting: click a column header to sort using `browser_click`.
5. Use `browser_snapshot` to confirm sorting changed the order.
6. Test filtering: use any available filter controls (by date, team, division).
7. Use `browser_snapshot` to confirm filtering reduced the displayed results.

**Expected Result:**
- The preview displays the generated schedule in a table format.
- Sorting by columns works.
- Filtering narrows the displayed games.

**Verification:**
- `browser_snapshot` shows schedule data with games, teams, dates.
- `browser_screenshot` of the preview table.

### TC-03-17: CSV Export
**Priority:** High
**Type:** UI

**Steps:**
1. After generation, navigate to the preview or export section.
2. Use `browser_snapshot` to locate the "Export CSV" button.
3. Click "Export CSV" using `browser_click`.
4. Use `browser_evaluate` to check if a download was triggered or a blob URL was created.
5. Alternatively, check for the downloaded file: `docker exec sportspress-test ls -la /tmp/*.csv --allow-root` (if server-side export).

**Expected Result:**
- Clicking export triggers a CSV file download.
- The CSV contains the schedule data.

**Verification:**
- A file download is initiated (check via browser evaluation or server-side file).

### TC-03-18: Import to SportsPress Preview
**Priority:** Critical
**Type:** UI

**Steps:**
1. After generation, use `browser_snapshot` to locate the "Import to SportsPress" button.
2. Click the button using `browser_click`.
3. Use `browser_snapshot` to capture the preview dialog.
4. Verify the dialog shows:
   - Number of events to be created.
   - Summary of teams, dates, and venues.
   - A confirm/cancel option.

**Expected Result:**
- A preview dialog opens showing what will be imported.
- The dialog accurately summarizes the generated schedule.

**Verification:**
- `browser_snapshot` shows the import preview dialog with event count and summary.
- `browser_screenshot` of the preview dialog.

### TC-03-19: Import to SportsPress Execute
**Priority:** Critical
**Type:** Hybrid

**Steps:**
1. Continue from TC-03-18 with the import preview dialog open.
2. Count existing events: `docker exec sportspress-test wp post list --post_type=sp_event --format=count --allow-root`
3. Click the "Confirm Import" button using `browser_click`.
4. Wait for the import to complete (monitor progress with `browser_snapshot`).
5. Use `browser_snapshot` to check for a success message.
6. Count events after: `docker exec sportspress-test wp post list --post_type=sp_event --format=count --allow-root`

**Expected Result:**
- The import creates SportsPress events for each game in the schedule.
- A success message shows how many events were created.
- Event count increases by the number of games in the schedule.

**Verification:**
- WP-CLI event count increased.
- `docker exec sportspress-test wp post list --post_type=sp_event --fields=ID,post_title,post_date --format=table --allow-root` shows the new events.
- `browser_snapshot` shows import success message.

### TC-03-20: Placeholder Teams - Create
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to the Schedule Generator page.
2. Use `browser_snapshot` to locate the Placeholder Teams section or button.
3. Click to open the placeholder teams management area.
4. Click "Create Placeholder" or similar button using `browser_click`.
5. Use `browser_type` to enter a placeholder name (e.g., `TBD Team 1`).
6. Create a second placeholder: `TBD Team 2`.
7. Use `browser_snapshot` to confirm both placeholders are listed.

**Expected Result:**
- Placeholder teams can be created with custom names.
- They appear in the team list and can be used in configurations.

**Verification:**
- `browser_snapshot` shows the placeholder teams.
- WP-CLI: `docker exec sportspress-test wp post list --post_type=sp_team --format=table --allow-root` shows placeholder teams.

### TC-03-21: Placeholder Teams - Replace with Real Teams
**Priority:** High
**Type:** UI

**Steps:**
1. Continue from TC-03-20 with placeholder teams created.
2. Use `browser_snapshot` to locate the "Replace" button next to a placeholder team.
3. Click "Replace" using `browser_click`.
4. Use `browser_snapshot` to capture the replacement dialog.
5. Select a real team from the dropdown or list.
6. Confirm the replacement.
7. Use `browser_snapshot` to verify the placeholder was replaced.

**Expected Result:**
- The replacement dialog shows available real teams.
- After replacement, the placeholder is replaced with the real team in all scheduled events.

**Verification:**
- `browser_snapshot` shows the real team name where the placeholder was.
- WP-CLI: verify events reference the real team ID.

### TC-03-22: Change Tracking - View History
**Priority:** Medium
**Type:** UI

**Steps:**
1. Navigate to the Schedule Generator page.
2. Use `browser_snapshot` to locate the Change Tracking section or history button.
3. Click to open the change history.
4. Use `browser_snapshot` to capture the history list.

**Expected Result:**
- The change history shows a log of actions performed (configurations saved, schedules generated, imports executed).
- Each entry has a timestamp and description.

**Verification:**
- `browser_snapshot` shows history entries with timestamps.

### TC-03-23: Change Tracking - Clear History
**Priority:** Medium
**Type:** UI

**Steps:**
1. Continue from TC-03-22 with the change history open.
2. Use `browser_snapshot` to locate the "Clear History" button.
3. Click "Clear History" using `browser_click`.
4. Use `browser_snapshot` to check for a confirmation dialog.
5. Confirm the clear action.
6. Use `browser_snapshot` to verify the history is empty.

**Expected Result:**
- A confirmation dialog appears before clearing.
- After confirmation, the history list is empty.

**Verification:**
- `browser_snapshot` shows an empty history or "No history" message.

### TC-03-24: Unsaved Changes Warning
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to the Schedule Generator page and load a configuration.
2. Make a change to the configuration (e.g., add a team, change a date).
3. Do NOT save.
4. Use `browser_evaluate` to check for a `beforeunload` handler: `typeof window.onbeforeunload === 'function'` or check for dirty state flags.
5. Attempt to navigate away by clicking a sidebar menu link using `browser_click`.
6. Use `browser_snapshot` to check for a warning dialog.

**Expected Result:**
- Modifying the configuration without saving sets a dirty flag.
- Navigating away triggers a warning prompt.

**Verification:**
- `browser_evaluate` confirms `beforeunload` handler is active.
- `browser_snapshot` or `browser_screenshot` shows the warning if a custom dialog is used.

### TC-03-25: Settings Tab - Max Generation Time
**Priority:** Medium
**Type:** UI

**Steps:**
1. Navigate to the Schedule Generator page.
2. Use `browser_snapshot` to locate the "Settings" tab.
3. Click the "Settings" tab using `browser_click`.
4. Use `browser_snapshot` to identify the max generation time field.
5. Clear the field and use `browser_type` to enter `120` (seconds).
6. Click "Save" using `browser_click`.
7. Reload the page and navigate back to the Settings tab.
8. Use `browser_snapshot` to confirm the value persisted.

**Expected Result:**
- The max generation time field accepts numeric input.
- The value persists after save and reload.

**Verification:**
- `browser_snapshot` shows `120` in the max generation time field after reload.

### TC-03-26: Settings Tab - Debug Logging and Timezone
**Priority:** Medium
**Type:** UI

**Steps:**
1. Navigate to the Schedule Generator Settings tab.
2. Use `browser_snapshot` to identify the debug logging toggle and timezone selector.
3. Toggle debug logging on using `browser_click`.
4. Select a timezone (e.g., `America/New_York`) from the timezone dropdown.
5. Click "Save" using `browser_click`.
6. Reload the page and navigate back to the Settings tab.
7. Use `browser_snapshot` to confirm both settings persisted.

**Expected Result:**
- Debug logging toggle state is saved.
- Timezone selection is saved.
- Both persist after reload.

**Verification:**
- `browser_snapshot` shows debug logging enabled and correct timezone selected.
- WP-CLI: `docker exec sportspress-test wp option get spat_schedule_generator_settings --format=json --allow-root`

### TC-03-27: Settings Tab - Change Tracking Toggle
**Priority:** Medium
**Type:** UI

**Steps:**
1. Navigate to the Schedule Generator Settings tab.
2. Use `browser_snapshot` to locate the change tracking toggle.
3. Note the current state.
4. Toggle it to the opposite state using `browser_click`.
5. Click "Save" using `browser_click`.
6. Reload the page and navigate back to the Settings tab.
7. Use `browser_snapshot` to confirm the toggle state changed.
8. Toggle it back to the original state and save to restore defaults.

**Expected Result:**
- The change tracking toggle can be enabled/disabled.
- The state persists after save and reload.

**Verification:**
- `browser_snapshot` confirms the toggled state after reload.
