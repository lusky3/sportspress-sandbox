# Test Suite: League Manager

## Prerequisites
- WordPress running at http://sportspress-test with auto-login enabled
- SportsPress core plugin activated
- SPAT League Manager child plugin activated
- WP-CLI available via `docker exec` or direct shell
- At least one league, season, and team exist (create via WP-CLI if needed):
  - `wp term create sp_league "Test League"`
  - `wp term create sp_season "2026"`
  - `wp post create --post_type=sp_team --post_title="Test Team LM" --post_status=publish`

## Test Cases

### TC-05-01: League Manager Menu Page Loads
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to http://sportspress-test/wp-admin/admin.php?page=league-manager
2. If the exact URL differs, look for "League Manager" in the admin sidebar as a top-level menu item

**Expected Result:**
- A top-level "League Manager" menu item exists in the WordPress admin sidebar
- The League Manager page loads without PHP errors or warnings

**Verification:**
- Confirm the menu item is visible in the sidebar
- Confirm the page renders with a proper heading

### TC-05-02: Dashboard Shows League Overview
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to the League Manager main page
2. Review the dashboard content

**Expected Result:**
- The dashboard displays a league overview with summary information
- Key metrics (teams count, players count, seasons, etc.) are visible

**Verification:**
- Confirm at least one summary widget or data section is present on the dashboard
- Confirm the data reflects the current state (e.g., shows the test league/team)

### TC-05-03: First-Run Wizard Appears and Can Be Dismissed
**Priority:** High
**Type:** UI

**Steps:**
1. Reset the wizard state via WP-CLI: `wp option delete spat_league_manager_wizard_complete` (or equivalent)
2. Navigate to the League Manager page
3. Observe if a first-run wizard or setup prompt appears
4. Click "Dismiss", "Skip", or "Close" to dismiss the wizard

**Expected Result:**
- A first-run wizard or onboarding prompt appears on initial visit
- The wizard can be dismissed via a button or link

**Verification:**
- After dismissing, reload the page and confirm the wizard does not reappear
- Verify via WP-CLI: `wp option get spat_league_manager_wizard_complete` returns a truthy value

### TC-05-04: Teams & Rosters — Filter by League/Season
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to the Teams & Rosters subpage under League Manager
2. Locate the league filter dropdown and select "Test League"
3. Locate the season filter dropdown and select "2026"
4. Apply the filters

**Expected Result:**
- Filter dropdowns for league and season are present
- Applying filters updates the team list to show only matching teams
- The test team appears in the filtered results

**Verification:**
- Confirm the filtered results contain "Test Team LM"
- Confirm teams from other leagues/seasons are excluded

### TC-05-05: Teams & Rosters — View Roster
**Priority:** High
**Type:** UI

**Steps:**
1. On the Teams & Rosters page, click on "Test Team LM" or its "View Roster" link
2. Review the roster display

**Expected Result:**
- The roster page loads showing players assigned to the team
- Player names and relevant details are displayed

**Verification:**
- Confirm the roster page renders without errors
- Confirm the team name is shown in the heading or breadcrumb

### TC-05-06: Teams & Rosters — CSV Roster Upload Validation
**Priority:** High
**Type:** Hybrid

**Steps:**
1. Navigate to the Teams & Rosters page and locate the CSV upload feature
2. Test with an invalid CSV (wrong columns): `echo "Foo,Bar\n1,2" > /tmp/bad-roster.csv`
3. Upload the invalid CSV
4. Test with an oversized file (if max upload size is configurable): create a file exceeding the limit
5. Test with a non-CSV MIME type: rename a text file to `.pdf` and attempt upload

**Expected Result:**
- Invalid column CSV is rejected with a clear error message about required columns
- Oversized files are rejected with a file size error
- Non-CSV MIME types are rejected with a MIME type error

**Verification:**
- Confirm each invalid upload produces an appropriate error message
- Confirm no data is imported from invalid files

### TC-05-07: Teams & Rosters — Valid CSV Roster Upload
**Priority:** Critical
**Type:** Hybrid

**Steps:**
1. Create a valid roster CSV: `echo "Name,Number,Position\nJohn Doe,7,Forward\nJane Smith,10,Midfielder" > /tmp/valid-roster.csv`
2. Navigate to the Teams & Rosters page
3. Select "Test Team LM" as the target team
4. Upload the valid CSV
5. Submit the import

**Expected Result:**
- The CSV is accepted and parsed successfully
- Players are imported and associated with the team
- A success message shows the number of players imported

**Verification:**
- Verify via WP-CLI: `wp post list --post_type=sp_player --fields=ID,post_title` includes "John Doe" and "Jane Smith"

### TC-05-08: Fee Status Subpage
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to the Fee Status subpage under League Manager
2. Search for or select a player to check fee status
3. Review the fee status display

**Expected Result:**
- The Fee Status page loads without errors
- A player lookup/search mechanism is available
- Fee status information is displayed for the selected player

**Verification:**
- Confirm the page contains a search or filter control
- Confirm fee status data renders (paid/unpaid/pending or similar)

### TC-05-09: Health Checker — Run Check via AJAX
**Priority:** Medium
**Type:** Hybrid

**Steps:**
1. Navigate to the League Manager page or a subpage with the Health Checker
2. Locate the "Run Health Check" or similar button
3. Click the button and wait for the AJAX request to complete

**Expected Result:**
- An AJAX request is sent when the button is clicked
- A loading indicator appears during the check
- Results are displayed after the check completes

**Verification:**
- Confirm the AJAX response returns a 200 status
- Confirm the results section populates with health check data

### TC-05-10: Health Checker — View Results
**Priority:** Medium
**Type:** UI

**Steps:**
1. After running the health check in TC-05-09, review the results
2. Check for any warnings or issues flagged

**Expected Result:**
- Results are displayed in a readable format (table, list, or cards)
- Each check item shows a pass/fail/warning status

**Verification:**
- Confirm at least one health check item is displayed
- Confirm the results are not empty or error states

### TC-05-11: User Preferences Persist
**Priority:** High
**Type:** UI

**Steps:**
1. Navigate to the League Manager page
2. Select a preferred league from the dropdown (e.g., "Test League")
3. Select a preferred season (e.g., "2026")
4. Save or let the preference auto-save
5. Navigate away to another admin page
6. Return to the League Manager page

**Expected Result:**
- The previously selected league and season are pre-selected on return
- User preferences persist across page navigations

**Verification:**
- Confirm the dropdowns show the previously selected values
- Verify via WP-CLI: `wp user meta get 1 spat_preferred_league` (or equivalent) returns the expected value

### TC-05-12: Settings Tab Configuration
**Priority:** Critical
**Type:** UI

**Steps:**
1. Navigate to the League Manager settings tab (or SPAT settings > League Manager)
2. Set "Default Season" to "2026"
3. Configure "Fee Source" to an available option
4. Enable "Debug Logging"
5. Set "Max Upload Size" to a specific value (e.g., 2MB)
6. Save settings

**Expected Result:**
- All settings fields are present and editable
- Settings save without error
- A success notice appears

**Verification:**
- Reload the page and confirm all values persisted
- Verify via WP-CLI: `wp option get spat_league_manager_settings` (or equivalent) reflects saved values

### TC-05-13: Custom Capability manage_league
**Priority:** High
**Type:** Hybrid

**Steps:**
1. Run WP-CLI: `wp cap list administrator` or `wp role list --fields=role,name`
2. Check if the `manage_league` capability is assigned to the administrator role

**Expected Result:**
- The `manage_league` capability exists and is assigned to the administrator role

**Verification:**
- WP-CLI output confirms `manage_league` is in the administrator's capability list
- Alternatively: `wp eval "var_dump(current_user_can('manage_league'));"` returns `bool(true)`

### TC-05-14: Contextual Help Tabs
**Priority:** Medium
**Type:** UI

**Steps:**
1. Navigate to the League Manager main page
2. Click the "Help" tab in the top-right corner of the WordPress admin screen
3. Review the contextual help content
4. Repeat for each League Manager subpage (Teams & Rosters, Fee Status, Settings)

**Expected Result:**
- A contextual help tab is available on each League Manager page
- The help content is relevant to the current page

**Verification:**
- Confirm the help tab dropdown opens and contains text
- Confirm the help content differs per subpage (is contextual, not generic)
